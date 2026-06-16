#!/usr/bin/env python3
"""
One-time bulk-link backfill: link participants to their HubSpot deal and capture
the deal's EDOF session dates (date_debut_formation / date_fin_formation_edof).

This is the manual backfill counterpart to the auto-link phase that now runs
inside the periodic sync (see app/services/edof_auto_link.py). Both share the
same decision logic: a participant is auto-linked ONLY when it has exactly one
active ADF and exactly one HubSpot deal, and isn't already linked. Multi-deal /
multi-ADF cases are skipped and reported for manual linking from the UI.

Use this once after deploy to backfill the existing population in one pass
(faster than waiting for the budget-bounded sync phase to catch up over several
runs). Performs NO writes to HubSpot or Dendreo — only the local
participant_hubspot_data table.

Run inside the backend container, from the `back/` directory:

    # Dry run (default) — shows what would happen, writes nothing:
    python scripts/bulk_link_edof_deals.py

    # Apply the changes:
    python scripts/bulk_link_edof_deals.py --commit

Options:
    --commit          Persist links (otherwise dry-run / rollback).
    --limit N         Only process the first N participants (testing).
    --sleep SECONDS   Delay between candidate HubSpot fetches (default 0.3).
"""

import argparse
import asyncio
import os
import sys

# Make the `app` package importable when run from anywhere.
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.models.database import SessionLocal  # noqa: E402
from app.services.edof_auto_link import auto_link_deals  # noqa: E402


async def run(commit: bool, limit: int, sleep_s: float):
    db = SessionLocal()
    try:
        print(f"{'APPLY' if commit else 'DRY-RUN'}: scanning participants for unambiguous deal links\n")
        stats = await auto_link_deals(
            db,
            commit=commit,
            limit=limit,
            sleep_s=sleep_s,
            max_hubspot_calls=None,  # backfill the whole population in one pass
            update_counter=False,
            log=print,
        )

        if commit:
            try:
                from app.services.cache_service import cache_service
                cache_service.invalidate_participant_cache()
            except Exception as e:
                print(f"  (cache invalidation skipped: {e})")
            print("\nCommitted changes to the database.")
        else:
            print("\nDRY-RUN: no changes written. Re-run with --commit to apply.")

        print("\n=== Summary ===")
        for k, v in stats.items():
            print(f"  {k:22} {v}")
    finally:
        db.close()


def main():
    parser = argparse.ArgumentParser(description="Bulk-link participants to HubSpot deals + EDOF dates.")
    parser.add_argument("--commit", action="store_true", help="Persist changes (default: dry-run).")
    parser.add_argument("--limit", type=int, default=0, help="Process only the first N participants.")
    parser.add_argument("--sleep", type=float, default=0.3, help="Seconds to sleep between candidate fetches.")
    args = parser.parse_args()

    asyncio.run(run(commit=args.commit, limit=args.limit, sleep_s=args.sleep))


if __name__ == "__main__":
    main()
