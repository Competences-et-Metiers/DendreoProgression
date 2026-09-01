from fastapi import APIRouter, Depends, HTTPException, Query as QueryParam, status
from sqlalchemy.orm import Session, subqueryload
from sqlalchemy import func, extract, desc, asc
from app.models.database import get_db
from app.models.models import User, SyncMetadata, AdminSyncConfig, ModuleCategory, Intervention, Participant, ActionHistory
from app.auth.dependencies import require_admin, require_manager_or_admin
from app.models.schemas import AdminUserResponse, AdminUserUpdate
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
from datetime import datetime, timezone, timedelta
import subprocess
import logging
import json
import os

logger = logging.getLogger(__name__)
router = APIRouter()

SYNC_LOG_PATH = "/app/logs/sync_live.log"
SYNC_API_COUNTERS_PATH = "/app/logs/sync_api_counters.json"
_sync_process = None  # Track the running subprocess
_sync_log_file = None  # Track the log file handle


# Schemas
class SyncConfigUpdate(BaseModel):
    cron_enabled: Optional[bool] = None
    cooldown_hours: Optional[float] = None
    schedule_days: Optional[str] = None
    schedule_time: Optional[str] = None
    dendreo_api_limit: Optional[int] = None
    hubspot_api_limit: Optional[int] = None
    dendreo_daily_limit: Optional[int] = None
    dendreo_weekly_limit: Optional[int] = None
    dendreo_monthly_limit: Optional[int] = None
    hubspot_daily_limit: Optional[int] = None
    hubspot_weekly_limit: Optional[int] = None
    hubspot_monthly_limit: Optional[int] = None


class SyncConfigResponse(BaseModel):
    id: int
    cron_enabled: bool
    cooldown_hours: float
    schedule_days: str
    schedule_time: str
    dendreo_api_limit: Optional[int] = None
    hubspot_api_limit: Optional[int] = None
    dendreo_daily_limit: Optional[int] = None
    dendreo_weekly_limit: Optional[int] = None
    dendreo_monthly_limit: Optional[int] = None
    hubspot_daily_limit: Optional[int] = None
    hubspot_weekly_limit: Optional[int] = None
    hubspot_monthly_limit: Optional[int] = None
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
    hubspot_api_calls_count: int = 0
    duration_seconds: Optional[float]
    error_message: Optional[str]
    stats: Optional[Dict[str, Any]] = None

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


def check_period_limits(db: Session) -> Optional[str]:
    """Check if any period API limits have been reached. Returns error message or None."""
    config = get_or_create_sync_config(db)
    now = datetime.now(timezone.utc)
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    # Calendar-week boundary so display ranges and enforcement match
    week_start = today_start - timedelta(days=today_start.weekday())
    month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    sync_types = ['sync_all', 'sync_adf']

    checks = [
        ('dendreo_daily_limit', 'api_calls_count', today_start, 'Dendreo daily'),
        ('dendreo_weekly_limit', 'api_calls_count', week_start, 'Dendreo weekly'),
        ('dendreo_monthly_limit', 'api_calls_count', month_start, 'Dendreo monthly'),
        ('hubspot_daily_limit', 'hubspot_api_calls_count', today_start, 'HubSpot daily'),
        ('hubspot_weekly_limit', 'hubspot_api_calls_count', week_start, 'HubSpot weekly'),
        ('hubspot_monthly_limit', 'hubspot_api_calls_count', month_start, 'HubSpot monthly'),
    ]

    for limit_field, count_column, period_start, label in checks:
        limit_val = getattr(config, limit_field, None)
        if not limit_val or limit_val <= 0:
            continue
        col = getattr(SyncMetadata, count_column)
        usage = db.query(func.sum(col)).filter(
            SyncMetadata.sync_type.in_(sync_types),
            SyncMetadata.last_sync_at >= period_start
        ).scalar() or 0
        if usage >= limit_val:
            return f"{label} API limit reached ({usage}/{limit_val} calls). Increase the limit or wait for the period to reset."

    return None


def _cleanup_finished_process():
    """Clean up resources when the sync subprocess has exited."""
    global _sync_process, _sync_log_file
    if _sync_log_file:
        try:
            _sync_log_file.close()
        except Exception:
            pass
        _sync_log_file = None
    _sync_process = None


