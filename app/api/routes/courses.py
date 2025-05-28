from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.models.database import get_db, Course
from app.models.schemas import CourseResponse

router = APIRouter(prefix="/courses", tags=["courses"])

@router.get("/", response_model=List[CourseResponse])
async def get_courses(db: Session = Depends(get_db)):
    """Get all courses"""
    courses = db.query(Course).all()
    return courses

@router.get("/{id_lam}", response_model=CourseResponse)
async def get_course(id_lam: str, db: Session = Depends(get_db)):
    """Get a specific course by ID"""
    course = db.query(Course).filter(Course.id_lam == id_lam).first()
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    return course
