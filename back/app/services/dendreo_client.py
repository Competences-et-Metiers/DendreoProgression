import httpx
import logging
import json
import asyncio
import os
from typing import Dict, Any, List, Optional
from collections import deque
from datetime import datetime, timedelta
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

        # Rate limiting configuration (100 requests per 10 seconds as per Dendreo's limit)
        self.rate_limit_requests = int(os.getenv('DENDREO_RATE_LIMIT_REQUESTS', '95'))  # Use 95 to stay safely under 100
        self.rate_limit_window = int(os.getenv('DENDREO_RATE_LIMIT_WINDOW', '10'))  # 10 seconds
        self.request_timestamps = deque()  # Track request timestamps for rate limiting
        self.total_requests = 0  # Track total requests made during sync

        logger.info(f"Initialized DendreoClient with base URL: {self.base_url}")
        logger.info(f"Rate limiting: {self.rate_limit_requests} requests per {self.rate_limit_window} seconds")

    async def _wait_for_rate_limit(self):
        """Wait if we're at the rate limit to comply with API constraints"""
        now = datetime.now()
        cutoff_time = now - timedelta(seconds=self.rate_limit_window)

        # Remove timestamps older than the rate limit window
        while self.request_timestamps and self.request_timestamps[0] < cutoff_time:
            self.request_timestamps.popleft()

        # If we're at or over the limit, wait until we can make another request
        if len(self.request_timestamps) >= self.rate_limit_requests:
            # Calculate how long to wait (time until oldest timestamp expires + small buffer)
            oldest_timestamp = self.request_timestamps[0]
            wait_until = oldest_timestamp + timedelta(seconds=self.rate_limit_window + 0.1)
            wait_seconds = (wait_until - now).total_seconds()

            if wait_seconds > 0:
                logger.warning(
                    f"⏳ Rate limit reached ({len(self.request_timestamps)}/{self.rate_limit_requests} "
                    f"requests in {self.rate_limit_window}s). Waiting {wait_seconds:.2f}s..."
                )
                await asyncio.sleep(wait_seconds)

                # Clean up old timestamps again after waiting
                now = datetime.now()
                cutoff_time = now - timedelta(seconds=self.rate_limit_window)
                while self.request_timestamps and self.request_timestamps[0] < cutoff_time:
                    self.request_timestamps.popleft()

    async def _make_request(self, endpoint: str, params: Dict[str, Any] = None) -> Any:
        """Make a request to the Dendreo API with rate limiting"""
        # Wait if we're at the rate limit
        await self._wait_for_rate_limit()

        url = f"{self.base_url}/{endpoint}"
        params = params or {}
        params['key'] = self.api_key

        # Record this request timestamp
        self.request_timestamps.append(datetime.now())
        self.total_requests += 1

        # Log progress every 50 requests
        if self.total_requests % 50 == 0:
            logger.info(f"📊 API requests: {self.total_requests} total, {len(self.request_timestamps)} in last {self.rate_limit_window}s")
        else:
            logger.debug(f"Making request to Dendreo API: {url}")

        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(url, params=params, timeout=120.0)

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

    async def get_laps(self, id_action_formation: str) -> List[Dict[str, Any]]:
        """Get all LAPS data for a specific ADF"""
        params = {
            "id_action_de_formation": id_action_formation
        }
        try:
            response = await self._make_request("laps.php", params)
            return response if response and isinstance(response, list) else []
        except DendreoAPIError:
            logger.warning(f"No LAPS data found for ADF {id_action_formation}")
            return []

    async def get_lmps_for_lap(self, id_lap: str) -> List[Dict[str, Any]]:
        """Get LMPs data for a specific LAP (participant enrollment)"""
        params = {
            "id_lap": id_lap,
            "include": "participant,module"
        }
        try:
            response = await self._make_request("lmps.php", params)
            return response if response and isinstance(response, list) else []
        except DendreoAPIError:
            logger.warning(f"No LMPs data found for LAP {id_lap}")
            return []

    async def get_lmps_data(self) -> List[Dict[str, Any]]:
        """Legacy method - use get_lmps() instead"""
        return await self.get_lmps()

    async def get_course_data(self, course_id: str) -> Dict[str, Any]:
        """Get data for a specific course by its LAM ID"""
        data = await self.get_lmps()
        return next((lmp for lmp in data if lmp.get("id_lam") == course_id), {})

    def get_rate_limit_stats(self) -> Dict[str, Any]:
        """Get current rate limiting statistics"""
        now = datetime.now()
        cutoff_time = now - timedelta(seconds=self.rate_limit_window)

        # Count requests in current window
        current_window_count = sum(1 for ts in self.request_timestamps if ts >= cutoff_time)

        return {
            "total_requests": self.total_requests,
            "requests_in_current_window": current_window_count,
            "rate_limit": f"{self.rate_limit_requests} requests per {self.rate_limit_window}s",
            "percentage_of_limit": f"{(current_window_count / self.rate_limit_requests * 100):.1f}%"
        }

    def reset_rate_limit_stats(self):
        """Reset rate limiting statistics (useful at start of new sync)"""
        self.request_timestamps.clear()
        self.total_requests = 0
        logger.info("🔄 Rate limiting statistics reset")

# Create client instance
dendreo_client = DendreoClient()
