from fastapi import APIRouter, Depends, BackgroundTasks
from sqlalchemy.orm import Session
from app.models.database import get_db
from app.models.schemas import SyncResponse
from app.services.data_processor import DataProcessor

router = APIRouter(prefix="/sync", tags=["synchronization"])

@router.post("/", response_model=SyncResponse)
async def sync_dendreo_data(
        background_tasks: BackgroundTasks,
        db: Session = Depends(get_db)
):
    """Sync data from Dendreo API"""
    processor = DataProcessor(db)

    try:
        processed_courses, processed_participants, errors = await processor.sync_dendreo_data()

        return SyncResponse(
            success=len(errors) == 0,
            message="Synchronization completed" if len(errors) == 0 else "Synchronization completed with errors",
            processed_courses=processed_courses,
            processed_participants=processed_participants,
            errors=errors
        )
    finally:
        await processor.close()

@router.post("/background", response_model=dict)
async def sync_dendreo_data_background(
        background_tasks: BackgroundTasks,
        db: Session = Depends(get_db)
):
    """Start background sync from Dendreo API"""

    async def run_sync():
        processor = DataProcessor(db)
        try:
            await processor.sync_dendreo_data()
        finally:
            await processor.close()

    background_tasks.add_task(run_sync)
    return {"message": "Background synchronization started"}
