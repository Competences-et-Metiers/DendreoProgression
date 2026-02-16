from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func, extract
from app.models.database import get_db
from app.models.models import User, SyncMetadata, AdminSyncConfig
from app.auth.dependencies import require_admin
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
from datetime import datetime, timezone, timedelta
import subprocess
import logging
import json
import os

logger = logging.getLogger(__name__)
router = APIRouter()

SYNC_LOG_PATH = "/tmp/sync_live.log"


# Schemas
class SyncConfigUpdate(BaseModel):
    cron_enabled: Optional[bool] = None
    cooldown_hours: Optional[float] = None
    schedule_days: Optional[str] = None
    schedule_time: Optional[str] = None
    dendreo_api_limit: Optional[int] = None
    hubspot_api_limit: Optional[int] = None


class SyncConfigResponse(BaseModel):
    id: int
    cron_enabled: bool
    cooldown_hours: float
    schedule_days: str
    schedule_time: str
    dendreo_api_limit: Optional[int] = None
    hubspot_api_limit: Optional[int] = None
    last_updated_at: datetime
    updated_by_user_id: Optional[int] = None

    class Config:
        from_attributes = True


class APIUsageStats(BaseModel):
    last_sync: Dict[str, Any]
    today: Dict[str, Any]
    this_week: Dict[str, Any]
    this_month: Dict[str, Any]


class SyncStatusResponse(BaseModel):
    is_running: bool
    last_sync: Optional[Dict[str, Any]] = None
    config: Optional[SyncConfigResponse] = None
    skipped_adf_count: int = 0


class SyncHistoryItem(BaseModel):
    id: int
    sync_type: str
    last_sync_at: datetime
    status: str
    api_calls_count: int
    duration_seconds: Optional[float]
    error_message: Optional[str]

    class Config:
        from_attributes = True


class SyncCommandResponse(BaseModel):
    status: str
    message: str
    output: Optional[str] = None


# Helper functions
def get_or_create_sync_config(db: Session) -> AdminSyncConfig:
    """Get or create the singleton sync config"""
    config = db.query(AdminSyncConfig).first()
    if not config:
        config = AdminSyncConfig(
            cron_enabled=True,
            cooldown_hours=12.0,
            schedule_days='0,1,2,3,4',
            schedule_time='08:00'
        )
        db.add(config)
        db.commit()
        db.refresh(config)
    return config


def start_sync_process(command: List[str]) -> Dict[str, Any]:
    """Start sync subprocess in background, redirect output to log file."""
    try:
        with open(SYNC_LOG_PATH, "w") as f:
            f.write("")

        log_file = open(SYNC_LOG_PATH, "a")
        process = subprocess.Popen(
            command,
            stdout=log_file,
            stderr=subprocess.STDOUT,
            cwd="/app"
        )
        return {
            "status": "started",
            "message": f"Sync started (PID: {process.pid})",
        }
    except Exception as e:
        return {
            "status": "error",
            "message": f"Failed to start sync: {str(e)}",
        }


# API Endpoints
@router.get("/sync/api-usage", response_model=APIUsageStats)
async def get_api_usage(
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """
    Get API call usage statistics:
    - Last sync: api_calls_count, duration, timestamp
    - Today: sum of api_calls_count for syncs where date = today
    - This week: sum for last 7 days
    - This month: sum for current month
    """
    now = datetime.now(timezone.utc)
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    week_start = now - timedelta(days=7)
    month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)

    # Last sync
    last_sync = db.query(SyncMetadata).filter(
        SyncMetadata.sync_type == 'sync_all'
    ).order_by(SyncMetadata.last_sync_at.desc()).first()

    last_sync_data = {
        "api_calls": last_sync.api_calls_count if last_sync else 0,
        "duration_seconds": last_sync.duration_seconds if last_sync else None,
        "timestamp": last_sync.last_sync_at.isoformat() if last_sync else None,
        "status": last_sync.status if last_sync else None
    }

    # Today's total
    today_total = db.query(func.sum(SyncMetadata.api_calls_count)).filter(
        SyncMetadata.sync_type == 'sync_all',
        SyncMetadata.last_sync_at >= today_start
    ).scalar() or 0

    today_syncs = db.query(func.count(SyncMetadata.id)).filter(
        SyncMetadata.sync_type == 'sync_all',
        SyncMetadata.last_sync_at >= today_start
    ).scalar() or 0

    # This week's total
    week_total = db.query(func.sum(SyncMetadata.api_calls_count)).filter(
        SyncMetadata.sync_type == 'sync_all',
        SyncMetadata.last_sync_at >= week_start
    ).scalar() or 0

    week_syncs = db.query(func.count(SyncMetadata.id)).filter(
        SyncMetadata.sync_type == 'sync_all',
        SyncMetadata.last_sync_at >= week_start
    ).scalar() or 0

    # This month's total
    month_total = db.query(func.sum(SyncMetadata.api_calls_count)).filter(
        SyncMetadata.sync_type == 'sync_all',
        SyncMetadata.last_sync_at >= month_start
    ).scalar() or 0

    month_syncs = db.query(func.count(SyncMetadata.id)).filter(
        SyncMetadata.sync_type == 'sync_all',
        SyncMetadata.last_sync_at >= month_start
    ).scalar() or 0

    return APIUsageStats(
        last_sync=last_sync_data,
        today={"api_calls": today_total, "sync_count": today_syncs},
        this_week={"api_calls": week_total, "sync_count": week_syncs},
        this_month={"api_calls": month_total, "sync_count": month_syncs}
    )


