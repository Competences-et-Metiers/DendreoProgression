from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session, joinedload
from typing import List, Optional
from app.models.database import get_db
from app.models.models import Course, ParticipantCourse, Participant
from app.models.schemas import CourseWithParticipants, ParticipantCourse as ParticipantCourseSchema

router = APIRouter()

@router.get("/", response_model=List[CourseWithParticipants])
async def get_courses(
        skip: int = Query(0, ge=0),
        limit: int = Query(100, ge=1, le=1000),
        course_type: Optional[str] = Query(None),
        title: Optional[str] = Query(None),
        db: Session = Depends(get_db)
):
    """Get all courses with their participants"""
    try:
        query = db.query(Course).options(
            joinedload(Course.participant_courses).joinedload(ParticipantCourse.participant)
        )

        # Apply filters
        if course_type:
            query = query.filter(Course.course_type == course_type)
        if title:
            query = query.filter(Course.title.ilike(f"%{title}%"))

        # Apply pagination
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
        raise HTTPException(status_code=500, detail=f"Error fetching courses: {str(e)}")

@router.get("/{course_id}", response_model=CourseWithParticipants)
async def get_course(course_id: int, db: Session = Depends(get_db)):
    """Get a specific course with its participants"""
    try:
        course = db.query(Course).options(
            joinedload(Course.participant_courses).joinedload(ParticipantCourse.participant)
        ).filter(Course.id == course_id).first()

        if not course:
            raise HTTPException(status_code=404, detail="Course not found")

        course_data = CourseWithParticipants.model_validate(course)

        # Calculate statistics
        if course.participant_courses:
            progressions = [pc.progression for pc in course.participant_courses if pc.progression is not None]
            course_data.average_progression = sum(progressions) / len(progressions) if progressions else 0.0
            course_data.total_participants = len(course.participant_courses)
            completed_count = len([pc for pc in course.participant_courses if pc.activity_status == 'completed'])
            course_data.completion_rate = (completed_count / len(course.participant_courses)) * 100 if course.participant_courses else 0.0
            course_data.participants = [ParticipantCourseSchema.model_validate(pc) for pc in course.participant_courses]

        return course_data

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching course: {str(e)}")

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
