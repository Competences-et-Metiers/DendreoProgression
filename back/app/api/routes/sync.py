from fastapi import APIRouter, Depends, HTTPException
from app.models.database import get_db
from sqlalchemy.orm import Session
from typing import Dict, Any
import logging
import json
from datetime import datetime, timezone
from app.models.models import SyncMetadata

logger = logging.getLogger(__name__)
router = APIRouter()

# Note: Sync execution endpoints removed - use sync container/script instead
# Only read-only status endpoints remain in the API

@router.get("/last-sync")
async def get_last_sync(db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Get information about the last sync-all operation"""
    try:
        sync_metadata = db.query(SyncMetadata).filter(
            SyncMetadata.sync_type == 'sync_all'
        ).order_by(SyncMetadata.last_sync_at.desc()).first()
        
        if not sync_metadata:
            return {
                "status": "no_sync",
                "message": "No sync operation has been performed yet",
                "last_sync_at": None,
                "sync_status": None,
                "stats": None
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
            "error_message": sync_metadata.error_message
        }
        
    except Exception as e:
        logger.error(f"Failed to get last sync info: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to get last sync info: {str(e)}")