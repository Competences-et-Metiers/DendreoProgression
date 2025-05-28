from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime

# Dendreo API Response Models
class DendreoCourse(BaseModel):
    id_lam: str
    id_module: str
    date_debut: str
    date_fin: str
    intitule: str
    lms_progression: Optional[str] = "0.00"

class DendreoParticipant(BaseModel):
    id_participant: str
    nom: str
    prenom: str
    email: str
    c_url_transaction_hubspot: Optional[str] = ""
    c_id_transaction_hubspot: Optional[str] = ""

class DendreoADF(BaseModel):
    id_action_de_formation: str
    intitule: str
    id_etape_process: str
    modules: List[DendreoCourse]
    participants: List[DendreoParticipant]

# Internal API Models
class ParticipantResponse(BaseModel):
    id_participant: str
    nom: str
    prenom: str
    email: str
    url_transac: Optional[str] = None
    id_transac: Optional[str] = None

class CourseResponse(BaseModel):
    id_lam: str
    intitule: str
    etat: str

class ParticipantProgressionResponse(BaseModel):
    course_intitule: str
    participant_nom: str
    participant_prenom: str
    participant_email: str
    progression: float
    id_transac: Optional[str] = None
    url_transac: Optional[str] = None
    id_lam: str

class SyncResponse(BaseModel):
    success: bool
    message: str
    processed_courses: int
    processed_participants: int
    errors: List[str] = []
