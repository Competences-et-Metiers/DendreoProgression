import httpx
import logging
from typing import Dict, Any, Optional
from app.config.settings import settings  # Remove 'back.' prefix

logger = logging.getLogger(__name__)

class HubSpotClient:
    def __init__(self):
        self.base_url = settings.hubspot_base_url
        self.api_key = settings.hubspot_api_key

    async def update_transaction_progress(self, transaction_id: str, progression: float, status: str) -> bool:
        """Update progress in HubSpot transaction"""
        if not self.api_key:
            logger.warning("HubSpot API key not configured")
            return False

        # This would be the actual HubSpot API call
        # Implementation depends on your HubSpot setup
        url = f"{self.base_url}/deals/v1/deal/{transaction_id}"

        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }

        data = {
            "properties": [
                {
                    "name": "course_progression",
                    "value": str(progression)
                },
                {
                    "name": "activity_status",
                    "value": status
                }
            ]
        }

        try:
            async with httpx.AsyncClient() as client:
                response = await client.put(url, json=data, headers=headers)
                response.raise_for_status()
                logger.info(f"Updated HubSpot transaction {transaction_id}")
                return True
        except httpx.HTTPError as e:
            logger.error(f"Error updating HubSpot transaction: {e}")
            return False
        except Exception as e:
            logger.error(f"Unexpected error updating HubSpot: {e}")
            return False

# Create client instance
hubspot_client = HubSpotClient()
