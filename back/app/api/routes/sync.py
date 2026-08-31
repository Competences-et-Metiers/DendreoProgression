from fastapi import APIRouter, Depends, HTTPException
from app.models.database import get_db
from sqlalchemy.orm import Session
from typing import Dict, Any, Optional
import logging
import json
import os
from datetime import datetime, timezone, timedelta
from zoneinfo import ZoneInfo
from app.models.models import SyncMetadata, AdminSyncConfig

logger = logging.getLogger(__name__)
router = APIRouter()


def _compute_next_sync_at(config: Optional[AdminSyncConfig], last_success: Optional[datetime]) -> Optional[datetime]:
    """Compute the next time the cron-driven sync_all will actually fire, taking
    schedule_days, schedule_time and cooldown_hours into account.
    Returns a UTC-aware datetime, or None if cron is disabled or unconfigured."""
    if not config or not config.cron_enabled:
        return None
    try:
        allowed_days = {int(d.strip()) for d in (config.schedule_days or '').split(',') if d.strip()}
        hour = int((config.schedule_time or '08:00').split(':')[0])
    except (ValueError, AttributeError):
        return None
    if not allowed_days:
        return None

    tz = ZoneInfo(os.environ.get('TZ', 'Europe/Paris'))
    now_local = datetime.now(tz)
    candidate = now_local.replace(hour=hour, minute=0, second=0, microsecond=0)
    if candidate <= now_local:
        candidate += timedelta(days=1)

    cooldown = max(float(config.cooldown_hours or 0), 0)
    for _ in range(14):
        if candidate.weekday() in allowed_days:
            candidate_utc = candidate.astimezone(timezone.utc)
            if last_success is None:
                return candidate_utc
            cutoff = last_success + timedelta(hours=cooldown)
            if candidate_utc >= cutoff:
                return candidate_utc
        candidate += timedelta(days=1)
    return None

# Note: Sync execution endpoints removed - use sync container/script instead
# Only read-only status endpoints remain in the API

@router.get("/last-sync")
def get_last_sync(db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Get information about the last completed full sync (sync_all only).
    Single-ADF syncs are excluded so the inactivity manager only reflects large/scheduled runs."""
    try:
        # Is a full sync currently running?
        in_progress = db.query(SyncMetadata).filter(
            SyncMetadata.sync_type == 'sync_all',
            SyncMetadata.status == 'in_progress'
        ).first() is not None

        sync_metadata = db.query(SyncMetadata).filter(
            SyncMetadata.sync_type == 'sync_all',
            SyncMetadata.status != 'in_progress'
        ).order_by(SyncMetadata.last_sync_at.desc()).first()

        # Latest successful full sync drives cooldown calculation for next-sync prediction
        last_success = db.query(SyncMetadata).filter(
            SyncMetadata.sync_type == 'sync_all',
            SyncMetadata.status == 'success'
        ).order_by(SyncMetadata.last_sync_at.desc()).first()

        config = db.query(AdminSyncConfig).first()
        next_sync = _compute_next_sync_at(
            config,
            last_success.last_sync_at if last_success and last_success.last_sync_at else None,
        )

        if not sync_metadata:
            return {
                "status": "no_sync",
                "message": "No sync operation has been performed yet",
                "last_sync_at": None,
                "sync_status": None,
                "stats": None,
                "in_progress": in_progress,
                "next_sync_at": next_sync.isoformat() if next_sync else None,
            }

        # Parse stats if available
        stats = None
        if sync_metadata.stats:
            try:
                stats = json.loads(sync_metadata.stats)
            except json.JSONDecodeError:
                stats = None

        return {
            "status": "success",
            "last_sync_at": sync_metadata.last_sync_at.isoformat() if sync_metadata.last_sync_at else None,
            "sync_status": sync_metadata.status,
            "stats": stats,
            "error_message": sync_metadata.error_message,
            "in_progress": in_progress,
            "next_sync_at": next_sync.isoformat() if next_sync else None,
        }

    except Exception as e:
        logger.error(f"Failed to get last sync info: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to get last sync info: {str(e)}")