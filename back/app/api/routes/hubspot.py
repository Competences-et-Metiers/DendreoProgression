from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
import httpx
import logging
from datetime import datetime, timezone

from app.services.hubspot_client import hubspot_client
from app.services.dendreo_client import DendreoClient, DendreoAPIError
from app.services.api_budget import check_budget
from app.models.database import get_db
from app.models.models import Participant, ParticipantHubspotData, ParticipantCourse, Course, User, ActionHistory
from app.models.schemas import LinkDealRequest, UnlinkDealRequest
from app.auth.dependencies import get_current_user
from app.services.cache_service import cache_service

logger = logging.getLogger(__name__)
router = APIRouter()


@router.get("/contact/{email}")
async def get_hubspot_contact(email: str):
    """Look up a HubSpot contact by email. Returns full contact data including profile URL and deal associations."""
    try:
        result = await hubspot_client.get_contact_by_email(email)
        if result is None:
            raise HTTPException(status_code=503, detail="HubSpot API key not configured")
        return result
    except httpx.HTTPStatusError as e:
        if e.response.status_code == 404:
            raise HTTPException(status_code=404, detail="Contact not found in HubSpot")
        logger.error(f"HubSpot API error for {email}: {e.response.status_code}")
        raise HTTPException(status_code=502, detail=f"HubSpot API error: {e.response.status_code}")
    except httpx.HTTPError as e:
        logger.error(f"HubSpot connection error for {email}: {e}")
        raise HTTPException(status_code=502, detail="Failed to connect to HubSpot API")


@router.get("/deals/{email}")
async def get_hubspot_deals(
    email: str,
    current_user: User = Depends(get_current_user),
):
    """Get all HubSpot deals associated with a contact by email."""
    try:
        deals = await hubspot_client.get_deals_for_contact(email)
        return {"deals": deals}
    except httpx.HTTPStatusError as e:
        if e.response.status_code == 404:
            raise HTTPException(status_code=404, detail="Contact not found in HubSpot")
        logger.error(f"HubSpot API error for deals {email}: {e.response.status_code}")
        raise HTTPException(status_code=502, detail=f"HubSpot API error: {e.response.status_code}")
    except httpx.HTTPError as e:
        logger.error(f"HubSpot connection error for deals {email}: {e}")
        raise HTTPException(status_code=502, detail="Failed to connect to HubSpot API")


def _resolve_id_lap(db: Session, participant_id: int, id_action_formation: str) -> str | None:
    """Resolve the LAP ID for a (participant, ADF) from ParticipantCourse if not stored on
    ParticipantHubspotData. The sync always populates ParticipantCourse.id_lap, so this
    works for any synced enrollment regardless of whether a HubSpot link existed."""
    row = (
        db.query(ParticipantCourse.id_lap)
        .join(Course, Course.id == ParticipantCourse.course_id)
        .filter(
            ParticipantCourse.participant_id == participant_id,
            Course.id_action_formation == id_action_formation,
            ParticipantCourse.id_lap.isnot(None),
        )
        .first()
    )
    return row[0] if row else None


def _record_action(
    db: Session,
    action_type: str,
    user_id: int,
    status: str,
    participant_id: int,
    id_action_formation: str,
    deal_id: str = None,
    api_calls: int = 0,
    hubspot_calls: int = 0,
    duration: float = 0.0,
    error: str = None,
    details: dict = None,
):
    """Persist an ActionHistory row."""
    row = ActionHistory(
        action_type=action_type,
        user_id=user_id,
        status=status,
        participant_id=participant_id,
        id_action_formation=id_action_formation,
        deal_id=deal_id,
        api_calls_count=api_calls,
        hubspot_api_calls_count=hubspot_calls,
        duration_seconds=duration,
        error_message=error,
        details=details,
    )
    db.add(row)
    db.commit()


