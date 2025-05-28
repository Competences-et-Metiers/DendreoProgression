import httpx
import logging
from typing import Dict, Any, Optional
from app.config.settings import settings

logger = logging.getLogger(__name__)

class HubSpotClient:
    def __init__(self):
        self.api_key = settings.hubspot_api_key
        self.base_url = "https://api.hubapi.com"
        self.client = httpx.AsyncClient(timeout=30.0)

    async def close(self):
        await self.client.aclose()

    async def update_transaction_progression(self, transaction_id: str, progression: float) -> bool:
        """Update progression in HubSpot transaction"""
        if not self.api_key or not transaction_id:
            logger.warning("HubSpot API key or transaction ID missing")
            return False

        url = f"{self.base_url}/crm/v3/objects/deals/{transaction_id}"
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }

        data = {
            "properties": {
                "progression": str(progression)  # Adjust property name as needed
            }
        }

        try:
            response = await self.client.patch(url, headers=headers, json=data)
            response.raise_for_status()
            logger.info(f"Successfully updated HubSpot transaction {transaction_id} with progression {progression}")
            return True
        except httpx.RequestError as e:
            logger.error(f"Error updating HubSpot transaction {transaction_id}: {e}")
            return False
        except httpx.HTTPStatusError as e:
            logger.error(f"HTTP error updating HubSpot transaction {transaction_id}: {e}")
            return False
