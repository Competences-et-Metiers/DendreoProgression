import httpx
import logging
import json
from typing import Dict, Any, List, Optional
from app.config.settings import settings

logger = logging.getLogger(__name__)

class DendreoAPIError(Exception):
    """Custom exception for Dendreo API errors"""
    pass

class DendreoClient:
    def __init__(self):
        # Validate settings
        if not settings.dendreo_base_url:
            raise DendreoAPIError("DENDREO_BASE_URL is not set in environment variables")
        if not settings.dendreo_api_key:
            raise DendreoAPIError("DENDREO_API_KEY is not set in environment variables")

        self.base_url = settings.dendreo_base_url.rstrip('/')  # Remove trailing slash if present
        self.api_key = settings.dendreo_api_key
        
        logger.info(f"Initialized DendreoClient with base URL: {self.base_url}")

    async def _make_request(self, endpoint: str, params: Dict[str, Any] = None) -> Any:
        """Make a request to the Dendreo API"""
        url = f"{self.base_url}/{endpoint}"
        params = params or {}
        params['key'] = self.api_key

        logger.info(f"Making request to Dendreo API: {url}")

        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(url, params=params, timeout=30.0)
                
                if response.status_code == 401:
                    raise DendreoAPIError("Invalid API key or unauthorized access")
                
                if response.status_code == 404:
                    raise DendreoAPIError(f"API endpoint not found: {url}")
                
                response.raise_for_status()
                return response.json()

        except httpx.TimeoutException:
            raise DendreoAPIError(f"Request timed out: {url}")
        except httpx.RequestError as e:
            raise DendreoAPIError(f"Request failed: {str(e)}")
        except ValueError as e:
            raise DendreoAPIError(f"Invalid JSON response: {str(e)}")

    async def get_lmps(self) -> List[Dict[str, Any]]:
        """Get all LMPs (modules) with participant and module data"""
        params = {"include": "participant,module"}
        return await self._make_request("lmps.php", params)

    async def get_actions_de_formation(self) -> List[Dict[str, Any]]:
        """Get all Actions de Formation (ADFs) with modules and participant data"""
        params = {"include": "modules,participant,etapeProcess,mode_organisation"}
        return await self._make_request("actions_de_formation.php", params)

    async def get_laps(self, id_action_formation: str) -> Optional[Dict[str, Any]]:
        """Get LAPS data for a specific ADF"""
        params = {
            "id_action_de_formation": id_action_formation,
            "include": "participactions,mode_organisation"
        }
        try:
            response = await self._make_request("laps.php", params)
            return response[0] if response and isinstance(response, list) else None
        except DendreoAPIError:
            logger.warning(f"No LAPS data found for ADF {id_action_formation}")
            return None

    async def get_lmps_data(self) -> List[Dict[str, Any]]:
        """Legacy method - use get_lmps() instead"""
        return await self.get_lmps()

    async def get_course_data(self, course_id: str) -> Dict[str, Any]:
        """Get data for a specific course by its LAM ID"""
        data = await self.get_lmps()
        return next((lmp for lmp in data if lmp.get("id_lam") == course_id), {})

# Create client instance
dendreo_client = DendreoClient()
