import httpx
import logging
from typing import Dict, Any, List
from app.config.settings import settings  # Remove 'back.' prefix

logger = logging.getLogger(__name__)

class DendreoClient:
    def __init__(self):
        self.base_url = settings.dendreo_base_url
        self.api_key = settings.dendreo_api_key

    async def get_lmps_data(self) -> Dict[str, Any]:
        """Fetch LMPs data from Dendreo API"""
        url = f"{self.base_url}/lmps.php"
        params = {
            "key": self.api_key,
            "include": "participant,module"
        }

        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(url, params=params)
                response.raise_for_status()
                return response.json()
        except httpx.HTTPError as e:
            logger.error(f"Error fetching Dendreo data: {e}")
            raise
        except Exception as e:
            logger.error(f"Unexpected error: {e}")
            raise

    async def get_course_data(self, course_id: str) -> Dict[str, Any]:
        """Fetch specific course data from Dendreo API"""
        # This would be a specific endpoint for a course if available
        # For now, we'll filter from the main endpoint
        data = await self.get_lmps_data()

        # Filter for specific course
        for lmp in data.get("lmps", []):
            if lmp.get("id_lam") == course_id:
                return lmp

        return {}

# Create client instance
dendreo_client = DendreoClient()
