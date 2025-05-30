from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session, joinedload
from typing import List, Optional
from app.models.database import get_db
from app.models.models import Course, ParticipantCourse, Participant, Module
from app.models.schemas import CourseWithParticipants, ParticipantCourse as ParticipantCourseSchema
from app.schemas.course import CourseResponse, ModuleResponse
from sqlalchemy import func

router = APIRouter()

@router.get("/", response_model=List[CourseResponse])
async def get_courses(db: Session = Depends(get_db)):
    """Get all courses with their modules grouped by ADF"""
    courses = db.query(Course).all()
    
    # Enhance courses with aggregated module data
    for course in courses:
        # Calculate average progression across all modules
        avg_progression = db.query(func.avg(Module.progression)).filter(
            Module.course_id == course.id
        ).scalar() or 0.0
        
        # Get last access time across all modules
        last_access = db.query(func.max(Module.last_access_at)).filter(
            Module.course_id == course.id
        ).scalar()
        
        # Add computed fields
        course.progression = float(avg_progression)
        course.last_access_at = last_access
    
    return courses

@router.get("/{course_id}", response_model=CourseResponse)
async def get_course(course_id: int, db: Session = Depends(get_db)):
    """Get a specific course with its modules"""
    course = db.query(Course).filter(Course.id == course_id).first()
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    
    # Calculate average progression
    avg_progression = db.query(func.avg(Module.progression)).filter(
        Module.course_id == course.id
    ).scalar() or 0.0
    
    # Get last access time
    last_access = db.query(func.max(Module.last_access_at)).filter(
        Module.course_id == course.id
    ).scalar()
    
    # Add computed fields
    course.progression = float(avg_progression)
    course.last_access_at = last_access
    
    return course

@router.get("/{course_id}/modules", response_model=List[ModuleResponse])
async def get_course_modules(course_id: int, db: Session = Depends(get_db)):
    """Get all modules for a specific course"""
    course = db.query(Course).filter(Course.id == course_id).first()
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    
    return course.modules

@router.get("/elearning/", response_model=List[CourseWithParticipants])
async def get_elearning_courses(
        skip: int = Query(0, ge=0),
        limit: int = Query(100, ge=1, le=1000),
        db: Session = Depends(get_db)
):
    """Get only e-learning courses"""
    try:
        query = db.query(Course).options(
            joinedload(Course.participant_courses).joinedload(ParticipantCourse.participant)
        ).filter(Course.course_type == 'e-learning')

        courses = query.offset(skip).limit(limit).all()

        result = []
        for course in courses:
            course_data = CourseWithParticipants.model_validate(course)

            # Calculate statistics
            if course.participant_courses:
                progressions = [pc.progression for pc in course.participant_courses if pc.progression is not None]
                course_data.average_progression = sum(progressions) / len(progressions) if progressions else 0.0
                course_data.total_participants = len(course.participant_courses)
                completed_count = len([pc for pc in course.participant_courses if pc.activity_status == 'completed'])
                course_data.completion_rate = (completed_count / len(course.participant_courses)) * 100 if course.participant_courses else 0.0
                course_data.participants = [ParticipantCourseSchema.model_validate(pc) for pc in course.participant_courses]

            result.append(course_data)

        return result

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching e-learning courses: {str(e)}")
