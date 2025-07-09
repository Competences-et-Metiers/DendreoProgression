from fastapi import APIRouter, Depends, HTTPException, Header
from app.services.dendreo_sync import DendreoSync
from app.services.dendreo_client import DendreoClient
from app.models.database import get_db
from sqlalchemy.orm import Session
from typing import Dict, Any, Optional
import logging
import httpx
import json
import os
from datetime import datetime
from app.models.models import Participant, Course, Module, ParticipantCourse, SyncMetadata
from sqlalchemy import text
from app.config.settings import settings

logger = logging.getLogger(__name__)
router = APIRouter()

# Simple API key authentication for sync endpoints
def verify_sync_api_key(x_api_key: Optional[str] = Header(None)):
    """
    Verify API key for sync endpoints
    Set SYNC_API_KEY environment variable to enable authentication
    """
    expected_key = getattr(settings, 'sync_api_key', None) or os.getenv('SYNC_API_KEY')
    
    if expected_key:
        if not x_api_key:
            raise HTTPException(
                status_code=401,
                detail="API key required. Set X-API-Key header."
            )
        if x_api_key != expected_key:
            raise HTTPException(
                status_code=401,
                detail="Invalid API key"
            )
    
    return True

@router.post("/sync-all")
async def sync_all(
    db: Session = Depends(get_db),
    _: bool = Depends(verify_sync_api_key)
) -> Dict[str, Any]:
    """Synchronize all data from Dendreo"""
    sync_start_time = datetime.utcnow()
    
    # Create or update sync metadata record
    sync_metadata = db.query(SyncMetadata).filter(SyncMetadata.sync_type == 'sync_all').first()
    if not sync_metadata:
        sync_metadata = SyncMetadata(
            sync_type='sync_all',
            last_sync_at=sync_start_time,
            status='in_progress'
        )
        db.add(sync_metadata)
    else:
        sync_metadata.last_sync_at = sync_start_time
        sync_metadata.status = 'in_progress'
        sync_metadata.error_message = None
    
    db.commit()
    
    try:
        client = DendreoClient()
        sync_service = DendreoSync(db, client)
        result = await sync_service.sync_all()
        
        # Update sync metadata with success
        sync_metadata.status = 'success'
        sync_metadata.stats = json.dumps(result.get('stats', {}))
        sync_metadata.updated_at = datetime.utcnow()
        db.commit()
        
        return result
    except Exception as e:
        # Update sync metadata with error
        sync_metadata.status = 'error'
        sync_metadata.error_message = str(e)
        sync_metadata.updated_at = datetime.utcnow()
        db.commit()
        
        raise HTTPException(status_code=500, detail=f"Sync failed: {str(e)}")