@router.post("/sync/dry-run", response_model=SyncCommandResponse)
async def trigger_dry_run(
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """
    Execute sync_dendreo.py --dry-run (non-blocking).
    Returns immediately after starting the process.
    """
    in_progress = db.query(SyncMetadata).filter(
        SyncMetadata.status == 'in_progress'
    ).first()
    if in_progress:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="A sync is already running. Wait for it to finish."
        )

    logger.info(f"Admin user '{current_user.username}' triggered dry-run sync")

    result = start_sync_process(
        ["python3", "scripts/sync_dendreo.py", "--dry-run", "--log-level", "INFO"]
    )

    return SyncCommandResponse(**result)


@router.post("/sync/force", response_model=SyncCommandResponse)
async def force_sync(
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """
    Execute sync_dendreo.py --force (non-blocking).
    Returns immediately after starting the process.
    """
    in_progress = db.query(SyncMetadata).filter(
        SyncMetadata.status == 'in_progress'
    ).first()
    if in_progress:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="A sync is already running. Wait for it to finish."
        )

    logger.info(f"Admin user '{current_user.username}' triggered force sync")

    result = start_sync_process(
        ["python3", "scripts/sync_dendreo.py", "--force", "--log-level", "INFO"]
    )

    return SyncCommandResponse(**result)


@router.post("/sync/adf/{id_action_formation}", response_model=SyncCommandResponse)
async def sync_specific_adf(
    id_action_formation: str,
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """
    Execute sync_dendreo.py --adf {id_action_formation} (non-blocking).
    Returns immediately after starting the process.
    """
    in_progress = db.query(SyncMetadata).filter(
        SyncMetadata.status == 'in_progress'
    ).first()
    if in_progress:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="A sync is already running. Wait for it to finish."
        )

    logger.info(f"Admin user '{current_user.username}' triggered sync for ADF {id_action_formation}")

    result = start_sync_process(
        ["python3", "scripts/sync_dendreo.py", "--adf", id_action_formation, "--log-level", "INFO"]
    )

    return SyncCommandResponse(**result)


@router.get("/sync/config", response_model=SyncConfigResponse)
async def get_sync_config(
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """
    Get admin_sync_config singleton row
    Returns cron_enabled and cooldown_hours
    """
    config = get_or_create_sync_config(db)
    return config


@router.put("/sync/config", response_model=SyncConfigResponse)
async def update_sync_config(
    config_update: SyncConfigUpdate,
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """
    Update sync configuration (schedule, cooldown, enable/disable).
    Writes to admin_sync_config table.
    """
    config = get_or_create_sync_config(db)

    if config_update.cron_enabled is not None:
        config.cron_enabled = config_update.cron_enabled
        logger.info(f"Admin user '{current_user.username}' set cron_enabled to {config_update.cron_enabled}")

    if config_update.cooldown_hours is not None:
        if config_update.cooldown_hours < 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cooldown hours must be non-negative"
            )
        config.cooldown_hours = config_update.cooldown_hours
        logger.info(f"Admin user '{current_user.username}' set cooldown_hours to {config_update.cooldown_hours}")

    if config_update.schedule_days is not None:
        # Validate: comma-separated digits 0-6
        valid_days = set('0123456')
        parts = [d.strip() for d in config_update.schedule_days.split(',') if d.strip()]
        if not parts or not all(d in valid_days for d in parts):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="schedule_days must be comma-separated digits 0-6 (Mon=0, Sun=6)"
            )
        config.schedule_days = ','.join(sorted(set(parts), key=int))
        logger.info(f"Admin user '{current_user.username}' set schedule_days to {config.schedule_days}")

    if config_update.schedule_time is not None:
        # Validate HH:MM format
        import re
        if not re.match(r'^([01]\d|2[0-3]):[0-5]\d$', config_update.schedule_time):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="schedule_time must be HH:MM (00:00-23:59)"
            )
        config.schedule_time = config_update.schedule_time
        logger.info(f"Admin user '{current_user.username}' set schedule_time to {config_update.schedule_time}")

    if config_update.dendreo_api_limit is not None:
        # 0 or negative means unlimited (store as NULL)
        limit_val = config_update.dendreo_api_limit if config_update.dendreo_api_limit > 0 else None
        config.dendreo_api_limit = limit_val
        logger.info(f"Admin user '{current_user.username}' set dendreo_api_limit to {limit_val or 'unlimited'}")

    if config_update.hubspot_api_limit is not None:
        limit_val = config_update.hubspot_api_limit if config_update.hubspot_api_limit > 0 else None
        config.hubspot_api_limit = limit_val
        logger.info(f"Admin user '{current_user.username}' set hubspot_api_limit to {limit_val or 'unlimited'}")

    config.updated_by_user_id = current_user.id
    config.last_updated_at = datetime.now(timezone.utc)

    db.commit()
    db.refresh(config)

    return config


