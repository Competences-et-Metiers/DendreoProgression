from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session, joinedload
from typing import List, Optional
from app.models.database import get_db
from app.models.models import Participant, ParticipantCourse, Course
from app.models.schemas import ParticipantWithProgress, ParticipantCourse as ParticipantCourseSchema

router = APIRouter()

def calculate_activity_status(participant_course: ParticipantCourse) -> str:
    """Simple function to determine activity status"""
    from datetime import datetime

    # Check if completed
    if participant_course.progression and participant_course.progression >= 100.0:
        return "completed"

    if participant_course.completed_at:
        return "completed"

    # Check last access for activity
    if not participant_course.last_access:
        return "not_started"

    days_since_access = (datetime.now() - participant_course.last_access).days

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
        query = db.query(Participant).options(
            joinedload(Participant.participant_courses).joinedload(ParticipantCourse.course)
        )

        # Apply filters
        if email:
            query = query.filter(Participant.email.ilike(f"%{email}%"))
        if company:
            query = query.filter(Participant.company.ilike(f"%{company}%"))

        # Apply pagination
        participants = query.offset(skip).limit(limit).all()

        result = []

        for participant in participants:
            participant_data = ParticipantWithProgress.model_validate(participant)

            # Calculate overall progression and counts
            if participant.participant_courses:
                progressions = [pc.progression for pc in participant.participant_courses if pc.progression is not None]
                participant_data.overall_progression = sum(progressions) / len(progressions) if progressions else 0.0
                participant_data.total_courses = len(participant.participant_courses)

                # Update activity statuses and count them
                completed_courses = 0
                active_courses = 0

                for pc in participant.participant_courses:
                    status = calculate_activity_status(pc)
                    pc.activity_status = status  # Update the status
                    if status == 'completed':
                        completed_courses += 1
                    elif status == 'active':
                        active_courses += 1

                participant_data.completed_courses = completed_courses
                participant_data.active_courses = active_courses
                participant_data.courses = [ParticipantCourseSchema.model_validate(pc) for pc in participant.participant_courses]

            result.append(participant_data)

        return result

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching participants: {str(e)}")

@router.get("/{participant_id}", response_model=ParticipantWithProgress)
async def get_participant(participant_id: int, db: Session = Depends(get_db)):
    """Get a specific participant with their course progress"""
    try:
        participant = db.query(Participant).options(
            joinedload(Participant.participant_courses).joinedload(ParticipantCourse.course)
        ).filter(Participant.id == participant_id).first()

        if not participant:
            raise HTTPException(status_code=404, detail="Participant not found")

        # Convert to response model with calculated fields
        participant_data = ParticipantWithProgress.model_validate(participant)

        if participant.participant_courses:
            progressions = [pc.progression for pc in participant.participant_courses if pc.progression is not None]
            participant_data.overall_progression = sum(progressions) / len(progressions) if progressions else 0.0
            participant_data.total_courses = len(participant.participant_courses)

            # Update activity statuses and count them
            completed_courses = 0
            active_courses = 0

            for pc in participant.participant_courses:
                status = calculate_activity_status(pc)
                pc.activity_status = status  # Update the status
                if status == 'completed':
                    completed_courses += 1
                elif status == 'active':
                    active_courses += 1

            participant_data.completed_courses = completed_courses
            participant_data.active_courses = active_courses
            participant_data.courses = [ParticipantCourseSchema.model_validate(pc) for pc in participant.participant_courses]

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
            joinedload(Participant.participant_courses).joinedload(ParticipantCourse.course)
        ).filter(Participant.email == email).first()

        if not participant:
            raise HTTPException(status_code=404, detail="Participant not found")

        # Convert to response model with calculated fields
        participant_data = ParticipantWithProgress.model_validate(participant)

        if participant.participant_courses:
            progressions = [pc.progression for pc in participant.participant_courses if pc.progression is not None]
            participant_data.overall_progression = sum(progressions) / len(progressions) if progressions else 0.0
            participant_data.total_courses = len(participant.participant_courses)

            # Update activity statuses and count them
            completed_courses = 0
            active_courses = 0

            for pc in participant.participant_courses:
                status = calculate_activity_status(pc)
                pc.activity_status = status  # Update the status
                if status == 'completed':
                    completed_courses += 1
                elif status == 'active':
                    active_courses += 1

            participant_data.completed_courses = completed_courses
            participant_data.active_courses = active_courses
            participant_data.courses = [ParticipantCourseSchema.model_validate(pc) for pc in participant.participant_courses]

        return participant_data

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching participant: {str(e)}")
