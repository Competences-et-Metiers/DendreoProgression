"""
Shared auto-link logic for HubSpot deals + EDOF session dates.

Used by both the periodic sync (as a phase) and the one-time backfill CLI
(`scripts/bulk_link_edof_deals.py`). The deal is tied to the PARTICIPANT: when a
contact has exactly one *eligible* deal, it is linked to every active course
(ADF) of that participant.

Eligibility (see is_eligible_deal): the deal must be in the EDOF pipeline and
NOT in a closed/finished stage. This drops obsolete/lost deals so the remaining
active one is usually unambiguous.

A participant is auto-linked when:
  * it has at least one active ADF enrollment (Dendreo etape 5/6/7) not yet linked, AND
  * the contact has exactly ONE eligible deal.

Everything else (0 deals, 0 eligible, 2+ eligible deals) is skipped and counted
so staff can link it manually. Links are written with is_manual_link=True so the
sync's deal-data guard preserves them (this flag is the system's only "don't
overwrite from Dendreo" signal — auto-links are not literally manual but must be
preserved the same way). EDOF dates are captured at link time only.

No writes to HubSpot happen here — only the local participant_hubspot_data table
is populated.
"""

import asyncio
import json
import logging
import os
import tempfile
from typing import Any, Callable, Dict, Optional, Set

from sqlalchemy.orm import Session

from app.models.models import Participant, ParticipantCourse, Course, ParticipantHubspotData
from app.services.hubspot_client import hubspot_client

logger = logging.getLogger(__name__)

ACTIVE_STATUSES = ("5", "6", "7")
DEAL_URL_TMPL = "https://app-eu1.hubspot.com/contacts/25868618/record/0-3/{deal_id}"
_COUNTERS_PATH = "/app/logs/sync_api_counters.json"

# Only deals in this pipeline are eligible for auto-linking...
EDOF_PIPELINE_ID = "1033999593"
# ...and not in these stages (closed/finished deals must be ignored).
EXCLUDED_DEAL_STAGES = {
    "1441989831",  # Fermé perdu
    "1441989830",  # Formation terminée
}


def is_eligible_deal(deal: dict) -> bool:
    """A deal is auto-linkable only if it's in the EDOF pipeline and not in an
    excluded (closed/finished) stage. Filters out obsolete/lost deals so a
    contact's remaining active deal can be picked unambiguously."""
    return (
        deal.get("pipeline") == EDOF_PIPELINE_ID
        and deal.get("dealstage") not in EXCLUDED_DEAL_STAGES
    )


def build_active_adf_map(db: Session) -> Dict[int, Set[str]]:
    """participant_id -> set of active ADF ids (Dendreo etape 5/6/7)."""
    rows = (
        db.query(ParticipantCourse.participant_id, Course.id_action_formation)
        .join(Course, Course.id == ParticipantCourse.course_id)
        .filter(Course.status.in_(ACTIVE_STATUSES))
        .distinct()
        .all()
    )
    out: Dict[int, Set[str]] = {}
    for pid, adf in rows:
        if adf:
            out.setdefault(pid, set()).add(adf)
    return out


def _bump_hubspot_counter(n: int) -> None:
    """Best-effort additive update of the live sync API counter file."""
    try:
        current = {"dendreo": 0, "hubspot": 0}
        if os.path.exists(_COUNTERS_PATH):
            with open(_COUNTERS_PATH, "r") as f:
                current = json.load(f)
        current["hubspot"] = current.get("hubspot", 0) + n
        fd, tmp = tempfile.mkstemp(dir="/tmp", prefix="sync_api_")
        with os.fdopen(fd, "w") as f:
            json.dump(current, f)
        os.replace(tmp, _COUNTERS_PATH)
    except Exception:
        pass


def _new_stats() -> Dict[str, Any]:
    return {
        "candidates": 0,
        "edof_set": 0,          # participants whose participant-level EDOF sessions were set
        "linked": 0,            # participants newly linked
        "linked_rows": 0,       # course rows written (deal replicated per active course)
        "linked_with_edof": 0,
        "linked_without_edof": 0,
        "no_deal": 0,
        "no_eligible_deal": 0,
        "multi_deal": 0,
        "no_active_adf": 0,
        "already_linked": 0,
        "no_email": 0,
        "hubspot_calls": 0,
        "budget_stopped": False,
    }


