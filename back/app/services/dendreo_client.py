import httpx
import logging
import json
from typing import Dict, Any, List
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

    async def get_lmps_data(self) -> List[Dict[str, Any]]:
        """Fetch LMPs data from Dendreo API"""
        url = f"{self.base_url}/lmps.php"
        params = {
            "key": self.api_key,
            "include": "participant,module"
        }

        logger.info(f"Making request to Dendreo API: {url}")
        # Force debug output
        print(f"\nDEBUG - Request parameters: {params}")

        try:
            async with httpx.AsyncClient() as client:
                try:
                    response = await client.get(url, params=params, timeout=30.0)
                    # Force debug output
                    print(f"\nDEBUG - Response status code: {response.status_code}")
                    print(f"DEBUG - Response headers: {dict(response.headers)}")
                    
                    # Log response content type
                    content_type = response.headers.get('content-type', 'unknown')
                    print(f"DEBUG - Response content type: {content_type}")
                    
                    if response.status_code == 401:
                        error_msg = "Invalid API key or unauthorized access"
                        logger.error(f"{error_msg}. Response: {response.text}")
                        raise DendreoAPIError(error_msg)
                    
                    if response.status_code == 404:
                        error_msg = f"API endpoint not found: {url}"
                        logger.error(error_msg)
                        raise DendreoAPIError(error_msg)
                    
                    try:
                        response.raise_for_status()
                    except httpx.HTTPStatusError as e:
                        error_msg = f"HTTP error occurred: {e.response.status_code} - {e.response.text}"
                        logger.error(error_msg)
                        raise DendreoAPIError(error_msg) from e

                    # Log the raw response text for debugging
                    response_text = response.text
                    print(f"\nDEBUG - Raw response preview (first 500 chars):\n{response_text[:500]}")

                    try:
                        data = response.json()
                        # Log the parsed data structure
                        print(f"\nDEBUG - Response data type: {type(data)}")
                        if isinstance(data, dict):
                            print(f"DEBUG - Response data keys: {list(data.keys())}")
                        elif isinstance(data, list):
                            print(f"DEBUG - Response data is a list with {len(data)} items")
                            if data:
                                print(f"DEBUG - First item preview: {json.dumps(data[0], indent=2)[:200]}...")
                        else:
                            print(f"DEBUG - Response data is of unexpected type: {type(data)}")
                        
                        if not isinstance(data, list):
                            raise DendreoAPIError(f"Expected list response but got {type(data)}")
                            
                        return data

                    except ValueError as e:
                        error_msg = f"Invalid JSON response from API: {response_text[:200]}..."
                        logger.error(error_msg)
                        raise DendreoAPIError(error_msg) from e

                except httpx.TimeoutException as e:
                    error_msg = f"Request timed out while connecting to Dendreo API: {url}"
                    logger.error(error_msg)
                    raise DendreoAPIError(error_msg) from e

        except httpx.RequestError as e:
            error_msg = f"Network error occurred while connecting to Dendreo API ({url}): {str(e)}"
            logger.error(error_msg)
            raise DendreoAPIError(error_msg) from e
        except Exception as e:
            error_msg = f"Unexpected error while connecting to Dendreo API ({url}): {str(e)}"
            logger.error(error_msg)
            raise DendreoAPIError(error_msg) from e

    async def get_course_data(self, course_id: str) -> Dict[str, Any]:
        """Fetch specific course data from Dendreo API"""
        try:
            data = await self.get_lmps_data()

            # Filter for specific course
            for lmp in data:
                if lmp.get("id_lam") == course_id:
                    return lmp

            return {}
        except Exception as e:
            logger.error(f"Error fetching course data: {str(e)}")
            raise

# Create client instance
dendreo_client = DendreoClient()