@router.post("/link-deal")
async def link_deal(
    body: LinkDealRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Link a HubSpot deal to a participant's ADF enrollment.
    Pushes progression to the HubSpot deal and deal fields to the Dendreo LAP.
    Gated by the shared API budget."""
    start_time = datetime.now(timezone.utc)

    participant = db.query(Participant).filter(Participant.id == body.participant_id).first()
    if not participant:
        raise HTTPException(status_code=404, detail="Participant not found")

    # Pre-flight budget check: link pushes up to 1 Dendreo + 1 HubSpot call
    ok, reason = check_budget(db, dendreo_needed=1, hubspot_needed=1)
    if not ok:
        _record_action(
            db, 'link_deal', current_user.id, 'blocked',
            body.participant_id, body.id_action_formation, body.deal_id,
            duration=(datetime.now(timezone.utc) - start_time).total_seconds(),
            error=reason,
        )
        raise HTTPException(status_code=429, detail=reason)

    deal_url = f"https://app-eu1.hubspot.com/contacts/25868618/record/0-3/{body.deal_id}"

    # Capture the deal's EDOF session dates (best-effort read, not budget-gated).
    edof = await hubspot_client.get_deal_edof_dates(body.deal_id)

    # Upsert local link
    hubspot_data = db.query(ParticipantHubspotData).filter(
        ParticipantHubspotData.participant_id == body.participant_id,
        ParticipantHubspotData.id_action_formation == body.id_action_formation,
    ).first()

    if hubspot_data:
        hubspot_data.c_id_transaction_hubspot = body.deal_id
        hubspot_data.c_url_transaction_hubspot = deal_url
        hubspot_data.is_manual_link = True
        hubspot_data.edof_date_debut = edof.get("edof_date_debut")
        hubspot_data.edof_date_fin = edof.get("edof_date_fin")
        hubspot_data.updated_at = datetime.now(timezone.utc)
    else:
        hubspot_data = ParticipantHubspotData(
            participant_id=body.participant_id,
            id_action_formation=body.id_action_formation,
            c_id_transaction_hubspot=body.deal_id,
            c_url_transaction_hubspot=deal_url,
            is_manual_link=True,
            edof_date_debut=edof.get("edof_date_debut"),
            edof_date_fin=edof.get("edof_date_fin"),
        )
        db.add(hubspot_data)

    # Merge this deal's EDOF dates into the participant-level sessions (the display
    # source). Replace any existing entry for the same deal; keep the others.
    if edof.get("edof_date_debut") or edof.get("edof_date_fin"):
        sessions = [s for s in (participant.edof_sessions or []) if s.get("deal_id") != body.deal_id]
        sessions.append({
            "deal_id": body.deal_id,
            "date_debut": edof.get("edof_date_debut"),
            "date_fin": edof.get("edof_date_fin"),
        })
        sessions.sort(key=lambda s: s.get("date_debut") or s.get("date_fin") or "")
        participant.edof_sessions = sessions

    db.commit()

    # Push deal fields to the Dendreo LAP (local link + EDOF saved above).
    dendreo_calls = 0
    dendreo_push_ok = False
    id_lap = hubspot_data.id_lap or _resolve_id_lap(db, body.participant_id, body.id_action_formation)
    if id_lap and not hubspot_data.id_lap:
        hubspot_data.id_lap = id_lap
        db.commit()
    if id_lap and participant.id_participant:
        dendreo_calls = 1
        try:
            dendreo = DendreoClient()
            await dendreo.update_lap(
                id_lap=id_lap,
                id_participant=participant.id_participant,
                fields={
                    "c_url_transaction_hubspot": deal_url,
                    "c_id_transaction_hubspot": body.deal_id,
                },
            )
            dendreo_push_ok = True
        except DendreoAPIError as e:
            logger.warning(f"Dendreo LAP {id_lap} update failed: {e}")
        except Exception as e:
            logger.warning(f"Unexpected error updating Dendreo LAP {id_lap}: {e}")
    elif not id_lap:
        logger.info(f"Skipped Dendreo LAP push: no id_lap stored for participant {body.participant_id} ADF {body.id_action_formation}")

    cache_service.invalidate_participant_cache(body.participant_id)

    # Status: the only external write is the Dendreo LAP push (when applicable).
    if dendreo_calls == 0:
        overall = 'success'  # local link only
    elif dendreo_push_ok:
        overall = 'success'
    else:
        overall = 'error'

    duration = (datetime.now(timezone.utc) - start_time).total_seconds()
    _record_action(
        db, 'link_deal', current_user.id, overall,
        body.participant_id, body.id_action_formation, body.deal_id,
        api_calls=dendreo_calls, hubspot_calls=1, duration=duration,  # 1 HubSpot read (EDOF dates)
        details={
            "dendreo_push_ok": dendreo_push_ok,
            "edof_date_debut": edof.get("edof_date_debut"),
            "edof_date_fin": edof.get("edof_date_fin"),
        },
    )

    logger.info(
        f"Deal {body.deal_id} linked to participant {body.participant_id} ADF {body.id_action_formation} "
        f"by {current_user.username} (dendreo_push={dendreo_push_ok})"
    )
    return {
        "status": "linked",
        "deal_id": body.deal_id,
        "deal_url": deal_url,
        "dendreo_lap_pushed": dendreo_push_ok,
    }


@router.post("/unlink-deal")
async def unlink_deal(
    body: UnlinkDealRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Remove the HubSpot deal link and clear the deal fields on the Dendreo LAP."""
    start_time = datetime.now(timezone.utc)

    hubspot_data = db.query(ParticipantHubspotData).filter(
        ParticipantHubspotData.participant_id == body.participant_id,
        ParticipantHubspotData.id_action_formation == body.id_action_formation,
    ).first()

    if not hubspot_data:
        raise HTTPException(status_code=404, detail="No deal link found")

    # Pre-flight budget check (clears the Dendreo LAP: up to 1 Dendreo call)
    ok, reason = check_budget(db, dendreo_needed=1, hubspot_needed=0)
    if not ok:
        _record_action(
            db, 'unlink_deal', current_user.id, 'blocked',
            body.participant_id, body.id_action_formation,
            hubspot_data.c_id_transaction_hubspot,
            duration=(datetime.now(timezone.utc) - start_time).total_seconds(),
            error=reason,
        )
        raise HTTPException(status_code=429, detail=reason)

    prev_deal_id = hubspot_data.c_id_transaction_hubspot
    id_lap = hubspot_data.id_lap or _resolve_id_lap(db, body.participant_id, body.id_action_formation)
    participant = db.query(Participant).filter(Participant.id == body.participant_id).first()

    hubspot_data.c_id_transaction_hubspot = None
    hubspot_data.c_url_transaction_hubspot = None
    hubspot_data.is_manual_link = False
    hubspot_data.edof_date_debut = None
    hubspot_data.edof_date_fin = None
    hubspot_data.updated_at = datetime.now(timezone.utc)

    # Drop this deal from the participant-level EDOF sessions (unless another of the
    # participant's courses is still linked to the same deal).
    if participant and prev_deal_id and participant.edof_sessions:
        still_linked = (
            db.query(ParticipantHubspotData)
            .filter(
                ParticipantHubspotData.participant_id == body.participant_id,
                ParticipantHubspotData.c_id_transaction_hubspot == prev_deal_id,
                ParticipantHubspotData.id != hubspot_data.id,
            )
            .first()
        )
        if not still_linked:
            participant.edof_sessions = [
                s for s in participant.edof_sessions if s.get("deal_id") != prev_deal_id
            ]

    db.commit()

    dendreo_calls = 0
    dendreo_push_ok = False
    if id_lap and participant and participant.id_participant:
        dendreo_calls = 1
        try:
            dendreo = DendreoClient()
            await dendreo.update_lap(
                id_lap=id_lap,
                id_participant=participant.id_participant,
                fields={
                    "c_url_transaction_hubspot": "",
                    "c_id_transaction_hubspot": "",
                },
            )
            dendreo_push_ok = True
        except DendreoAPIError as e:
            logger.warning(f"Dendreo LAP {id_lap} clear failed: {e}")
        except Exception as e:
            logger.warning(f"Unexpected error clearing Dendreo LAP {id_lap}: {e}")

    cache_service.invalidate_participant_cache(body.participant_id)

    # Status: the only external write is the Dendreo LAP clear (when applicable).
    if dendreo_calls == 0:
        overall = 'success'
    elif dendreo_push_ok:
        overall = 'success'
    else:
        overall = 'error'

    duration = (datetime.now(timezone.utc) - start_time).total_seconds()
    _record_action(
        db, 'unlink_deal', current_user.id, overall,
        body.participant_id, body.id_action_formation, prev_deal_id,
        api_calls=dendreo_calls, hubspot_calls=0, duration=duration,
        details={
            "dendreo_cleared": dendreo_push_ok,
        },
    )

    logger.info(
        f"Deal unlinked from participant {body.participant_id} ADF {body.id_action_formation} "
        f"by {current_user.username} (dendreo_cleared={dendreo_push_ok})"
    )
    return {
        "status": "unlinked",
        "dendreo_lap_cleared": dendreo_push_ok,
    }