async def auto_link_deals(
    db: Session,
    *,
    commit: bool = True,
    limit: int = 0,
    sleep_s: float = 0.2,
    max_hubspot_calls: Optional[int] = None,
    update_counter: bool = False,
    log: Callable[[str], None] = logger.info,
) -> Dict[str, Any]:
    """Link unambiguous participants to their single HubSpot deal + capture EDOF dates.

    Args:
        db: SQLAlchemy session.
        commit: persist changes (False = rollback, i.e. dry-run).
        limit: only scan the first N participants (0 = all).
        sleep_s: delay between candidate HubSpot fetches (rate-limit courtesy).
        max_hubspot_calls: stop once this many HubSpot calls have been made
            (None = unlimited). Bounds cost on the first run before backfill.
        update_counter: additively bump the live sync counter file.
        log: per-action logger (e.g. print for the CLI).

    Returns a stats dict (see _new_stats). HubSpot cost is incurred only for
    *candidates* (participants with at least one unlinked active course); one
    fetch per candidate, then the eligible deal is replicated across all their
    unlinked courses at no extra HubSpot cost.
    """
    stats = _new_stats()

    active_adf_map = build_active_adf_map(db)

    # Pairs already linked to a deal -> never overwrite.
    linked_pairs: Set[tuple] = set(
        db.query(
            ParticipantHubspotData.participant_id,
            ParticipantHubspotData.id_action_formation,
        )
        .filter(ParticipantHubspotData.c_id_transaction_hubspot.isnot(None))
        .all()
    )

    participants = db.query(Participant).order_by(Participant.id).all()
    if limit:
        participants = participants[:limit]

    for participant in participants:
        active_adfs = active_adf_map.get(participant.id, set())

        if not active_adfs:
            stats["no_active_adf"] += 1
            continue
        unlinked_adfs = [a for a in active_adfs if (participant.id, a) not in linked_pairs]
        # A participant is worth processing if it has a course to link OR its
        # participant-level EDOF sessions haven't been computed yet.
        edof_missing = participant.edof_sessions is None
        if not unlinked_adfs and not edof_missing:
            stats["already_linked"] += 1
            continue

        email = (participant.email or "").strip()
        if not email:
            stats["no_email"] += 1
            continue

        # Budget guard before spending HubSpot calls on this candidate.
        if max_hubspot_calls is not None and stats["hubspot_calls"] >= max_hubspot_calls:
            stats["budget_stopped"] = True
            break

        stats["candidates"] += 1
        try:
            deals = await hubspot_client.get_deals_for_contact(email)
            # 1 contact GET, plus 1 batch read only when the contact has deals.
            stats["hubspot_calls"] += 2 if deals else 1
        except Exception as e:
            log(f"  ! {email}: HubSpot fetch failed: {e}")
            deals = []
            stats["hubspot_calls"] += 1
        finally:
            if sleep_s:
                await asyncio.sleep(sleep_s)

        # Keep only deals in the EDOF pipeline and not in a closed/finished stage.
        # This drops obsolete/lost deals.
        eligible = [d for d in deals if is_eligible_deal(d)]

        # 1) Participant-level EDOF sessions from ALL eligible deals (with any date).
        #    Tied to the participant, independent of how many courses/deals they have.
        sessions = [
            {
                "deal_id": d.get("id"),
                "date_debut": d.get("edof_date_debut"),
                "date_fin": d.get("edof_date_fin"),
            }
            for d in eligible
            if d.get("edof_date_debut") or d.get("edof_date_fin")
        ]
        sessions.sort(key=lambda s: s.get("date_debut") or s.get("date_fin") or "")
        participant.edof_sessions = sessions
        if sessions:
            stats["edof_set"] += 1

        if not deals:
            stats["no_deal"] += 1
            continue

        # 2) Per-ADF deal link — only the unambiguous single-eligible-deal case.
        #    Multi-deal participants keep their EDOF (above) but the per-course link
        #    is left for staff (the deal->course mapping can't be auto-resolved).
        if not unlinked_adfs:
            continue
        if len(eligible) == 0:
            stats["no_eligible_deal"] += 1
            continue
        if len(eligible) > 1:
            stats["multi_deal"] += 1
            log(f"  ~ multi_deal: {email} has {len(eligible)} eligible deals -> EDOF set, link left manual")
            continue

        deal = eligible[0]
        deal_id = deal.get("id")
        edof_debut = deal.get("edof_date_debut")
        edof_fin = deal.get("edof_date_fin")
        deal_url = DEAL_URL_TMPL.format(deal_id=deal_id)

        # Replicate the deal across all of the participant's unlinked active courses.
        for adf in unlinked_adfs:
            existing = (
                db.query(ParticipantHubspotData)
                .filter(
                    ParticipantHubspotData.participant_id == participant.id,
                    ParticipantHubspotData.id_action_formation == adf,
                )
                .first()
            )
            if existing:
                existing.c_id_transaction_hubspot = deal_id
                existing.c_url_transaction_hubspot = deal_url
                existing.is_manual_link = True
                existing.edof_date_debut = edof_debut
                existing.edof_date_fin = edof_fin
            else:
                db.add(
                    ParticipantHubspotData(
                        participant_id=participant.id,
                        id_action_formation=adf,
                        c_id_transaction_hubspot=deal_id,
                        c_url_transaction_hubspot=deal_url,
                        is_manual_link=True,
                        edof_date_debut=edof_debut,
                        edof_date_fin=edof_fin,
                    )
                )
            linked_pairs.add((participant.id, adf))

        stats["linked"] += 1
        stats["linked_rows"] += len(unlinked_adfs)
        if edof_debut or edof_fin:
            stats["linked_with_edof"] += 1
        else:
            stats["linked_without_edof"] += 1
        log(f"  + link: {email} -> deal {deal_id} on {len(unlinked_adfs)} course(s) (EDOF {edof_debut or '?'} -> {edof_fin or '?'})")

    if commit:
        db.commit()
    else:
        db.rollback()

    if update_counter and stats["hubspot_calls"]:
        _bump_hubspot_counter(stats["hubspot_calls"])

    return stats