def _is_process_running() -> bool:
    """Check if the sync subprocess is still running. Auto-cleans up if finished."""
    return _check_process_state() == 'running'


def _check_process_state() -> str:
    """Check local subprocess state. Returns 'running', 'exited', or 'none'.

    'none' means no local subprocess was tracked (e.g. scheduled syncs in sync container).
    'exited' means a local subprocess was started and has since terminated.
    """
    if _sync_process is None:
        return 'none'
    if _sync_process.poll() is None:
        return 'running'
    # Process has exited — clean up
    _cleanup_finished_process()
    return 'exited'


def start_sync_process(command: List[str]) -> Dict[str, Any]:
    """Start sync subprocess in background, redirect output to log file."""
    global _sync_process, _sync_log_file
    try:
        os.makedirs(os.path.dirname(SYNC_LOG_PATH), exist_ok=True)
        with open(SYNC_LOG_PATH, "w") as f:
            f.write("")

        # Clear API counter file
        try:
            with open(SYNC_API_COUNTERS_PATH, "w") as f:
                json.dump({"dendreo": 0, "hubspot": 0}, f)
        except Exception:
            pass

        log_file = open(SYNC_LOG_PATH, "a")
        process = subprocess.Popen(
            command,
            stdout=log_file,
            stderr=subprocess.STDOUT,
            cwd="/app"
        )
        _sync_process = process
        _sync_log_file = log_file
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
def get_api_usage(
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
    today_end = today_start + timedelta(days=1)

    # Calendar-week boundaries (Mon 00:00 → next Mon 00:00) so the counter has a real reset moment
    week_start = today_start - timedelta(days=today_start.weekday())
    week_end = week_start + timedelta(days=7)

    month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    if month_start.month == 12:
        month_end = month_start.replace(year=month_start.year + 1, month=1)
    else:
        month_end = month_start.replace(month=month_start.month + 1)

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

    # Get period limits from config
    config = get_or_create_sync_config(db)

    # Today's total (includes both full syncs and ADF syncs)
    sync_types = ['sync_all', 'sync_adf']
    today_stats = db.query(
        func.sum(SyncMetadata.api_calls_count),
        func.sum(SyncMetadata.hubspot_api_calls_count),
        func.count(SyncMetadata.id)
    ).filter(
        SyncMetadata.sync_type.in_(sync_types),
        SyncMetadata.last_sync_at >= today_start
    ).first()
    today_dendreo = today_stats[0] or 0
    today_hubspot = today_stats[1] or 0
    today_syncs = today_stats[2] or 0

    # This week's total
    week_stats = db.query(
        func.sum(SyncMetadata.api_calls_count),
        func.sum(SyncMetadata.hubspot_api_calls_count),
        func.count(SyncMetadata.id)
    ).filter(
        SyncMetadata.sync_type.in_(sync_types),
        SyncMetadata.last_sync_at >= week_start
    ).first()
    week_dendreo = week_stats[0] or 0
    week_hubspot = week_stats[1] or 0
    week_syncs = week_stats[2] or 0

    # This month's total
    month_stats = db.query(
        func.sum(SyncMetadata.api_calls_count),
        func.sum(SyncMetadata.hubspot_api_calls_count),
        func.count(SyncMetadata.id)
    ).filter(
        SyncMetadata.sync_type.in_(sync_types),
        SyncMetadata.last_sync_at >= month_start
    ).first()
    month_dendreo = month_stats[0] or 0
    month_hubspot = month_stats[1] or 0
    month_syncs = month_stats[2] or 0

    return APIUsageStats(
        last_sync=last_sync_data,
        today={
            "api_calls": today_dendreo + today_hubspot,
            "dendreo_calls": today_dendreo,
            "hubspot_calls": today_hubspot,
            "sync_count": today_syncs,
            "dendreo_limit": config.dendreo_daily_limit,
            "hubspot_limit": config.hubspot_daily_limit,
            "period_start": today_start.isoformat(),
            "period_end": today_end.isoformat(),
        },
        this_week={
            "api_calls": week_dendreo + week_hubspot,
            "dendreo_calls": week_dendreo,
            "hubspot_calls": week_hubspot,
            "sync_count": week_syncs,
            "dendreo_limit": config.dendreo_weekly_limit,
            "hubspot_limit": config.hubspot_weekly_limit,
            "period_start": week_start.isoformat(),
            "period_end": week_end.isoformat(),
        },
        this_month={
            "api_calls": month_dendreo + month_hubspot,
            "dendreo_calls": month_dendreo,
            "hubspot_calls": month_hubspot,
            "sync_count": month_syncs,
            "dendreo_limit": config.dendreo_monthly_limit,
            "hubspot_limit": config.hubspot_monthly_limit,
            "period_start": month_start.isoformat(),
            "period_end": month_end.isoformat(),
        }
    )


@router.post("/sync/dry-run", response_model=SyncCommandResponse)
def trigger_dry_run(
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
    process_running = _is_process_running()
    if in_progress or process_running:
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
def force_sync(
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
    process_running = _is_process_running()
    if in_progress or process_running:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="A sync is already running. Wait for it to finish."
        )

    # Check period limits
    period_error = check_period_limits(db)
    if period_error:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=period_error
        )

    logger.info(f"Admin user '{current_user.username}' triggered force sync")

    result = start_sync_process(
        ["python3", "scripts/sync_dendreo.py", "--force", "--log-level", "INFO"]
    )

    return SyncCommandResponse(**result)


@router.post("/sync/adf/{id_action_formation}", response_model=SyncCommandResponse)
def sync_specific_adf(
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
    process_running = _is_process_running()
    if in_progress or process_running:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="A sync is already running. Wait for it to finish."
        )

    # Check period limits
    period_error = check_period_limits(db)
    if period_error:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=period_error
        )

    logger.info(f"Admin user '{current_user.username}' triggered sync for ADF {id_action_formation}")

    result = start_sync_process(
        ["python3", "scripts/sync_dendreo.py", "--adf", id_action_formation, "--log-level", "INFO"]
    )

    return SyncCommandResponse(**result)


