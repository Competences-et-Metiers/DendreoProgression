#!/usr/bin/env python3
"""
Refresh the HubSpot deal fields stored on existing links.

Deal fields (financials + EDOF session dates) are captured at link time only, so
rows linked before this feature shipped have them empty, and rows linked long ago
can be stale. This script re-reads every linked deal from HubSpot and updates:

    deal_amount              (HubSpot: amount)
    deal_type_financement    (HubSpot: type_de_financement)
    deal_montant_pec         (HubSpot: montant_pec)
    deal_montant_rac         (HubSpot: montant_rac)
    edof_date_debut/fin      (only with --with-edof; off by default)

Cheap: deals are read in batches of 100 (one HubSpot call per batch), and each
distinct deal is fetched once even when linked to several courses. Performs NO
writes to HubSpot or Dendreo — only the local participant_hubspot_data table.

Run inside the backend container, from the `back/` directory:

    # Dry run (default) — reports what would change, writes nothing:
    python scripts/refresh_deal_fields.py

    # Apply:
    python scripts/refresh_deal_fields.py --commit

Options:
    --commit        Persist changes (otherwise dry-run / rollback).
    --only-missing  Only touch rows with no financial data yet (backfill mode).
    --with-edof     Also refresh edof_date_debut/edof_date_fin from the deal.
    --limit N       Only process the first N linked rows (testing).
"""

import argparse
import asyncio
import os
import sys

# Make the `app` package importable when run from anywhere.
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.models.database import SessionLocal  # noqa: E402
from app.models.models import ParticipantHubspotData  # noqa: E402
from app.services.hubspot_client import DEAL_FINANCE_FIELDS, hubspot_client  # noqa: E402


async def run(commit: bool, only_missing: bool, with_edof: bool, limit: int):
    db = SessionLocal()
    try:
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

        deal_ids = sorted({str(r.c_id_transaction_hubspot) for r in rows})
        print(f"{'APPLY' if commit else 'DRY-RUN'}: {len(rows)} linked row(s), "
              f"{len(deal_ids)} distinct deal(s) to read from HubSpot "
              f"({(len(deal_ids) + 99) // 100} batch call(s))\n")

        if not deal_ids:
            print("Nothing to do.")
            return

        deals = await hubspot_client.get_deals_batch(deal_ids)
        print(f"Fetched {len(deals)}/{len(deal_ids)} deal(s) from HubSpot\n")

        updated = unchanged = missing_deal = 0
        for row in rows:
            deal = deals.get(str(row.c_id_transaction_hubspot))
            if not deal:
                missing_deal += 1
                print(f"  ! deal {row.c_id_transaction_hubspot} not found "
                      f"(participant {row.participant_id}, ADF {row.id_action_formation})")
                continue

            changes = {f: deal.get(f) for f in DEAL_FINANCE_FIELDS}
            if with_edof:
                changes["edof_date_debut"] = deal.get("edof_date_debut")
                changes["edof_date_fin"] = deal.get("edof_date_fin")

            diff = {k: v for k, v in changes.items() if getattr(row, k) != v}
            if not diff:
                unchanged += 1
                continue

            for field, value in diff.items():
                setattr(row, field, value)
            updated += 1
            print(f"  + participant {row.participant_id} ADF {row.id_action_formation} "
                  f"(deal {row.c_id_transaction_hubspot}): "
                  + ", ".join(f"{k}={v}" for k, v in diff.items()))

        if commit:
            db.commit()
            try:
                from app.services.cache_service import cache_service
                cache_service.invalidate_participant_cache()
            except Exception as e:
                print(f"  (cache invalidation skipped: {e})")
            print("\nCommitted changes to the database.")
        else:
            db.rollback()
            print("\nDRY-RUN: no changes written. Re-run with --commit to apply.")

        print("\n=== Summary ===")
        print(f"  rows_scanned       {len(rows)}")
        print(f"  updated            {updated}")
        print(f"  unchanged          {unchanged}")
        print(f"  deal_not_found     {missing_deal}")
        print(f"  hubspot_calls      {(len(deal_ids) + 99) // 100}")
    finally:
        db.close()


def main():
    parser = argparse.ArgumentParser(description="Refresh HubSpot deal fields on existing links.")
    parser.add_argument("--commit", action="store_true", help="Persist changes (default: dry-run).")
    parser.add_argument("--only-missing", action="store_true",
                        help="Only rows with no financial data yet (backfill mode).")
    parser.add_argument("--with-edof", action="store_true",
                        help="Also refresh the EDOF session dates from the deal.")
    parser.add_argument("--limit", type=int, default=0, help="Process only the first N linked rows.")
    args = parser.parse_args()

    asyncio.run(run(commit=args.commit, only_missing=args.only_missing,
                    with_edof=args.with_edof, limit=args.limit))


if __name__ == "__main__":
    main()
