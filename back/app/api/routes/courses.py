from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.models.database import get_db
from app.models.models import Course, CourseProgression

router = APIRouter()

@router.get("/")
async def get_all_courses(db: Session = Depends(get_db)):
    """Get all courses"""
    try:
        courses = db.query(Course).all()
        return [
            {
                "id_lam": course.id_lam,
                "intitule": course.intitule,
                "description": course.description,
                "type_lam": course.type_lam,
                "date_debut": course.date_debut,
                "date_fin": course.date_fin
            }
            for course in courses
        ]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching courses: {str(e)}")

@router.get("/{course_id}")
async def get_course(course_id: str, db: Session = Depends(get_db)):
    """Get a specific course"""
    try:
        course = db.query(Course).filter(Course.id_lam == course_id).first()

        if not course:
            raise HTTPException(status_code=404, detail="Course not found")

        return {
            "id_lam": course.id_lam,
            "intitule": course.intitule,
            "description": course.description,
            "type_lam": course.type_lam,
            "date_debut": course.date_debut,
            "date_fin": course.date_fin,
            "duree_heures": course.duree_heures,
            "prix": course.prix
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching course: {str(e)}")

@router.get("/{course_id}/participants")
async def get_course_participants(course_id: str, db: Session = Depends(get_db)):
    """Get all participants for a specific course"""
    try:
        progressions = db.query(CourseProgression).filter(
            CourseProgression.id_lam == course_id
        ).all()

        return [
            {
                "participant_id": prog.id_participant,
                "progression": prog.progression,
                "activity_status": prog.activity_status,
                "last_activity_date": prog.last_activity_date
            }
            for prog in progressions
        ]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching course participants: {str(e)}")
