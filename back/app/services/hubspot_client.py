import asyncio
import httpx
import logging
from datetime import datetime, timezone
from typing import Dict, Any, Optional, List
from app.config.settings import settings  # Remove 'back.' prefix

logger = logging.getLogger(__name__)

class HubSpotClient:
    def __init__(self):
        self.base_url = settings.hubspot_base_url
        self.api_key = settings.hubspot_api_key

    async def get_contact_by_email(self, email: str) -> Optional[Dict[str, Any]]:
        """Look up a HubSpot contact by email, including deal associations."""
        if not self.api_key:
            logger.warning("HubSpot API key not configured")
            return None

        url = f"{self.base_url}/crm/v3/objects/contacts/{email}"
        params = {"idProperty": "email", "associations": "deals"}
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }

        async with httpx.AsyncClient(timeout=30) as client:
            response = await client.get(url, params=params, headers=headers)
            response.raise_for_status()
            return response.json()

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

    def _get_headers(self) -> Dict[str, str]:
        return {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }

    async def get_contact_id_by_email(self, email: str) -> Optional[str]:
        """Get the HubSpot contact ID for an email."""
        result = await self.get_contact_by_email(email)
        return result.get('id') if result else None

    async def get_contact_notes(self, contact_id: str) -> List[Dict[str, Any]]:
        """Get notes associated with a contact via associations API + batch read."""
        if not self.api_key:
            return []

        headers = self._get_headers()
        try:
            async with httpx.AsyncClient(timeout=30) as client:
                # Step 1: Get associated note IDs
                assoc_url = f"{self.base_url}/crm/v3/objects/contacts/{contact_id}/associations/notes"
                response = await client.get(assoc_url, headers=headers)
                response.raise_for_status()
                assoc_data = response.json()

                note_ids = [r['id'] for r in assoc_data.get('results', [])]
                if not note_ids:
                    return []

                # Step 2: Batch read note details
                batch_url = f"{self.base_url}/crm/v3/objects/notes/batch/read"
                batch_body = {
                    "properties": ["hs_note_body", "hs_timestamp", "hubspot_owner_id"],
                    "inputs": [{"id": nid} for nid in note_ids[:100]]  # Limit to 100
                }
                batch_response = await client.post(batch_url, json=batch_body, headers=headers)
                batch_response.raise_for_status()
                batch_data = batch_response.json()

                notes = []
                for result in batch_data.get('results', []):
                    props = result.get('properties', {})
                    notes.append({
                        'id': result.get('id'),
                        'hs_note_body': props.get('hs_note_body', ''),
                        'hs_timestamp': props.get('hs_timestamp'),
                        'hubspot_owner_id': props.get('hubspot_owner_id'),
                    })
                return notes

        except httpx.HTTPStatusError as e:
            logger.error(f"HubSpot API error fetching notes for contact {contact_id}: {e.response.status_code}")
            return []
        except Exception as e:
            logger.error(f"Error fetching HubSpot notes: {e}")
            return []

    async def get_contact_calls(self, contact_id: str) -> List[Dict[str, Any]]:
        """Get call recordings associated with a contact (Ringover integration)."""
        if not self.api_key:
            return []

        headers = self._get_headers()
        try:
            async with httpx.AsyncClient(timeout=30) as client:
                # Step 1: Get associated call IDs
                assoc_url = f"{self.base_url}/crm/v3/objects/contacts/{contact_id}/associations/calls"
                response = await client.get(assoc_url, headers=headers)
                response.raise_for_status()
                assoc_data = response.json()

                call_ids = [r['id'] for r in assoc_data.get('results', [])]
                if not call_ids:
                    return []

                # Step 2: Batch read call details
                batch_url = f"{self.base_url}/crm/v3/objects/calls/batch/read"
                batch_body = {
                    "properties": [
                        "hs_call_body", "hs_call_duration", "hs_call_direction",
                        "hs_call_disposition", "hs_call_recording_url", "hs_timestamp"
                    ],
                    "inputs": [{"id": cid} for cid in call_ids[:100]]  # Limit to 100
                }
                batch_response = await client.post(batch_url, json=batch_body, headers=headers)
                batch_response.raise_for_status()
                batch_data = batch_response.json()

                calls = []
                for result in batch_data.get('results', []):
                    props = result.get('properties', {})
                    calls.append({
                        'id': result.get('id'),
                        'hs_call_body': props.get('hs_call_body', ''),
                        'hs_call_duration': props.get('hs_call_duration'),
                        'hs_call_direction': props.get('hs_call_direction'),
                        'hs_call_disposition': props.get('hs_call_disposition'),
                        'hs_call_recording_url': props.get('hs_call_recording_url'),
                        'hs_timestamp': props.get('hs_timestamp'),
                    })
                return calls

        except httpx.HTTPStatusError as e:
            logger.error(f"HubSpot API error fetching calls for contact {contact_id}: {e.response.status_code}")
            return []
        except Exception as e:
            logger.error(f"Error fetching HubSpot calls: {e}")
            return []

    async def create_note_for_contact(self, contact_id: str, note_body: str) -> Optional[str]:
        """Create a note associated with a contact. Returns the note ID or None."""
        if not self.api_key:
            logger.warning("HubSpot API key not configured, cannot create note")
            return None

        headers = self._get_headers()
        url = f"{self.base_url}/crm/v3/objects/notes"

        body = {
            "properties": {
                "hs_note_body": note_body,
                "hs_timestamp": datetime.now(timezone.utc).isoformat(),
            },
            "associations": [{
                "to": {"id": contact_id},
                "types": [{
                    "associationTypeId": 202,
                    "associationCategory": "HUBSPOT_DEFINED"
                }]
            }]
        }

        try:
            async with httpx.AsyncClient(timeout=30) as client:
                response = await client.post(url, json=body, headers=headers)
                response.raise_for_status()
                result = response.json()
                note_id = result.get('id')
                logger.info(f"Created HubSpot note {note_id} for contact {contact_id}")
                return note_id
        except httpx.HTTPError as e:
            logger.error(f"Error creating HubSpot note for contact {contact_id}: {e}")
            return None
        except Exception as e:
            logger.error(f"Unexpected error creating HubSpot note: {e}")
            return None

    async def get_contact_engagements(self, email: str) -> Dict[str, Any]:
        """Get all notes and calls for a contact by email. Uses parallel fetching."""
        contact_id = await self.get_contact_id_by_email(email)
        if not contact_id:
            return {'contact_id': None, 'notes': [], 'calls': []}

        notes, calls = await asyncio.gather(
            self.get_contact_notes(contact_id),
            self.get_contact_calls(contact_id),
        )
        return {'contact_id': contact_id, 'notes': notes, 'calls': calls}


# Create client instance
hubspot_client = HubSpotClient()
