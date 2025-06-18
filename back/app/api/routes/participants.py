from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session, joinedload
from typing import List, Optional
from app.models.database import get_db
from app.models.models import Participant, ParticipantCourse, Course
from app.models.schemas import ParticipantWithProgress, ParticipantCourse as ParticipantCourseSchema
from app.services.cache_service import cache_service
import logging

logger = logging.getLogger(__name__)
router = APIRouter()

def calculate_activity_status(participant_course: ParticipantCourse, db: Session = None) -> str:
    """Calculate activity status for a participant course"""
    from datetime import datetime
    from app.models.models import Module, Course

    # Check if completed
    if participant_course.overall_progression and participant_course.overall_progression >= 100.0:
        return "completed"

    # Check last activity - if null in participant_course, calculate from modules
    last_activity = participant_course.last_activity
    
    if not last_activity and db:
        # Get the course and find the ADF
        course = db.query(Course).filter(Course.id == participant_course.course_id).first()
        if course:
            # Get all modules for this participant in this ADF
            adf_lam_ids = db.query(Course.id_lam).filter(
                Course.id_action_formation == course.id_action_formation
            ).distinct().all()
            
            if adf_lam_ids:
                lam_ids_list = [lam_id[0] for lam_id in adf_lam_ids if lam_id[0]]
                modules = db.query(Module).filter(
                    Module.id_lam.in_(lam_ids_list),
                    Module.participant_id == participant_course.participant_id,
                    Module.mode_organisation == 'elearning_async',
                    Module.lms_last_access_at.isnot(None)
                ).all()
                
                if modules:
                    last_activities = [m.lms_last_access_at for m in modules if m.lms_last_access_at]
                    if last_activities:
                        last_activity = max(last_activities)

    if not last_activity:
        return "not_started"

    days_since_access = (datetime.now() - last_activity).days

    if days_since_access <= 30:  # 30 days threshold
        return "active"
    else:
        return "inactive"

@router.get("/", response_model=List[ParticipantWithProgress])
async def get_participants(
        skip: int = Query(0, ge=0),
        limit: int = Query(100, ge=1, le=1000),
        email: Optional[str] = Query(None),
        company: Optional[str] = Query(None),
        db: Session = Depends(get_db)
):
    """Get all participants with their course progress"""
    try:
        # For basic requests without filters, try cache first
        if skip == 0 and limit == 100 and not email and not company:
            cached_participants = cache_service.get_participants_list()
            if cached_participants:
                logger.info("🚀 Participants list served from cache")
                return cached_participants
            logger.info("👥 Computing participants list from database")
        
        query = db.query(Participant).options(
            joinedload(Participant.courses).joinedload(ParticipantCourse.course)
        )

        # Apply filters
        if email:
            query = query.filter(Participant.email.ilike(f"%{email}%"))
        # Note: company field doesn't exist in our model, so removing this filter
        # if company:
        #     query = query.filter(Participant.company.ilike(f"%{company}%"))

        # Apply pagination
        participants = query.offset(skip).limit(limit).all()

        result = []

        for participant in participants:
            participant_data = ParticipantWithProgress.model_validate(participant)

            # Calculate overall progression and counts
            if participant.courses:
                progressions = [pc.overall_progression for pc in participant.courses if pc.overall_progression is not None]
                participant_data.overall_progression = sum(progressions) / len(progressions) if progressions else 0.0
                participant_data.total_courses = len(participant.courses)

                # Update activity statuses and count them
                completed_courses = 0
                active_courses = 0

                for pc in participant.courses:
                    status = calculate_activity_status(pc, db)
                    pc.activity_status = status  # Update the status
                    if status == 'completed':
                        completed_courses += 1
                    elif status == 'active':
                        active_courses += 1

                participant_data.completed_courses = completed_courses
                participant_data.active_courses = active_courses
                participant_data.courses = [ParticipantCourseSchema.model_validate(pc) for pc in participant.courses]

            result.append(participant_data)

        # Cache the result if it's the default query
        if skip == 0 and limit == 100 and not email and not company:
            cache_service.set_participants_list(result, ttl=300)

        return result

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching participants: {str(e)}")

@router.get("/{participant_id}", response_model=ParticipantWithProgress)
async def get_participant(participant_id: int, db: Session = Depends(get_db)):
    """Get a specific participant with their course progress"""
    try:
        participant = db.query(Participant).options(
            joinedload(Participant.courses).joinedload(ParticipantCourse.course)
        ).filter(Participant.id == participant_id).first()

        if not participant:
            raise HTTPException(status_code=404, detail="Participant not found")

        # Convert to response model with calculated fields
        participant_data = ParticipantWithProgress.model_validate(participant)

        if participant.courses:
            progressions = [pc.overall_progression for pc in participant.courses if pc.overall_progression is not None]
            participant_data.overall_progression = sum(progressions) / len(progressions) if progressions else 0.0
            participant_data.total_courses = len(participant.courses)

            # Update activity statuses and count them
            completed_courses = 0
            active_courses = 0

            for pc in participant.courses:
                status = calculate_activity_status(pc, db)
                pc.activity_status = status  # Update the status
                if status == 'completed':
                    completed_courses += 1
                elif status == 'active':
                    active_courses += 1

            participant_data.completed_courses = completed_courses
            participant_data.active_courses = active_courses
            participant_data.courses = [ParticipantCourseSchema.model_validate(pc) for pc in participant.courses]

        return participant_data

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching participant: {str(e)}")

@router.get("/email/{email}", response_model=ParticipantWithProgress)
async def get_participant_by_email(email: str, db: Session = Depends(get_db)):
    """Get a participant by email"""
    try:
        participant = db.query(Participant).options(
            joinedload(Participant.courses).joinedload(ParticipantCourse.course)
        ).filter(Participant.email == email).first()

        if not participant:
            raise HTTPException(status_code=404, detail="Participant not found")

        # Convert to response model with calculated fields
        participant_data = ParticipantWithProgress.model_validate(participant)

        if participant.courses:
            progressions = [pc.overall_progression for pc in participant.courses if pc.overall_progression is not None]
            participant_data.overall_progression = sum(progressions) / len(progressions) if progressions else 0.0
            participant_data.total_courses = len(participant.courses)

            # Update activity statuses and count them
            completed_courses = 0
            active_courses = 0

            for pc in participant.courses:
                status = calculate_activity_status(pc, db)
                pc.activity_status = status  # Update the status
                if status == 'completed':
                    completed_courses += 1
                elif status == 'active':
                    active_courses += 1

            participant_data.completed_courses = completed_courses
            participant_data.active_courses = active_courses
            participant_data.courses = [ParticipantCourseSchema.model_validate(pc) for pc in participant.courses]

        return participant_data

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching participant: {str(e)}")
