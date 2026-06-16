import asyncio
import httpx
import logging
from datetime import datetime, timezone
from typing import Dict, Any, Optional, List
from app.config.settings import settings  # Remove 'back.' prefix

logger = logging.getLogger(__name__)

# HubSpot deal property internal names for the EDOF session dates
# (form labels: "Date Début Session EDOF" / "Date Fin Session EDOF").
EDOF_DATE_DEBUT_PROP = "date_debut_formation"
EDOF_DATE_FIN_PROP = "date_fin_formation_edof"


def normalize_hs_date(value: Any) -> Optional[str]:
    """Normalize a HubSpot date property value to an ISO 'YYYY-MM-DD' string.

    HubSpot date properties come back either as epoch-millis strings (midnight UTC)
    or as ISO date/datetime strings depending on the property/endpoint. Returns None
    for empty/unparseable values."""
    if value is None:
        return None
    s = str(value).strip()
    if not s:
        return None
    if s.isdigit():  # epoch milliseconds
        try:
            return datetime.fromtimestamp(int(s) / 1000, tz=timezone.utc).strftime("%Y-%m-%d")
        except (ValueError, OSError, OverflowError):
            return None
    return s[:10]  # ISO date or datetime -> keep the date part


class HubSpotClient:
    _OWNERS_CACHE_TTL_SEC = 600

    def __init__(self):
        self.base_url = settings.hubspot_base_url
        self.api_key = settings.hubspot_api_key
        self._owners_cache: Optional[Dict[str, str]] = None
        self._owners_cache_ts: Optional[datetime] = None

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

    def _get_headers(self) -> Dict[str, str]:
        return {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }

    async def update_deal_properties(self, deal_id: str, properties: Dict[str, Any]) -> bool:
        """PATCH deal properties via v3 API. Returns True on success, False on failure."""
        if not self.api_key:
            logger.warning("HubSpot API key not configured")
            return False

        url = f"{self.base_url}/crm/v3/objects/deals/{deal_id}"
        body = {"properties": {k: str(v) for k, v in properties.items()}}

        try:
            async with httpx.AsyncClient(timeout=30) as client:
                response = await client.patch(url, json=body, headers=self._get_headers())
                response.raise_for_status()
                logger.info(f"Updated HubSpot deal {deal_id} with properties {list(properties.keys())}")
                return True
        except httpx.HTTPStatusError as e:
            logger.error(f"HubSpot deal {deal_id} PATCH failed: {e.response.status_code} {e.response.text}")
            return False
        except httpx.HTTPError as e:
            logger.error(f"HubSpot connection error updating deal {deal_id}: {e}")
            return False

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
                        "hs_call_disposition", "hs_call_recording_url", "hs_timestamp",
                        "hubspot_owner_id",
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
                        'hubspot_owner_id': props.get('hubspot_owner_id'),
                    })
                return calls

        except httpx.HTTPStatusError as e:
            logger.error(f"HubSpot API error fetching calls for contact {contact_id}: {e.response.status_code}")
            return []
        except Exception as e:
            logger.error(f"Error fetching HubSpot calls: {e}")
            return []

    async def get_deals_for_contact(self, email: str) -> List[Dict[str, Any]]:
        """Fetch all deals associated with a HubSpot contact by email.
        Returns list of dicts: [{id, dealname, amount}, ...]."""
        if not self.api_key:
            return []

        try:
            contact = await self.get_contact_by_email(email)
        except Exception:
            return []

        if not contact:
            return []

        # Extract deal IDs from associations
        deal_ids = []
        associations = contact.get('associations', {})
        deals_assoc = associations.get('deals', {})
        for result in deals_assoc.get('results', []):
            deal_id = result.get('id')
            if deal_id:
                deal_ids.append(deal_id)

        if not deal_ids:
            return []

        # Batch read deal details
        headers = self._get_headers()
        try:
            async with httpx.AsyncClient(timeout=30) as client:
                batch_url = f"{self.base_url}/crm/v3/objects/deals/batch/read"
                batch_body = {
                    "properties": [
                        "dealname", "amount", "formation_detaillee",
                        EDOF_DATE_DEBUT_PROP, EDOF_DATE_FIN_PROP,
                    ],
                    "inputs": [{"id": did} for did in deal_ids[:100]]
                }
                response = await client.post(batch_url, json=batch_body, headers=headers)
                response.raise_for_status()
                batch_data = response.json()

                deals = []
                for result in batch_data.get('results', []):
                    props = result.get('properties', {})
                    deals.append({
                        'id': result.get('id'),
                        'dealname': props.get('dealname', ''),
                        'amount': props.get('amount'),
                        'formation_detaillee': props.get('formation_detaillee'),
                        'edof_date_debut': normalize_hs_date(props.get(EDOF_DATE_DEBUT_PROP)),
                        'edof_date_fin': normalize_hs_date(props.get(EDOF_DATE_FIN_PROP)),
                    })
                return deals

        except httpx.HTTPStatusError as e:
            logger.error(f"HubSpot API error fetching deals for {email}: {e.response.status_code}")
            return []
        except Exception as e:
            logger.error(f"Error fetching HubSpot deals for {email}: {e}")
            return []

    async def get_deal_edof_dates(self, deal_id: str) -> Dict[str, Optional[str]]:
        """Fetch the EDOF session dates for a single deal.
        Returns {'edof_date_debut': ..., 'edof_date_fin': ...} (ISO dates or None)."""
        empty = {"edof_date_debut": None, "edof_date_fin": None}
        if not self.api_key or not deal_id:
            return empty

        url = f"{self.base_url}/crm/v3/objects/deals/{deal_id}"
        params = {"properties": f"{EDOF_DATE_DEBUT_PROP},{EDOF_DATE_FIN_PROP}"}
        try:
            async with httpx.AsyncClient(timeout=30) as client:
                response = await client.get(url, params=params, headers=self._get_headers())
                response.raise_for_status()
                props = response.json().get("properties", {})
                return {
                    "edof_date_debut": normalize_hs_date(props.get(EDOF_DATE_DEBUT_PROP)),
                    "edof_date_fin": normalize_hs_date(props.get(EDOF_DATE_FIN_PROP)),
                }
        except httpx.HTTPError as e:
            logger.warning(f"Failed to fetch EDOF dates for deal {deal_id}: {e}")
            return empty

    async def get_owner_by_email(self, email: str) -> Optional[str]:
        """Look up a HubSpot owner ID by email. Returns owner ID or None."""
        if not self.api_key or not email:
            return None

        headers = self._get_headers()
        email_lower = email.lower()
        try:
            async with httpx.AsyncClient(timeout=15) as client:
                url = f"{self.base_url}/crm/v3/owners"
                params = {"email": email_lower, "limit": 100}
                response = await client.get(url, params=params, headers=headers)
                response.raise_for_status()
                data = response.json()
                # Filter by exact email match — the API may return all owners
                for owner in data.get('results', []):
                    if owner.get('email', '').lower() == email_lower:
                        owner_id = owner.get('id')
                        logger.info(f"HubSpot owner match: {email} -> owner_id={owner_id}")
                        return owner_id
                logger.warning(f"No HubSpot owner found for email {email}. "
                             f"Available: {[o.get('email') for o in data.get('results', [])]}")
                return None
        except Exception as e:
            logger.warning(f"Failed to look up HubSpot owner for {email}: {e}")
            return None

    async def create_note_for_contact(
        self, contact_id: str, note_body: str, owner_id: Optional[str] = None
    ) -> Optional[str]:
        """Create a note associated with a contact. Optionally attributed to a HubSpot owner.
        Returns the note ID or None."""
        if not self.api_key:
            logger.warning("HubSpot API key not configured, cannot create note")
            return None

        headers = self._get_headers()
        url = f"{self.base_url}/crm/v3/objects/notes"

        properties = {
            "hs_note_body": note_body,
            "hs_timestamp": datetime.now(timezone.utc).isoformat(),
        }
        if owner_id:
            properties["hubspot_owner_id"] = owner_id

        body = {
            "properties": properties,
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
                logger.info(f"Created HubSpot note {note_id} for contact {contact_id} (owner={owner_id})")
                return note_id
        except httpx.HTTPError as e:
            logger.error(f"Error creating HubSpot note for contact {contact_id}: {e}")
            return None
        except Exception as e:
            logger.error(f"Unexpected error creating HubSpot note: {e}")
            return None

    async def delete_note(self, note_id: str) -> bool:
        """Delete a note from HubSpot. Returns True on success."""
        if not self.api_key:
            return False

        headers = self._get_headers()
        url = f"{self.base_url}/crm/v3/objects/notes/{note_id}"
        try:
            async with httpx.AsyncClient(timeout=15) as client:
                response = await client.delete(url, headers=headers)
                response.raise_for_status()
                logger.info(f"Deleted HubSpot note {note_id}")
                return True
        except Exception as e:
            logger.error(f"Failed to delete HubSpot note {note_id}: {e}")
            return False

    async def get_owners_map(self) -> Dict[str, str]:
        """Return {owner_id: display_name} for all HubSpot owners. Cached in-process for 10min.
        Falls back to empty dict on auth failure (e.g. missing crm.objects.owners.read scope)."""
        now = datetime.now(timezone.utc)
        if (
            self._owners_cache is not None
            and self._owners_cache_ts
            and (now - self._owners_cache_ts).total_seconds() < self._OWNERS_CACHE_TTL_SEC
        ):
            return self._owners_cache

        if not self.api_key:
            return {}

        headers = self._get_headers()
        owners: Dict[str, str] = {}
        try:
            async with httpx.AsyncClient(timeout=15) as client:
                url = f"{self.base_url}/crm/v3/owners"
                after = None
                while True:
                    params = {"limit": 100}
                    if after:
                        params["after"] = after
                    response = await client.get(url, params=params, headers=headers)
                    response.raise_for_status()
                    data = response.json()
                    for owner in data.get('results', []):
                        oid = owner.get('id')
                        if not oid:
                            continue
                        first = (owner.get('firstName') or '').strip()
                        last = (owner.get('lastName') or '').strip()
                        full = f"{first} {last}".strip()
                        owners[oid] = full or owner.get('email') or oid
                    paging = data.get('paging', {}).get('next', {})
                    after = paging.get('after')
                    if not after:
                        break
            self._owners_cache = owners
            self._owners_cache_ts = now
            return owners
        except httpx.HTTPStatusError as e:
            logger.warning(f"HubSpot owners list failed ({e.response.status_code}); owner names unavailable")
            return self._owners_cache or {}
        except Exception as e:
            logger.warning(f"Failed to fetch HubSpot owners: {e}")
            return self._owners_cache or {}

    async def get_contact_engagements(self, email: str) -> Dict[str, Any]:
        """Get all notes and calls for a contact by email. Uses parallel fetching."""
        contact_id = await self.get_contact_id_by_email(email)
        if not contact_id:
            return {'contact_id': None, 'notes': [], 'calls': []}

        notes, calls, owners_map = await asyncio.gather(
            self.get_contact_notes(contact_id),
            self.get_contact_calls(contact_id),
            self.get_owners_map(),
        )
        if owners_map:
            for n in notes:
                oid = n.get('hubspot_owner_id')
                if oid:
                    n['hubspot_owner_name'] = owners_map.get(oid)
            for c in calls:
                oid = c.get('hubspot_owner_id')
                if oid:
                    c['hubspot_owner_name'] = owners_map.get(oid)
        return {'contact_id': contact_id, 'notes': notes, 'calls': calls}


# Create client instance
hubspot_client = HubSpotClient()
