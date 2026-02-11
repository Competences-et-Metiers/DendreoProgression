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

logger = logging.getLogger(__name__)
router = APIRouter()


# Schemas
class SyncConfigUpdate(BaseModel):
    cron_enabled: Optional[bool] = None
    cooldown_hours: Optional[float] = None
    schedule_days: Optional[str] = None
    schedule_time: Optional[str] = None


class SyncConfigResponse(BaseModel):
    id: int
    cron_enabled: bool
    cooldown_hours: float
    schedule_days: str
    schedule_time: str
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


def run_sync_command(command: List[str], timeout: int = 1800) -> Dict[str, Any]:
    """Execute a sync command and return results"""
    try:
        result = subprocess.run(
            command,
            capture_output=True,
            text=True,
            timeout=timeout,
            cwd="/app"
        )

        return {
            "status": "success" if result.returncode == 0 else "error",
            "message": "Command executed successfully" if result.returncode == 0 else f"Command failed with exit code {result.returncode}",
            "output": result.stdout + result.stderr,
            "exit_code": result.returncode
        }
    except subprocess.TimeoutExpired:
        return {
            "status": "error",
            "message": f"Command timed out after {timeout} seconds",
            "output": None,
            "exit_code": -1
        }
    except Exception as e:
        return {
            "status": "error",
            "message": f"Command execution failed: {str(e)}",
            "output": None,
            "exit_code": -1
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
    current_user: User = Depends(require_admin)
):
    """
    Execute sync_dendreo.py --dry-run
    Returns stdout/stderr from the process
    """
    logger.info(f"Admin user '{current_user.username}' triggered dry-run sync")

    result = run_sync_command(
        ["python3", "scripts/sync_dendreo.py", "--dry-run", "--log-level", "INFO"],
        timeout=1800
    )

    return SyncCommandResponse(**result)


@router.post("/sync/force", response_model=SyncCommandResponse)
async def force_sync(
    current_user: User = Depends(require_admin)
):
    """
    Execute sync_dendreo.py --force
    This runs a full sync immediately, bypassing cooldown checks
    """
    logger.info(f"Admin user '{current_user.username}' triggered force sync")

    result = run_sync_command(
        ["python3", "scripts/sync_dendreo.py", "--force", "--log-level", "INFO"],
        timeout=1800
    )

    return SyncCommandResponse(**result)


@router.post("/sync/adf/{id_action_formation}", response_model=SyncCommandResponse)
async def sync_specific_adf(
    id_action_formation: str,
    current_user: User = Depends(require_admin)
):
    """
    Execute sync_dendreo.py --adf {id_action_formation}
    Syncs only the specified ADF
    """
    logger.info(f"Admin user '{current_user.username}' triggered sync for ADF {id_action_formation}")

    result = run_sync_command(
        ["python3", "scripts/sync_dendreo.py", "--adf", id_action_formation, "--log-level", "INFO"],
        timeout=600
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

    # Get config
    config = get_or_create_sync_config(db)

    return SyncStatusResponse(
        is_running=in_progress is not None,
        last_sync=last_sync_data,
        config=config
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
