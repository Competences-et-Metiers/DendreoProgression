from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.models.database import get_db, Participant, ParticipantProgression
from app.models.schemas import ParticipantResponse, ParticipantProgressionResponse

router = APIRouter(prefix="/participants", tags=["participants"])

@router.get("/", response_model=List[ParticipantResponse])
async def get_participants(db: Session = Depends(get_db)):
    """Get all participants"""
    participants = db.query(Participant).all()
    return participants

@router.get("/{email}/progressions", response_model=List[ParticipantProgressionResponse])
async def get_participant_progressions(email: str, db: Session = Depends(get_db)):
    """Get progression data for a specific participant"""
    progressions = db.query(ParticipantProgression).filter(
        ParticipantProgression.participant_email == email
    ).all()

    if not progressions:
        raise HTTPException(status_code=404, detail="No progressions found for this participant")

    return progressions

@router.get("/course/{id_lam}", response_model=List[ParticipantProgressionResponse])
async def get_course_participants(id_lam: str, db: Session = Depends(get_db)):
    """Get all participants and their progression for a specific course"""
    progressions = db.query(ParticipantProgression).filter(
        ParticipantProgression.id_lam == id_lam
    ).all()

    if not progressions:
        raise HTTPException(status_code=404, detail="No participants found for this course")

    return progressions
