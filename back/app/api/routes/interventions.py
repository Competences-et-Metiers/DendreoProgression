from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session
from typing import Optional
from datetime import datetime, timezone
import httpx
import logging

from app.models.database import get_db
from app.models.models import Participant, User, Intervention
from app.models.schemas import (
    InterventionCreate,
    InterventionResponse,
    ParticipantTimelineResponse,
    TimelineEntry,
)
from app.auth.dependencies import get_current_user
from app.services.intervention_service import InterventionService
from app.services.hubspot_client import hubspot_client
from app.services.cache_service import cache_service

logger = logging.getLogger(__name__)
router = APIRouter()


def _timeline_cache_key(participant_id: int, adf: Optional[str]) -> str:
    return f"interventions:timeline:{participant_id}:{adf or 'all'}"


@router.post("/", response_model=InterventionResponse)
async def create_intervention(
    data: InterventionCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Create a new intervention (snooze, note, email, call, dismiss).
    For snooze type: also pushes a note to the HubSpot contact."""
    service = InterventionService(db)

    # For snooze: push note to HubSpot
    hubspot_note_id = None
    if data.intervention_type == 'snooze' and data.details:
        participant = db.query(Participant).filter(Participant.id == data.participant_id).first()
        if participant and participant.email:
            try:
                contact = await hubspot_client.get_contact_by_email(participant.email)
                if contact and contact.get('id'):
                    reason = data.details.get('reason', '')
                    days = data.details.get('snooze_days', 0)
                    staff_name = current_user.display_name or current_user.username
                    note_body = (
                        f"[DendreoProgression] Participant reporté pour {days} jours par {staff_name}."
                    )
                    if reason:
                        note_body += f"\nRaison : {reason}"
                    hubspot_note_id = await hubspot_client.create_note_for_contact(
                        contact['id'], note_body
                    )
            except Exception as e:
                logger.warning(f"Failed to push snooze note to HubSpot: {e}")

    try:
        result = service.create_intervention(
            user_id=current_user.id,
            data=data,
            hubspot_note_id=hubspot_note_id,
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    # Invalidate timeline cache
    cache_service.delete(_timeline_cache_key(data.participant_id, data.id_action_formation))

    return result


@router.get("/timeline/{participant_id}", response_model=ParticipantTimelineResponse)
async def get_participant_timeline(
    participant_id: int,
    id_action_formation: Optional[str] = Query(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get unified timeline: local interventions + HubSpot notes + calls.
    Cached in Redis for 5 minutes."""
    cache_key = _timeline_cache_key(participant_id, id_action_formation)
    cached = cache_service.get(cache_key)
    if cached:
        return ParticipantTimelineResponse(**cached)

    service = InterventionService(db)

    # Local interventions
    local_interventions = service.get_interventions(participant_id, id_action_formation)

    # HubSpot engagements
    participant = db.query(Participant).filter(Participant.id == participant_id).first()
    hs_notes = []
    hs_calls = []
    if participant and participant.email:
        try:
            engagements = await hubspot_client.get_contact_engagements(participant.email)
            hs_notes = engagements.get('notes', [])
            hs_calls = engagements.get('calls', [])
        except Exception as e:
            logger.warning(f"Failed to fetch HubSpot engagements for {participant.email}: {e}")

    # Merge into unified timeline
    entries = []

    for intervention in local_interventions:
        entries.append(TimelineEntry(
            source='local',
            timestamp=intervention.created_at,
            intervention_id=intervention.id,
            intervention_type=intervention.intervention_type,
            user_display_name=intervention.user_display_name,
            details=intervention.details,
            is_active=intervention.is_active,
            snooze_until=intervention.snooze_until,
        ))

    for note in hs_notes:
        ts = note.get('hs_timestamp')
        timestamp = None
        if ts:
            try:
                timestamp = datetime.fromisoformat(ts.replace('Z', '+00:00'))
            except (ValueError, AttributeError):
                pass
        entries.append(TimelineEntry(
            source='hubspot_note',
            timestamp=timestamp,
            hubspot_id=note.get('id'),
            body=note.get('hs_note_body', ''),
        ))

    for call in hs_calls:
        ts = call.get('hs_timestamp')
        timestamp = None
        if ts:
            try:
                timestamp = datetime.fromisoformat(ts.replace('Z', '+00:00'))
            except (ValueError, AttributeError):
                pass
        duration = call.get('hs_call_duration')
        entries.append(TimelineEntry(
            source='hubspot_call',
            timestamp=timestamp,
            hubspot_id=call.get('id'),
            body=call.get('hs_call_body', ''),
            call_duration=int(duration) if duration else None,
            call_direction=call.get('hs_call_direction'),
            call_recording_url=call.get('hs_call_recording_url'),
        ))

    # Sort by timestamp descending (newest first)
    entries.sort(
        key=lambda e: e.timestamp or datetime.min.replace(tzinfo=timezone.utc),
        reverse=True,
    )

    # Check snooze/dismiss status
    active_snooze = service.get_active_snooze(participant_id, id_action_formation)
    is_dismissed = service.is_dismissed(participant_id, id_action_formation)

    response = ParticipantTimelineResponse(
        participant_id=participant_id,
        id_action_formation=id_action_formation,
        entries=entries,
        has_active_snooze=active_snooze is not None,
        snooze_until=active_snooze.snooze_until if active_snooze else None,
        is_dismissed=is_dismissed,
    )

    # Cache for 5 minutes
    try:
        cache_service.set(cache_key, response.model_dump(mode='json'), ttl=300)
    except Exception:
        pass  # Non-critical if cache fails

    return response


@router.post("/{intervention_id}/cancel")
async def cancel_intervention(
    intervention_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Cancel a snooze or reverse a dismiss."""
    # Fetch intervention before cancelling (need details for HubSpot note)
    intervention = db.query(Intervention).filter(Intervention.id == intervention_id).first()
    if not intervention:
        raise HTTPException(status_code=404, detail="Intervention not found")

    service = InterventionService(db)
    success = service.cancel_intervention(intervention_id, current_user.id)

    if not success:
        raise HTTPException(status_code=404, detail="Intervention cannot be cancelled")

    # Push cancellation note to HubSpot for snooze type
    if intervention.intervention_type == 'snooze':
        participant = db.query(Participant).filter(
            Participant.id == intervention.participant_id
        ).first()
        if participant and participant.email:
            try:
                contact = await hubspot_client.get_contact_by_email(participant.email)
                if contact and contact.get('id'):
                    staff_name = current_user.display_name or current_user.username
                    note_body = (
                        f"[DendreoProgression] Report annulé par {staff_name}."
                    )
                    await hubspot_client.create_note_for_contact(contact['id'], note_body)
            except Exception as e:
                logger.warning(f"Failed to push snooze cancellation note to HubSpot: {e}")

    # Invalidate timeline cache
    cache_service.delete(_timeline_cache_key(
        intervention.participant_id, intervention.id_action_formation
    ))

    return {"message": "Intervention cancelled", "id": intervention_id}


@router.get("/proxy-recording")
async def proxy_recording(
    url: str = Query(...),
    token: str = Query(...),
    db: Session = Depends(get_db),
):
    """Proxy a Ringover call recording to avoid CORS issues.
    Auth via query param since <audio> elements can't send headers.
    Only allows URLs from cdn.ringover.com."""
    from urllib.parse import urlparse
    from app.auth.utils import decode_token

    # Verify token
    payload = decode_token(token)
    if not payload or not payload.get("sub"):
        raise HTTPException(status_code=401, detail="Invalid token")

    parsed = urlparse(url)
    if parsed.hostname not in ('cdn.ringover.com',):
        raise HTTPException(status_code=400, detail="Only Ringover recording URLs are allowed")

    try:
        async with httpx.AsyncClient(timeout=60, follow_redirects=True) as client:
            response = await client.get(url)
            response.raise_for_status()

            content_type = response.headers.get('content-type', 'audio/mpeg')

            return StreamingResponse(
                iter([response.content]),
                media_type=content_type,
                headers={
                    "Content-Length": str(len(response.content)),
                    "Accept-Ranges": "bytes",
                },
            )
    except httpx.HTTPError as e:
        logger.error(f"Failed to proxy recording: {e}")
        raise HTTPException(status_code=502, detail="Failed to fetch recording")
