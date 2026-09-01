#!/usr/bin/env python3
"""
Refresh the HubSpot deal fields stored on existing links (CLI).

Thin wrapper around app/services/deal_refresh.py, which the periodic sync runs
as a phase. Use this to backfill the whole population in one pass right after a
deploy, or to force a refresh without waiting for the next sync. It updates:

    deal_amount              (HubSpot: amount)
    deal_type_financement    (HubSpot: type_de_financement)
    deal_montant_pec         (HubSpot: montant_pec)
    deal_montant_rac         (HubSpot: montant_rac)
    deal_facturation         (HubSpot: facturation)
    edof_date_debut/fin      + the participant's EDOF sessions (--no-edof to skip)

Deals are read in batches of 100 (one HubSpot call per batch) and each distinct
deal is fetched once. Performs NO writes to HubSpot or Dendreo.

Run inside the backend container, from the `back/` directory:

    # Dry run (default) — reports what would change, writes nothing:
    python scripts/refresh_deal_fields.py

    # Apply:
    python scripts/refresh_deal_fields.py --commit
"""

import argparse
import asyncio
import os
import sys

# Make the `app` package importable when run from anywhere.
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.models.database import SessionLocal  # noqa: E402
from app.services.deal_refresh import refresh_deal_fields  # noqa: E402


async def run(commit: bool, only_missing: bool, with_edof: bool, limit: int):
    db = SessionLocal()
    try:
        print(f"{'APPLY' if commit else 'DRY-RUN'}: refreshing deal fields on linked rows\n")
        stats = await refresh_deal_fields(
            db,
            commit=commit,
            only_missing=only_missing,
            with_edof=with_edof,
            limit=limit,
            log=print,
        )

        if commit:
            print("\nCommitted changes to the database.")
        else:
            print("\nDRY-RUN: no changes written. Re-run with --commit to apply.")

        print("\n=== Summary ===")
        for k, v in stats.items():
            print(f"  {k:22} {v}")
    finally:
        db.close()


def main():
    parser = argparse.ArgumentParser(description="Refresh HubSpot deal fields on existing links.")
    parser.add_argument("--commit", action="store_true", help="Persist changes (default: dry-run).")
    parser.add_argument("--only-missing", action="store_true",
                        help="Only rows with no financial data yet (backfill mode).")
    parser.add_argument("--no-edof", action="store_true",
                        help="Skip the EDOF session dates (financial + billing fields only).")
    parser.add_argument("--limit", type=int, default=0, help="Process only the first N linked rows.")
    args = parser.parse_args()

    asyncio.run(run(commit=args.commit, only_missing=args.only_missing,
                    with_edof=not args.no_edof, limit=args.limit))


if __name__ == "__main__":
    main()
