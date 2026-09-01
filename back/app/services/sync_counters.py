"""Live API-call counters written during a sync run.

The sync writes a small JSON file that the admin dashboard polls to show API
usage while a sync is in flight. Shared by every phase that spends HubSpot calls
(auto-link, deal refresh) so the displayed count stays honest.
"""

import json
import logging
import os
import tempfile

logger = logging.getLogger(__name__)

COUNTERS_PATH = "/app/logs/sync_api_counters.json"


def bump_hubspot_counter(n: int) -> None:
    """Best-effort additive update of the live sync API counter file."""
    if not n:
        return
    try:
        current = {"dendreo": 0, "hubspot": 0}
        if os.path.exists(COUNTERS_PATH):
            with open(COUNTERS_PATH, "r") as f:
                current = json.load(f)
        current["hubspot"] = current.get("hubspot", 0) + n
        fd, tmp = tempfile.mkstemp(dir="/tmp", prefix="sync_api_")
        with os.fdopen(fd, "w") as f:
            json.dump(current, f)
        os.replace(tmp, COUNTERS_PATH)
    except Exception:
        pass