@router.get("/sync/config", response_model=SyncConfigResponse)
def get_sync_config(
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
def update_sync_config(
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

    # Period limits (daily, weekly, monthly)
    for field in ['dendreo_daily_limit', 'dendreo_weekly_limit', 'dendreo_monthly_limit',
                  'hubspot_daily_limit', 'hubspot_weekly_limit', 'hubspot_monthly_limit']:
        value = getattr(config_update, field, None)
        if value is not None:
            limit_val = value if value > 0 else None
            setattr(config, field, limit_val)
            logger.info(f"Admin user '{current_user.username}' set {field} to {limit_val or 'unlimited'}")

    config.updated_by_user_id = current_user.id
    config.last_updated_at = datetime.now(timezone.utc)

    db.commit()
    db.refresh(config)

    return config


@router.get("/sync/status", response_model=SyncStatusResponse)
def get_sync_status(
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """
    Check if a sync is currently running (status='in_progress')
    Return last sync info + current config
    """
    # Only clean up stale in_progress records if a LOCAL subprocess has exited.
    # State 'none' means no local subprocess (e.g. scheduled sync in sync container) — don't touch.
    process_state = _check_process_state()
    process_running = process_state == 'running'

    if process_state == 'exited':
        stale_records = db.query(SyncMetadata).filter(
            SyncMetadata.status == 'in_progress'
        ).all()
        if stale_records:
            for record in stale_records:
                record.status = 'error'
                record.error_message = 'Process exited without updating status'
                record.updated_at = datetime.now(timezone.utc)
                if record.last_sync_at:
                    record.duration_seconds = (datetime.now(timezone.utc) - record.last_sync_at).total_seconds()
            db.commit()

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
        is_running=(in_progress is not None) or process_running,
        last_sync=last_sync_data,
        config=config,
        skipped_adf_count=skipped_adf_count
    )


@router.get("/sync/history")
def get_sync_history(
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db),
    page: int = QueryParam(1, ge=1),
    page_size: int = QueryParam(50, ge=1, le=200),
):
    """
    Get full sync history with pagination.
    """
    query = db.query(SyncMetadata).filter(
        SyncMetadata.sync_type.in_(['sync_all', 'sync_adf'])
    ).order_by(SyncMetadata.last_sync_at.desc())

    total = query.count()
    offset = (page - 1) * page_size
    syncs = query.offset(offset).limit(page_size).all()

    import ast
    items = []
    for sync in syncs:
        parsed_stats = None
        if sync.stats:
            try:
                parsed_stats = ast.literal_eval(sync.stats) if isinstance(sync.stats, str) else sync.stats
            except (ValueError, SyntaxError):
                pass
        items.append({
            "id": sync.id,
            "sync_type": sync.sync_type,
            "last_sync_at": sync.last_sync_at.isoformat() if sync.last_sync_at else None,
            "status": sync.status,
            "api_calls_count": sync.api_calls_count or 0,
            "hubspot_api_calls_count": sync.hubspot_api_calls_count or 0,
            "duration_seconds": sync.duration_seconds,
            "error_message": sync.error_message,
            "stats": parsed_stats,
            "log_path": sync.log_path,
        })

    return {
        "items": items,
        "total": total,
        "page": page,
        "page_size": page_size,
        "total_pages": max(1, -(-total // page_size)),
    }


@router.post("/sync/resume", response_model=SyncCommandResponse)
def resume_sync(
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
    process_running = _is_process_running()
    if in_progress or process_running:
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

    # Check period limits
    period_error = check_period_limits(db)
    if period_error:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=period_error
        )

    logger.info(f"Admin user '{current_user.username}' triggered resume sync for {len(skipped_ids)} ADFs")

    adf_ids_str = ','.join(str(aid) for aid in skipped_ids)
    result = start_sync_process(
        ["python3", "scripts/sync_dendreo.py", "--force", "--resume-adfs", adf_ids_str, "--log-level", "INFO"]
    )

    return SyncCommandResponse(**result)


@router.post("/sync/resume/cancel", response_model=SyncCommandResponse)
def cancel_resume(
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """
    Discard the pending "skipped ADFs" list from the last sync, so the resume button goes away.
    Used when the admin wants to acknowledge that the API-limit-truncated sync is final.
    """
    last_sync = db.query(SyncMetadata).filter(
        SyncMetadata.sync_type == 'sync_all',
        SyncMetadata.status == 'success'
    ).order_by(SyncMetadata.last_sync_at.desc()).first()

    if not last_sync or not last_sync.stats:
        return SyncCommandResponse(status='success', message='Nothing to cancel')

    import ast
    try:
        stats_dict = ast.literal_eval(last_sync.stats) if isinstance(last_sync.stats, str) else last_sync.stats
    except (ValueError, SyntaxError):
        return SyncCommandResponse(status='success', message='Could not parse stats; nothing changed')

    if not stats_dict.get('skipped_adf_ids'):
        return SyncCommandResponse(status='success', message='No skipped ADFs to cancel')

    cleared_count = len(stats_dict.get('skipped_adf_ids') or [])
    stats_dict['skipped_adf_ids'] = []
    stats_dict['adfs_skipped_api_limit'] = 0
    last_sync.stats = str(stats_dict)
    last_sync.updated_at = datetime.now(timezone.utc)
    db.commit()

    logger.info(f"Admin user '{current_user.username}' cancelled resume for {cleared_count} skipped ADFs")
    return SyncCommandResponse(
        status='success',
        message=f'Cleared {cleared_count} skipped ADF(s) from resume queue'
    )


@router.post("/sync/stop", response_model=SyncCommandResponse)
def stop_sync(
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """
    Stop a currently running sync process.
    Sends SIGTERM, waits briefly, then SIGKILL if needed.
    """
    # Check if there's a running subprocess
    if not _is_process_running():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="No sync process is currently running."
        )

    pid = _sync_process.pid
    logger.warning(f"Admin user '{current_user.username}' requested sync stop (PID: {pid})")

    try:
        # Send SIGTERM first (graceful shutdown)
        _sync_process.terminate()

        # Wait up to 5 seconds for graceful shutdown
        try:
            _sync_process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            # Force kill if SIGTERM didn't work
            logger.warning(f"Process {pid} did not stop after SIGTERM, sending SIGKILL")
            _sync_process.kill()
            _sync_process.wait(timeout=5)

        # Update any in-progress SyncMetadata records
        in_progress_records = db.query(SyncMetadata).filter(
            SyncMetadata.status == 'in_progress'
        ).all()

        for record in in_progress_records:
            record.status = 'error'
            record.error_message = f'Manually stopped by admin ({current_user.username})'
            record.updated_at = datetime.now(timezone.utc)
            if record.last_sync_at:
                record.duration_seconds = (datetime.now(timezone.utc) - record.last_sync_at).total_seconds()

        db.commit()

        _cleanup_finished_process()

        return SyncCommandResponse(
            status="success",
            message=f"Sync process (PID: {pid}) has been stopped."
        )

    except Exception as e:
        logger.error(f"Error stopping sync process: {e}")
        return SyncCommandResponse(
            status="error",
            message=f"Failed to stop sync: {str(e)}"
        )


@router.post("/sync/categories", response_model=SyncCommandResponse)
async def sync_categories(
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """
    Manually sync module categories from Dendreo API.
    Lightweight operation (1 API call).
    """
    from app.services.dendreo_client import DendreoClient

    logger.info(f"Admin user '{current_user.username}' triggered category sync")

    try:
        client = DendreoClient()
        categories_data = await client.get_module_categories()

        if not categories_data:
            return SyncCommandResponse(status="success", message="No categories found in Dendreo API.")

        count = 0
        for cat in categories_data:
            id_cat = cat.get('id_categorie_module')
            if not id_cat:
                continue

            display_order = 0
            try:
                display_order = int(cat.get('order', 0))
            except (ValueError, TypeError):
                pass

            existing = db.query(ModuleCategory).filter(
                ModuleCategory.id_categorie_module == str(id_cat)
            ).first()

            if existing:
                existing.intitule = cat.get('intitule', '')
                existing.color = cat.get('color', '')
                existing.status = cat.get('status', '1')
                existing.display_order = display_order
                existing.updated_at = datetime.now(timezone.utc)
            else:
                new_cat = ModuleCategory(
                    id_categorie_module=str(id_cat),
                    intitule=cat.get('intitule', ''),
                    color=cat.get('color', ''),
                    status=cat.get('status', '1'),
                    display_order=display_order
                )
                db.add(new_cat)

            count += 1

        db.commit()
        return SyncCommandResponse(status="success", message=f"Synced {count} module categories.")

    except Exception as e:
        logger.error(f"Category sync failed: {e}")
        return SyncCommandResponse(status="error", message=f"Category sync failed: {str(e)}")


@router.get("/sync/{sync_id}/log")
def get_sync_log(
    sync_id: int,
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """
    Stream the archived per-sync log file as a downloadable text/plain attachment.
    The path is derived from SyncMetadata.log_path (relative to LOGS_DIR) so older
    runs without an attached log return a 404 cleanly.
    """
    from fastapi.responses import FileResponse
    from app.services.sync_logs import LOGS_DIR

    record = db.query(SyncMetadata).get(sync_id)
    if not record:
        raise HTTPException(status_code=404, detail="Sync not found")

    if not record.log_path:
        raise HTTPException(status_code=404, detail="No log archived for this sync")

    abs_path = os.path.join(LOGS_DIR, record.log_path)
    # Guard against path traversal: log_path must remain inside LOGS_DIR
    real_logs_dir = os.path.realpath(LOGS_DIR)
    real_path = os.path.realpath(abs_path)
    if not real_path.startswith(real_logs_dir + os.sep) and real_path != real_logs_dir:
        raise HTTPException(status_code=400, detail="Invalid log path")

    if not os.path.isfile(real_path):
        raise HTTPException(status_code=404, detail="Log file no longer on disk")

    filename = f"sync_{sync_id}.log"
    return FileResponse(
        real_path,
        media_type="text/plain; charset=utf-8",
        filename=filename,
    )


@router.get("/sync/live-log")
def get_live_log(
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

    # Check local subprocess state — only clean up stale records if a local process exited.
    # State 'none' means no local subprocess (e.g. scheduled sync in sync container) — don't touch.
    process_state = _check_process_state()
    process_running = process_state == 'running'

    if process_state == 'exited':
        stale_records = db.query(SyncMetadata).filter(
            SyncMetadata.status == 'in_progress'
        ).all()
        if stale_records:
            for record in stale_records:
                record.status = 'error'
                record.error_message = 'Process exited without updating status'
                record.updated_at = datetime.now(timezone.utc)
                if record.last_sync_at:
                    record.duration_seconds = (datetime.now(timezone.utc) - record.last_sync_at).total_seconds()
            db.commit()
            logger.info(f"Cleaned up {len(stale_records)} stale in_progress record(s)")

    db_in_progress = db.query(SyncMetadata).filter(
        SyncMetadata.status == 'in_progress'
    ).first() is not None

    # Read API counters from shared file
    api_counters = {"dendreo": 0, "hubspot": 0}
    try:
        if os.path.exists(SYNC_API_COUNTERS_PATH):
            with open(SYNC_API_COUNTERS_PATH, "r") as f:
                api_counters = json.load(f)
    except (json.JSONDecodeError, IOError):
        pass

    is_running = db_in_progress or process_running

    # When sync just finished, include the final result for the frontend
    final_status = None
    final_message = None
    if not is_running and offset > 0:
        # offset > 0 means we were polling, so the sync just ended
        latest = db.query(SyncMetadata).order_by(
            SyncMetadata.updated_at.desc()
        ).first()
        if latest:
            if latest.status == 'error':
                final_status = 'error'
                final_message = latest.error_message or 'Sync failed.'
            elif latest.status == 'success' and latest.error_message:
                # warning: success with an error_message means etape warning
                final_status = 'warning'
                final_message = latest.error_message
            elif latest.status == 'success':
                api_count = latest.api_calls_count or 0
                duration = int(latest.duration_seconds) if latest.duration_seconds else 0
                final_status = 'success'
                final_message = f'Sync completed successfully. {api_count} API calls in {duration}s.'

    return {
        "content": content,
        "offset": new_offset,
        "is_running": is_running,
        "api_counters": api_counters,
        "final_status": final_status,
        "final_message": final_message
    }


# ─── Admin Interventions Log ────────────────────────────────────────────────

@router.get("/interventions", dependencies=[Depends(require_manager_or_admin)])
def get_admin_interventions(
    page: int = QueryParam(1, ge=1),
    page_size: int = QueryParam(50, ge=1, le=200),
    sort_order: str = QueryParam("desc", pattern="^(asc|desc)$"),
    intervention_type: Optional[str] = QueryParam(None),
    is_active: Optional[bool] = QueryParam(None),
    user_id: Optional[int] = QueryParam(None),
    search: Optional[str] = QueryParam(None),
    date_from: Optional[str] = QueryParam(None),
    date_to: Optional[str] = QueryParam(None),
    db: Session = Depends(get_db),
):
    """Admin endpoint: list all interventions with filtering, pagination, and stats."""
    # Base query with joins
    query = db.query(Intervention).options(
        subqueryload(Intervention.participant),
        subqueryload(Intervention.user),
    )

    # Filters
    if intervention_type:
        query = query.filter(Intervention.intervention_type == intervention_type)
    if is_active is not None:
        query = query.filter(Intervention.is_active == is_active)
    if user_id:
        query = query.filter(Intervention.user_id == user_id)
    if search:
        term = f"%{search}%"
        query = query.join(Participant, Participant.id == Intervention.participant_id).filter(
            func.concat(Participant.nom, ' ', Participant.prenom).ilike(term)
        )
    if date_from:
        try:
            dt_from = datetime.fromisoformat(date_from)
            query = query.filter(Intervention.created_at >= dt_from)
        except ValueError:
            pass
    if date_to:
        try:
            dt_to = datetime.fromisoformat(date_to)
            # Include the full day
            dt_to = dt_to.replace(hour=23, minute=59, second=59)
            query = query.filter(Intervention.created_at <= dt_to)
        except ValueError:
            pass

    # Total count for pagination
    total = query.count()

    # Sort
    order_fn = desc if sort_order == "desc" else asc
    query = query.order_by(order_fn(Intervention.created_at))

    # Paginate
    offset = (page - 1) * page_size
    interventions = query.offset(offset).limit(page_size).all()

    # Build response items
    items = []
    for iv in interventions:
        items.append({
            "id": iv.id,
            "intervention_type": iv.intervention_type,
            "details": iv.details,
            "is_active": iv.is_active,
            "snooze_until": iv.snooze_until.isoformat() if iv.snooze_until else None,
            "hubspot_note_id": iv.hubspot_note_id,
            "created_at": iv.created_at.isoformat() if iv.created_at else None,
            "participant_id": iv.participant_id,
            "participant_name": f"{iv.participant.nom} {iv.participant.prenom}" if iv.participant else None,
            "id_action_formation": iv.id_action_formation,
            "user_id": iv.user_id,
            "user_display_name": iv.user.display_name or iv.user.username if iv.user else None,
        })

    return {
        "items": items,
        "total": total,
        "page": page,
        "page_size": page_size,
        "total_pages": max(1, -(-total // page_size)),  # ceil division
    }


@router.get("/interventions/stats", dependencies=[Depends(require_manager_or_admin)])
def get_admin_intervention_stats(
    db: Session = Depends(get_db),
):
    """Admin endpoint: aggregate intervention stats."""
    rows = db.query(
        Intervention.intervention_type,
        func.count(Intervention.id),
    ).group_by(Intervention.intervention_type).all()

    by_type = {r[0]: r[1] for r in rows}
    total = sum(by_type.values())

    # Active snoozes / dismissals
    active_snoozes = db.query(func.count(Intervention.id)).filter(
        Intervention.intervention_type == 'snooze',
        Intervention.is_active == True,
        Intervention.snooze_until > func.now(),
    ).scalar()

    active_dismissals = db.query(func.count(Intervention.id)).filter(
        Intervention.intervention_type == 'dismiss',
        Intervention.is_active == True,
    ).scalar()

    # Staff members who have created interventions
    staff_rows = db.query(
        User.id,
        User.display_name,
        User.username,
        func.count(Intervention.id).label("count"),
    ).join(Intervention, Intervention.user_id == User.id
    ).group_by(User.id, User.display_name, User.username
    ).order_by(desc(func.count(Intervention.id))
    ).all()

    staff = [
        {"id": r.id, "display_name": r.display_name or r.username, "count": r.count}
        for r in staff_rows
    ]

    return {
        "total": total,
        "by_type": by_type,
        "active_snoozes": active_snoozes,
        "active_dismissals": active_dismissals,
        "staff": staff,
    }


@router.get("/action-history", dependencies=[Depends(require_admin)])
def get_action_history(
    page: int = QueryParam(1, ge=1),
    page_size: int = QueryParam(50, ge=1, le=200),
    sort_order: str = QueryParam("desc", pattern="^(asc|desc)$"),
    action_type: Optional[str] = QueryParam(None),
    status_filter: Optional[str] = QueryParam(None, alias="status"),
    user_id: Optional[int] = QueryParam(None),
    search: Optional[str] = QueryParam(None),
    date_from: Optional[str] = QueryParam(None),
    date_to: Optional[str] = QueryParam(None),
    db: Session = Depends(get_db),
):
    """Admin endpoint: list action history (user-triggered manip actions) with filtering and pagination."""
    query = db.query(ActionHistory).options(
        subqueryload(ActionHistory.participant),
        subqueryload(ActionHistory.user),
    )

    if action_type:
        query = query.filter(ActionHistory.action_type == action_type)
    if status_filter:
        query = query.filter(ActionHistory.status == status_filter)
    if user_id:
        query = query.filter(ActionHistory.user_id == user_id)
    if search:
        term = f"%{search}%"
        query = query.outerjoin(Participant, Participant.id == ActionHistory.participant_id).filter(
            func.concat(Participant.nom, ' ', Participant.prenom).ilike(term)
        )
    if date_from:
        try:
            dt_from = datetime.fromisoformat(date_from)
            query = query.filter(ActionHistory.created_at >= dt_from)
        except ValueError:
            pass
    if date_to:
        try:
            dt_to = datetime.fromisoformat(date_to).replace(hour=23, minute=59, second=59)
            query = query.filter(ActionHistory.created_at <= dt_to)
        except ValueError:
            pass

    total = query.count()

    order_fn = desc if sort_order == "desc" else asc
    query = query.order_by(order_fn(ActionHistory.created_at))

    offset = (page - 1) * page_size
    rows = query.offset(offset).limit(page_size).all()

    items = []
    for r in rows:
        items.append({
            "id": r.id,
            "action_type": r.action_type,
            "category": "manip",
            "status": r.status,
            "created_at": r.created_at.isoformat() if r.created_at else None,
            "duration_seconds": r.duration_seconds,
            "api_calls_count": r.api_calls_count,
            "hubspot_api_calls_count": r.hubspot_api_calls_count,
            "error_message": r.error_message,
            "details": r.details,
            "participant_id": r.participant_id,
            "participant_name": f"{r.participant.prenom} {r.participant.nom}".strip() if r.participant else None,
            "id_action_formation": r.id_action_formation,
            "deal_id": r.deal_id,
            "user_id": r.user_id,
            "source": (r.user.display_name or r.user.username) if r.user else "Système",
        })

    return {
        "items": items,
        "total": total,
        "page": page,
        "page_size": page_size,
        "total_pages": max(1, -(-total // page_size)),
    }


@router.get("/action-history/stats", dependencies=[Depends(require_admin)])
def get_action_history_stats(db: Session = Depends(get_db)):
    """Aggregate stats for the action-history page header."""
    type_rows = db.query(
        ActionHistory.action_type,
        func.count(ActionHistory.id),
    ).group_by(ActionHistory.action_type).all()
    by_type = {r[0]: r[1] for r in type_rows}
    total = sum(by_type.values())

    status_rows = db.query(
        ActionHistory.status,
        func.count(ActionHistory.id),
    ).group_by(ActionHistory.status).all()
    by_status = {r[0]: r[1] for r in status_rows}

    staff_rows = db.query(
        User.id,
        User.display_name,
        User.username,
        func.count(ActionHistory.id).label("count"),
    ).join(ActionHistory, ActionHistory.user_id == User.id
    ).group_by(User.id, User.display_name, User.username
    ).order_by(desc(func.count(ActionHistory.id))
    ).all()

    staff = [
        {"id": r.id, "display_name": r.display_name or r.username, "count": r.count}
        for r in staff_rows
    ]

    return {
        "total": total,
        "by_type": by_type,
        "by_status": by_status,
        "staff": staff,
    }


# ============================================================================
# User management
# ============================================================================

@router.get("/users", response_model=List[AdminUserResponse])
async def list_users(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    """List all users with their role and how that role was assigned."""
    return db.query(User).order_by(User.username).all()


@router.patch("/users/{user_id}", response_model=AdminUserResponse)
async def update_user(
    user_id: int,
    body: AdminUserUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    """Update a user's role or active state.

    Setting a role marks it 'manual' so the M365 login stops re-deriving it from
    Entra groups (see auth/microsoft.py). reset_role_to_group hands it back.
    """
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    if body.role is not None and body.reset_role_to_group:
        raise HTTPException(
            status_code=400,
            detail="Set a role or hand it back to group mapping, not both",
        )

    # Don't let an admin lock themselves out of the admin area — including by
    # unpinning their own role, which the next M365 login would then re-derive.
    if user.id == current_user.id:
        if body.role is not None and body.role != 'admin':
            raise HTTPException(status_code=400, detail="You cannot change your own role")
        if body.reset_role_to_group:
            raise HTTPException(status_code=400, detail="You cannot unpin your own role")
        if body.is_active is False:
            raise HTTPException(status_code=400, detail="You cannot deactivate your own account")

    changes = {}
    if body.role is not None:
        if body.role != user.role:
            changes['role'] = f"{user.role} -> {body.role}"
            user.role = body.role
        # Pin it either way, so group mapping stops overwriting the choice.
        user.role_source = 'manual'

    if body.reset_role_to_group and user.role_source != 'group':
        changes['role_source'] = 'manual -> group'
        user.role_source = 'group'

    if body.is_active is not None and body.is_active != user.is_active:
        changes['is_active'] = f"{user.is_active} -> {body.is_active}"
        user.is_active = body.is_active

    user.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(user)

    if changes:
        logger.info(f"User '{user.username}' updated by {current_user.username}: {changes}")
    return user
