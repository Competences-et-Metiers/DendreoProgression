import httpx
import logging
from typing import List, Dict, Any, Optional
from app.config.settings import settings
from app.models.schemas import DendreoADF, DendreoCourse, DendreoParticipant

logger = logging.getLogger(__name__)

class DendreoClient:
    def __init__(self):
        self.base_url = settings.dendreo_base_url
        self.api_key = settings.dendreo_api_key
        self.client = httpx.AsyncClient(timeout=30.0)

    async def close(self):
        await self.client.aclose()

    async def get_lmps(self) -> List[Dict[str, Any]]:
        """Get all LMPS (modules) from Dendreo API"""
        url = f"{self.base_url}/lmps.php"
        params = {
            "key": self.api_key,
            "include": "participant,module"
        }

        try:
            response = await self.client.get(url, params=params)
            response.raise_for_status()
            data = response.json()
            logger.info(f"Successfully fetched {len(data)} LMPS records")
            return data
        except httpx.RequestError as e:
            logger.error(f"Error fetching LMPS: {e}")
            raise
        except httpx.HTTPStatusError as e:
            logger.error(f"HTTP error fetching LMPS: {e}")
            raise

    async def get_actions_de_formation(self) -> List[DendreoADF]:
        """Get all ADFs (training sessions) from Dendreo API"""
        url = f"{self.base_url}/actions_de_formation.php"
        params = {
            "key": self.api_key,
            "include": "modules,participant,etapeProcess"
        }

        try:
            response = await self.client.get(url, params=params)
            response.raise_for_status()
            data = response.json()

            # Filter only active sessions (id_etape_process = 5 or 6)
            active_adfs = []
            for adf in data:
                if adf.get("id_etape_process") in ["5", "6"]:
                    active_adfs.append(DendreoADF(**adf))

            logger.info(f"Successfully fetched {len(active_adfs)} active ADFs")
            return active_adfs
        except httpx.RequestError as e:
            logger.error(f"Error fetching ADFs: {e}")
            raise
        except httpx.HTTPStatusError as e:
            logger.error(f"HTTP error fetching ADFs: {e}")
            raise

    async def get_laps(self, id_action_de_formation: str) -> List[DendreoParticipant]:
        """Get LAPS (participant details) for a specific ADF"""
        url = f"{self.base_url}/laps.php"
        params = {
            "id_action_de_formation": id_action_de_formation,
            "key": self.api_key,
            "include": "participactions"
        }

        try:
            response = await self.client.get(url, params=params)
            response.raise_for_status()
            data = response.json()

            participants = []
            for lap in data:
                if lap.get("participant"):
                    participant_data = {
                        "id_participant": lap["participant"]["id_participant"],
                        "nom": lap["participant"]["nom"],
                        "prenom": lap["participant"]["prenom"],
                        "email": lap["participant"]["email"],
                        "c_url_transaction_hubspot": lap.get("c_url_transaction_hubspot", ""),
                        "c_id_transaction_hubspot": lap.get("c_id_transaction_hubspot", "")
                    }
                    participants.append(DendreoParticipant(**participant_data))

            logger.info(f"Successfully fetched {len(participants)} participants for ADF {id_action_de_formation}")
            return participants
        except httpx.RequestError as e:
            logger.error(f"Error fetching LAPS for ADF {id_action_de_formation}: {e}")
            raise
        except httpx.HTTPStatusError as e:
            logger.error(f"HTTP error fetching LAPS for ADF {id_action_de_formation}: {e}")
            raise
