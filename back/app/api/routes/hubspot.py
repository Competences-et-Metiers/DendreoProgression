from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
import httpx
import logging
from datetime import datetime, timezone

from app.services.hubspot_client import hubspot_client
from app.models.database import get_db
from app.models.models import Participant, ParticipantHubspotData, User
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


@router.post("/link-deal")
async def link_deal(
    body: LinkDealRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Link a HubSpot deal to a participant's ADF enrollment."""
    participant = db.query(Participant).filter(Participant.id == body.participant_id).first()
    if not participant:
        raise HTTPException(status_code=404, detail="Participant not found")

    deal_url = f"https://app.hubspot.com/contacts/deal/{body.deal_id}"

    # Upsert: find existing or create new
    hubspot_data = db.query(ParticipantHubspotData).filter(
        ParticipantHubspotData.participant_id == body.participant_id,
        ParticipantHubspotData.id_action_formation == body.id_action_formation,
    ).first()

    if hubspot_data:
        hubspot_data.c_id_transaction_hubspot = body.deal_id
        hubspot_data.c_url_transaction_hubspot = deal_url
        hubspot_data.is_manual_link = True
        hubspot_data.updated_at = datetime.now(timezone.utc)
    else:
        hubspot_data = ParticipantHubspotData(
            participant_id=body.participant_id,
            id_action_formation=body.id_action_formation,
            c_id_transaction_hubspot=body.deal_id,
            c_url_transaction_hubspot=deal_url,
            is_manual_link=True,
        )
        db.add(hubspot_data)

    db.commit()

    cache_service.invalidate_participant_cache(body.participant_id)

    logger.info(f"Deal {body.deal_id} linked to participant {body.participant_id} ADF {body.id_action_formation} by {current_user.username}")
    return {"status": "linked", "deal_id": body.deal_id, "deal_url": deal_url}


@router.post("/unlink-deal")
async def unlink_deal(
    body: UnlinkDealRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Remove the HubSpot deal link from a participant's ADF enrollment."""
    hubspot_data = db.query(ParticipantHubspotData).filter(
        ParticipantHubspotData.participant_id == body.participant_id,
        ParticipantHubspotData.id_action_formation == body.id_action_formation,
    ).first()

    if not hubspot_data:
        raise HTTPException(status_code=404, detail="No deal link found")

    hubspot_data.c_id_transaction_hubspot = None
    hubspot_data.c_url_transaction_hubspot = None
    hubspot_data.is_manual_link = False
    hubspot_data.updated_at = datetime.now(timezone.utc)
    db.commit()

    cache_service.invalidate_participant_cache(body.participant_id)

    logger.info(f"Deal unlinked from participant {body.participant_id} ADF {body.id_action_formation} by {current_user.username}")
    return {"status": "unlinked"}
