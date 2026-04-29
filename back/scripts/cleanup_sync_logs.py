#!/usr/bin/env python3
"""
Delete per-sync log files older than the configured retention window.
Runs from cron in the sync container; also runs at backend startup.

Usage:
    python3 scripts/cleanup_sync_logs.py [--days 90]
"""
import argparse
import logging
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).parent.parent))

from app.services.sync_logs import cleanup_old_sync_logs


def main():
    parser = argparse.ArgumentParser(description="Prune per-sync log files past retention.")
    parser.add_argument("--days", type=int, default=90, help="Retention window in days (default: 90)")
    args = parser.parse_args()

    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s - %(levelname)s - %(message)s",
    )
    log = logging.getLogger("cleanup_sync_logs")

    removed = cleanup_old_sync_logs(retention_days=args.days)
    log.info(f"Removed {removed} sync log file(s) older than {args.days} days")


if __name__ == "__main__":
    main()
