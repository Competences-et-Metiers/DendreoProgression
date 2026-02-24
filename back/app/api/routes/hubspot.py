from fastapi import APIRouter, HTTPException
import httpx
import logging

from app.services.hubspot_client import hubspot_client

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