@router.post("/sync-test")
async def sync_test(db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Test sync with a small dataset"""
    try:
        client = DendreoClient()
        sync_service = DendreoSync(db, client)
        result = await sync_service.test_sync_small()
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Test sync failed: {str(e)}")

@router.post("/cleanup-elearning-sync")
async def cleanup_elearning_sync(
    db: Session = Depends(get_db),
    _: bool = Depends(verify_sync_api_key)
) -> Dict[str, Any]:
    """Remove all elearning_sync courses and related data from the database"""
    try:
        logger.info("Starting cleanup of elearning_sync data via API...")
        
        # First, let's see what we're dealing with (Course model no longer has mode_organisation)
        # Look for courses with elearning_sync modules instead
        sync_course_ids = []
        sync_modules = db.query(Module).filter(Module.mode_organisation == 'elearning_sync').all()
        sync_course_ids = list(set([m.course_id for m in sync_modules if m.course_id]))
        sync_courses = db.query(Course).filter(Course.id.in_(sync_course_ids)).all() if sync_course_ids else []
        
        if not sync_courses:
            return {
                "status": "success",
                "message": "No elearning_sync courses found in database",
                "stats": {
                    "participant_courses_deleted": 0,
                    "modules_deleted": 0,
                    "courses_deleted": 0,
                    "orphaned_participants": 0
                }
            }
        
        logger.info(f"Found {len(sync_courses)} elearning_sync courses to clean up")
        
        # Count modules with elearning_sync mode_organisation  
        logger.info(f"Found {len(sync_modules)} elearning_sync modules to clean up")
        
        # Step 1: Delete ParticipantCourse records for elearning_sync courses
        participant_courses_deleted = 0
        if sync_course_ids:
            participant_courses_deleted = db.query(ParticipantCourse).filter(
                ParticipantCourse.course_id.in_(sync_course_ids)
            ).count()
            
            db.query(ParticipantCourse).filter(
                ParticipantCourse.course_id.in_(sync_course_ids)
            ).delete(synchronize_session=False)
            
            logger.info(f"Deleted {participant_courses_deleted} ParticipantCourse records")
        
        # Step 2: Delete Module records for elearning_sync courses OR with elearning_sync mode
        modules_deleted = 0
        
        # Delete modules linked to elearning_sync courses
        if sync_course_ids:
            modules_by_course = db.query(Module).filter(
                Module.course_id.in_(sync_course_ids)
            ).count()
            
            db.query(Module).filter(
                Module.course_id.in_(sync_course_ids)
            ).delete(synchronize_session=False)
            
            modules_deleted += modules_by_course
            logger.info(f"Deleted {modules_by_course} modules linked to elearning_sync courses")
        
        # Delete modules with elearning_sync mode_organisation
        modules_by_mode = db.query(Module).filter(
            Module.mode_organisation == 'elearning_sync'
        ).count()
        
        db.query(Module).filter(
            Module.mode_organisation == 'elearning_sync'
        ).delete(synchronize_session=False)
        
        modules_deleted += modules_by_mode
        logger.info(f"Deleted {modules_by_mode} modules with elearning_sync mode")
        
        # Step 3: Delete Course records that only had elearning_sync modules  
        # (Course model no longer has mode_organisation, courses are deleted based on modules)
        courses_deleted = len(sync_courses)
        if sync_course_ids:
            db.query(Course).filter(Course.id.in_(sync_course_ids)).delete(synchronize_session=False)
        
        logger.info(f"Deleted {courses_deleted} courses with elearning_sync modules")
        
        # Step 4: Find orphaned participants who no longer have any courses
        orphaned_participants = db.execute(text("""
            SELECT p.id, p.id_participant, p.email
            FROM participants p
            LEFT JOIN modules m ON p.id = m.participant_id
            LEFT JOIN participant_courses pc ON p.id = pc.participant_id
            WHERE m.id IS NULL AND pc.id IS NULL
        """)).fetchall()
        
        orphaned_count = len(orphaned_participants)
        if orphaned_participants:
            logger.info(f"Found {orphaned_count} participants with no remaining courses/modules")
            # Note: We don't auto-delete participants, just report them
        
        # Commit all changes
        db.commit()
        
        logger.info("✅ Cleanup completed successfully via API!")
        
        return {
            "status": "success",
            "message": f"Successfully cleaned up elearning_sync data",
            "stats": {
                "participant_courses_deleted": participant_courses_deleted,
                "modules_deleted": modules_deleted,
                "courses_deleted": courses_deleted,
                "orphaned_participants": orphaned_count
            }
        }
        
    except Exception as e:
        logger.error(f"Error during cleanup: {str(e)}")
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Cleanup failed: {str(e)}")

@router.get("/elearning-sync-stats")
async def get_elearning_sync_stats(db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Get statistics about elearning_sync data in the database"""
    try:
        # Count courses with elearning_sync modules (Course model no longer has mode_organisation)
        sync_modules = db.query(Module).filter(Module.mode_organisation == 'elearning_sync').all()
        sync_course_ids = list(set([m.course_id for m in sync_modules if m.course_id]))
        sync_courses_count = len(sync_course_ids)
        
        # Count modules with elearning_sync mode
        sync_modules_count = db.query(Module).filter(Module.mode_organisation == 'elearning_sync').count()
        
        # Count modules linked to courses with elearning_sync modules
        modules_in_sync_courses = 0
        if sync_course_ids:
            modules_in_sync_courses = db.query(Module).filter(Module.course_id.in_(sync_course_ids)).count()
        
        # Count participant courses linked to elearning_sync courses
        participant_courses_in_sync = 0
        if sync_course_ids:
            participant_courses_in_sync = db.query(ParticipantCourse).filter(ParticipantCourse.course_id.in_(sync_course_ids)).count()
        
        return {
            "status": "success",
            "stats": {
                "elearning_sync_courses": sync_courses_count,
                "elearning_sync_modules": sync_modules_count,
                "modules_in_sync_courses": modules_in_sync_courses,
                "participant_courses_in_sync": participant_courses_in_sync
            }
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get stats: {str(e)}")


@router.get("/last-sync")
async def get_last_sync(db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Get information about the last sync-all operation"""
    try:
        sync_metadata = db.query(SyncMetadata).filter(SyncMetadata.sync_type == 'sync_all').first()
        
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
        logger.error(f"Error getting last sync info: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to get last sync info: {str(e)}")

@router.get("/test-api")
async def test_api():
    """Test API connection"""
    try:
        client = DendreoClient()
        url = f"{client.base_url}/lmps.php"
        params = {'key': client.api_key, 'include': 'participant,module'}

        async with httpx.AsyncClient() as http_client:
            response = await http_client.head(url, params=params, timeout=10.0)
            return {
                "status": "success" if response.status_code == 200 else "error",
                "status_code": response.status_code,
                "message": "API connection test"
            }
    except Exception as e:
        return {"status": "error", "message": str(e)}
