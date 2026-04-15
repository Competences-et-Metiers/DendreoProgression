"""Shared API budget computation across SyncMetadata (sync) and ActionHistory (manip)."""
from datetime import datetime, timedelta
from typing import Tuple
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.models.models import SyncMetadata, ActionHistory, AdminSyncConfig


def _period_start(now: datetime, period: str) -> datetime:
    if period == 'daily':
        return now.replace(hour=0, minute=0, second=0, microsecond=0)
    if period == 'weekly':
        return now - timedelta(days=7)
    if period == 'monthly':
        return now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    raise ValueError(f"Unknown period: {period}")


def get_period_usage(db: Session, provider: str, period: str) -> int:
    """Return total API calls made in the given period across both sync and manip records.

    Args:
        provider: 'dendreo' or 'hubspot'
        period: 'daily', 'weekly', or 'monthly'
    """
    now = datetime.now()
    start = _period_start(now, period)

    if provider == 'dendreo':
        sync_col = SyncMetadata.api_calls_count
        action_col = ActionHistory.api_calls_count
    elif provider == 'hubspot':
        sync_col = SyncMetadata.hubspot_api_calls_count
        action_col = ActionHistory.hubspot_api_calls_count
    else:
        raise ValueError(f"Unknown provider: {provider}")

    sync_sum = db.query(func.sum(sync_col)).filter(
        SyncMetadata.sync_type.in_(['sync_all', 'sync_adf']),
        SyncMetadata.last_sync_at >= start,
    ).scalar() or 0

    action_sum = db.query(func.sum(action_col)).filter(
        ActionHistory.created_at >= start,
    ).scalar() or 0

    return int(sync_sum) + int(action_sum)


def check_budget(db: Session, dendreo_needed: int = 0, hubspot_needed: int = 0) -> Tuple[bool, str]:
    """Check whether making the given number of additional calls would exceed any period budget.

    Returns (ok, reason). reason is populated only when ok=False.
    """
    config = db.query(AdminSyncConfig).first()
    if not config:
        return True, ""

    checks = [
        ('dendreo', dendreo_needed, [
            ('daily', config.dendreo_daily_limit),
            ('weekly', config.dendreo_weekly_limit),
            ('monthly', config.dendreo_monthly_limit),
        ]),
        ('hubspot', hubspot_needed, [
            ('daily', config.hubspot_daily_limit),
            ('weekly', config.hubspot_weekly_limit),
            ('monthly', config.hubspot_monthly_limit),
        ]),
    ]

    for provider, needed, periods in checks:
        if needed <= 0:
            continue
        for period_name, limit in periods:
            if not limit or limit <= 0:
                continue
            usage = get_period_usage(db, provider, period_name)
            if usage + needed > limit:
                return False, f"{provider.capitalize()} {period_name} budget exhausted ({usage}/{limit})"

    return True, ""
