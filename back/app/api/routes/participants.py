from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.models.database import get_db
from app.models.models import Participant, CourseProgression

router = APIRouter()

@router.get("/")
async def get_all_participants(db: Session = Depends(get_db)):
    """Get all participants"""
    try:
        participants = db.query(Participant).all()

        return [
            {
                "id_participant": p.id_participant,
                "nom": p.nom,
                "prenom": p.prenom,
                "email": p.email,
                "entreprise": p.entreprise
            }
            for p in participants
        ]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching participants: {str(e)}")

@router.get("/{participant_id}")
async def get_participant(participant_id: str, db: Session = Depends(get_db)):
    """Get a specific participant"""
    try:
        participant = db.query(Participant).filter(
            Participant.id_participant == participant_id
        ).first()

        if not participant:
            raise HTTPException(status_code=404, detail="Participant not found")

        return {
            "id_participant": participant.id_participant,
            "nom": participant.nom,
            "prenom": participant.prenom,
            "email": participant.email,
            "portable": participant.portable,
            "entreprise": participant.entreprise,
            "created_at": participant.created_at
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching participant: {str(e)}")

@router.get("/{participant_id}/progress")
async def get_participant_progress(participant_id: str, db: Session = Depends(get_db)):
    """Get progression data for a specific participant"""
    try:
        progressions = db.query(CourseProgression).filter(
            CourseProgression.id_participant == participant_id
        ).all()

        return [
            {
                "course_id": prog.id_lam,
                "participant_id": prog.id_participant,
                "progression": prog.progression,
                "activity_status": prog.activity_status,
                "last_activity_date": prog.last_activity_date
            }
            for prog in progressions
        ]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching participant progress: {str(e)}")
