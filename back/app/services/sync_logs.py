"""
Per-sync log archive helpers.

Each sync run gets its own append-only file at LOGS_DIR/sync_runs/sync_<id>.log,
keyed by SyncMetadata.id. These files are the artifact powering the
"Download log" admin button and are pruned by a periodic cleanup.
"""
import logging
import os
from typing import Optional

from sqlalchemy.orm import Session

from app.models.models import SyncMetadata

LOGS_DIR = os.environ.get("APP_LOGS_DIR", "logs")
SYNC_RUNS_SUBDIR = "sync_runs"


def sync_runs_dir() -> str:
    """Absolute path to the directory holding per-sync archived logs."""
    return os.path.join(LOGS_DIR, SYNC_RUNS_SUBDIR)


def relative_log_path(sync_metadata_id: int) -> str:
    """Path stored in SyncMetadata.log_path — relative to LOGS_DIR for portability."""
    return os.path.join(SYNC_RUNS_SUBDIR, f"sync_{sync_metadata_id}.log")


def absolute_log_path(sync_metadata_id: int) -> str:
    return os.path.join(LOGS_DIR, relative_log_path(sync_metadata_id))


def attach_per_sync_handler(db: Session, sync_metadata_id: int) -> Optional[logging.Handler]:
    """
    Attach a FileHandler that captures all log records for the duration of this sync,
    and persist its relative path on the matching SyncMetadata row. Returns the handler
    so the caller can detach/close it once the sync ends.
    Failures are non-fatal — the sync proceeds without per-run log archiving.
    """
    try:
        os.makedirs(sync_runs_dir(), exist_ok=True)
        rel_path = relative_log_path(sync_metadata_id)
        abs_path = absolute_log_path(sync_metadata_id)

        handler = logging.FileHandler(abs_path, encoding="utf-8")
        handler.setLevel(logging.INFO)
        handler.setFormatter(logging.Formatter(
            "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
        ))
        logging.getLogger().addHandler(handler)

        record = db.query(SyncMetadata).get(sync_metadata_id)
        if record:
            record.log_path = rel_path
            db.commit()

        return handler
    except Exception as e:
        logging.getLogger(__name__).warning(f"Failed to attach per-sync log handler: {e}")
        return None


def detach_per_sync_handler(handler: Optional[logging.Handler]) -> None:
    """Detach + close the per-sync FileHandler returned by attach_per_sync_handler."""
    if handler is None:
        return
    try:
        logging.getLogger().removeHandler(handler)
        handler.close()
    except Exception:
        pass


def cleanup_old_sync_logs(retention_days: int = 90) -> int:
    """
    Delete per-sync log files older than `retention_days`. Returns the number of
    files removed. Safe to call on a stale or missing directory.
    """
    import time

    target_dir = sync_runs_dir()
    if not os.path.isdir(target_dir):
        return 0

    cutoff = time.time() - retention_days * 86400
    removed = 0
    for name in os.listdir(target_dir):
        full = os.path.join(target_dir, name)
        try:
            if os.path.isfile(full) and os.path.getmtime(full) < cutoff:
                os.remove(full)
                removed += 1
        except OSError:
            continue
    return removed
