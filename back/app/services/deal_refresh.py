"""
Refresh the HubSpot deal fields mirrored on existing links.

Every linked (participant, ADF) row carries a copy of its deal's financial and
billing fields so pages can render them without hitting HubSpot. Those copies go
stale when someone edits the deal in HubSpot — most importantly `facturation`,
which the accounting team also edits on the HubSpot side. This module re-reads
the linked deals and writes back what changed.

Cheap by construction: deals are read in batches of 100 (one HubSpot call per
batch) and each distinct deal is fetched once no matter how many courses link to
it — roughly a dozen calls for the whole population.

Used by both the periodic sync (as a phase, see dendreo_sync.sync_all) and the
CLI (`scripts/refresh_deal_fields.py`), mirroring how edof_auto_link.py is
shared. Performs NO writes to HubSpot or Dendreo — only the local database.
"""

import logging
from datetime import datetime, timezone
from typing import Any, Callable, Dict, List, Optional

from sqlalchemy.orm import Session

from app.models.models import Participant, ParticipantHubspotData
from app.services.hubspot_client import DEAL_FINANCE_FIELDS, hubspot_client
from app.services.sync_counters import bump_hubspot_counter

logger = logging.getLogger(__name__)

BATCH_SIZE = 100
EDOF_FIELDS = ("edof_date_debut", "edof_date_fin")


def _new_stats() -> Dict[str, Any]:
    return {
        "rows_scanned": 0,
        "updated": 0,
        "unchanged": 0,
        "deal_not_found": 0,
        "edof_sessions_updated": 0,
        "hubspot_calls": 0,
        "budget_stopped": False,
    }


def _merge_edof_session(participant: Participant, deal_id: str, debut: Optional[str], fin: Optional[str]) -> None:
    """Update this deal's entry in the participant's EDOF sessions list.

    `Participant.edof_sessions` is what the UI actually displays (the per-row
    edof_date_* columns are only the per-link copy), so a date change has to be
    propagated here too. Entries for other deals are left alone.
    """
    sessions = [s for s in (participant.edof_sessions or []) if s.get("deal_id") != deal_id]
    if debut or fin:
        sessions.append({"deal_id": deal_id, "date_debut": debut, "date_fin": fin})
    sessions.sort(key=lambda s: s.get("date_debut") or s.get("date_fin") or "")
    participant.edof_sessions = sessions


async def refresh_deal_fields(
    db: Session,
    *,
    commit: bool = True,
    only_missing: bool = False,
    with_edof: bool = True,
    limit: int = 0,
    max_hubspot_calls: Optional[int] = None,
    update_counter: bool = False,
    log: Callable[[str], None] = logger.info,
) -> Dict[str, Any]:
    """Re-read every linked deal from HubSpot and write back the changed fields.

    Args:
        db: SQLAlchemy session.
        commit: persist changes (False = rollback, i.e. dry-run).
        only_missing: only rows with no financial data yet (backfill mode).
        with_edof: also refresh the EDOF session dates (and the participant-level
            EDOF sessions that drive the UI).
        limit: only process the first N linked rows (0 = all).
        max_hubspot_calls: stop after this many batch calls (None = unlimited),
            so a sync phase stays inside its HubSpot budget.
        update_counter: additively bump the live sync counter file.
        log: per-action logger (e.g. print for the CLI).

    Returns a stats dict (see _new_stats).
    """
    stats = _new_stats()

    query = (
        db.query(ParticipantHubspotData)
        .filter(ParticipantHubspotData.c_id_transaction_hubspot.isnot(None))
        .order_by(ParticipantHubspotData.id)
    )
    if only_missing:
        query = query.filter(ParticipantHubspotData.deal_amount.is_(None))
    rows = query.all()
    if limit:
        rows = rows[:limit]
    stats["rows_scanned"] = len(rows)

    deal_ids: List[str] = sorted({str(r.c_id_transaction_hubspot) for r in rows})
    if not deal_ids:
        return stats

    # Bound the work to the call budget, keeping whole batches.
    if max_hubspot_calls is not None and len(deal_ids) > max_hubspot_calls * BATCH_SIZE:
        deal_ids = deal_ids[: max_hubspot_calls * BATCH_SIZE]
        stats["budget_stopped"] = True

    stats["hubspot_calls"] = (len(deal_ids) + BATCH_SIZE - 1) // BATCH_SIZE
    log(f"Refreshing {len(rows)} linked row(s) from {len(deal_ids)} deal(s) "
        f"({stats['hubspot_calls']} HubSpot batch call(s))")

    deals = await hubspot_client.get_deals_batch(deal_ids)
    log(f"Fetched {len(deals)}/{len(deal_ids)} deal(s) from HubSpot")

    wanted = set(deal_ids)
    participants: Dict[int, Participant] = {}
    if with_edof:
        pids = {r.participant_id for r in rows}
        participants = {
            p.id: p for p in db.query(Participant).filter(Participant.id.in_(pids)).all()
        } if pids else {}

    now = datetime.now(timezone.utc)
    for row in rows:
        deal_id = str(row.c_id_transaction_hubspot)
        if deal_id not in wanted:
            continue  # trimmed by the budget guard
        deal = deals.get(deal_id)
        if not deal:
            stats["deal_not_found"] += 1
            log(f"  ! deal {deal_id} not found (participant {row.participant_id}, "
                f"ADF {row.id_action_formation})")
            continue

        changes = {f: deal.get(f) for f in DEAL_FINANCE_FIELDS}
        if with_edof:
            changes.update({f: deal.get(f) for f in EDOF_FIELDS})

        diff = {k: v for k, v in changes.items() if getattr(row, k) != v}
        if not diff:
            stats["unchanged"] += 1
            continue

        for field, value in diff.items():
            setattr(row, field, value)
        if "deal_facturation" in diff:
            row.deal_facturation_synced_at = now

        # The per-link EDOF columns are a copy; the participant-level list is the
        # one the UI reads, so keep it in step.
        if with_edof and any(f in diff for f in EDOF_FIELDS):
            participant = participants.get(row.participant_id)
            if participant is not None:
                _merge_edof_session(
                    participant, deal_id, deal.get("edof_date_debut"), deal.get("edof_date_fin")
                )
                stats["edof_sessions_updated"] += 1

        stats["updated"] += 1
        log(f"  + participant {row.participant_id} ADF {row.id_action_formation} "
            f"(deal {deal_id}): " + ", ".join(f"{k}={v}" for k, v in diff.items()))

    if commit:
        db.commit()
        if stats["updated"]:
            try:
                from app.services.cache_service import cache_service
                cache_service.invalidate_participant_cache()
            except Exception as e:
                log(f"  (cache invalidation skipped: {e})")
    else:
        db.rollback()

    if update_counter:
        bump_hubspot_counter(stats["hubspot_calls"])

    return stats