@router.get("/sync/status", response_model=SyncStatusResponse)
async def get_sync_status(
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """
    Check if a sync is currently running (status='in_progress')
    Return last sync info + current config
    """
    # Check for in-progress sync
    in_progress = db.query(SyncMetadata).filter(
        SyncMetadata.status == 'in_progress'
    ).first()

    # Get last sync
    last_sync = db.query(SyncMetadata).filter(
        SyncMetadata.sync_type == 'sync_all'
    ).order_by(SyncMetadata.last_sync_at.desc()).first()

    last_sync_data = None
    skipped_adf_count = 0
    if last_sync:
        last_sync_data = {
            "id": last_sync.id,
            "sync_type": last_sync.sync_type,
            "last_sync_at": last_sync.last_sync_at.isoformat(),
            "status": last_sync.status,
            "api_calls_count": last_sync.api_calls_count,
            "duration_seconds": last_sync.duration_seconds,
            "error_message": last_sync.error_message
        }
        # Check if last sync has skipped ADFs (for resume button)
        if last_sync.stats and last_sync.status == 'success':
            import ast
            try:
                stats_dict = ast.literal_eval(last_sync.stats) if isinstance(last_sync.stats, str) else last_sync.stats
                skipped_ids = stats_dict.get('skipped_adf_ids', [])
                skipped_adf_count = len(skipped_ids)
            except (ValueError, SyntaxError):
                pass

    # Get config
    config = get_or_create_sync_config(db)

    return SyncStatusResponse(
        is_running=in_progress is not None,
        last_sync=last_sync_data,
        config=config,
        skipped_adf_count=skipped_adf_count
    )


@router.get("/sync/history", response_model=List[SyncHistoryItem])
async def get_sync_history(
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db),
    limit: int = 10
):
    """
    Get recent sync history (last N syncs)
    """
    syncs = db.query(SyncMetadata).filter(
        SyncMetadata.sync_type == 'sync_all'
    ).order_by(SyncMetadata.last_sync_at.desc()).limit(limit).all()

    return syncs


@router.post("/sync/resume", response_model=SyncCommandResponse)
async def resume_sync(
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """
    Resume sync from where the last one stopped due to API limit.
    Reads skipped ADF IDs from last sync's stats and syncs only those.
    """
    in_progress = db.query(SyncMetadata).filter(
        SyncMetadata.status == 'in_progress'
    ).first()
    if in_progress:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="A sync is already running. Wait for it to finish."
        )

    # Find the last completed sync with skipped ADF IDs
    last_sync = db.query(SyncMetadata).filter(
        SyncMetadata.sync_type == 'sync_all',
        SyncMetadata.status == 'success'
    ).order_by(SyncMetadata.last_sync_at.desc()).first()

    if not last_sync or not last_sync.stats:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No previous sync with skipped ADFs found."
        )

    # Parse the stats to find skipped ADF IDs
    import ast
    try:
        stats_dict = ast.literal_eval(last_sync.stats) if isinstance(last_sync.stats, str) else last_sync.stats
    except (ValueError, SyntaxError):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Could not parse last sync stats."
        )

    skipped_ids = stats_dict.get('skipped_adf_ids', [])
    if not skipped_ids:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No skipped ADFs to resume. The last sync completed fully."
        )

    logger.info(f"Admin user '{current_user.username}' triggered resume sync for {len(skipped_ids)} ADFs")

    adf_ids_str = ','.join(str(aid) for aid in skipped_ids)
    result = start_sync_process(
        ["python3", "scripts/sync_dendreo.py", "--force", "--resume-adfs", adf_ids_str, "--log-level", "INFO"]
    )

    return SyncCommandResponse(**result)


@router.get("/sync/live-log")
async def get_live_log(
    offset: int = 0,
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """
    Read sync log file from byte offset. Returns new content + new offset.
    Frontend polls this every 2s while sync is running.
    """
    content = ""
    new_offset = offset

    if os.path.exists(SYNC_LOG_PATH):
        file_size = os.path.getsize(SYNC_LOG_PATH)
        if file_size > offset:
            with open(SYNC_LOG_PATH, "r") as f:
                f.seek(offset)
                content = f.read()
                new_offset = f.tell()

    is_running = db.query(SyncMetadata).filter(
        SyncMetadata.status == 'in_progress'
    ).first() is not None

    return {
        "content": content,
        "offset": new_offset,
        "is_running": is_running
    }
