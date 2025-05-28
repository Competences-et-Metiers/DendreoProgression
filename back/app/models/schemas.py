from pydantic import BaseModel, EmailStr
from datetime import datetime
from typing import Optional, List
from enum import Enum

class ActivityStatus(str, Enum):
    INACTIVE = "inactive"
    ACTIVE = "active"
    COMPLETED = "completed"

# Base schemas
class ParticipantBase(BaseModel):
    nom: str
    prenom: str
    email: EmailStr
    portable: Optional[str] = None
    civilite: Optional[str] = None
    adresse: Optional[str] = None
    code_postal: Optional[str] = None
    ville: Optional[str] = None
    pays: Optional[str] = None
    entreprise: Optional[str] = None

class ParticipantCreate(ParticipantBase):
    id_participant: str

class ParticipantResponse(ParticipantBase):
    id: int
    id_participant: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

# Course schemas
class CourseBase(BaseModel):
    intitule: str
    description: Optional[str] = None
    type_lam: Optional[str] = None
    date_debut: Optional[datetime] = None
    date_fin: Optional[datetime] = None
    duree_heures: Optional[float] = None
    prix: Optional[float] = None

class CourseCreate(CourseBase):
    id_lam: str

class CourseResponse(CourseBase):
    id: int
    id_lam: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

# Module schemas
class ModuleBase(BaseModel):
    intitule: str
    description: Optional[str] = None
    ordre: Optional[int] = None
    duree_heures: Optional[float] = None

class ModuleCreate(ModuleBase):
    id_module: str
    id_lam: str

class ModuleResponse(ModuleBase):
    id: int
    id_module: str
    id_lam: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

# Progression schemas
class ModuleProgressionBase(BaseModel):
    progression: float = 0.0
    date_derniere_connexion: Optional[datetime] = None
    temps_passe_secondes: int = 0
    is_completed: bool = False

class ModuleProgressionCreate(ModuleProgressionBase):
    id_participant: str
    id_module: str

class ModuleProgressionResponse(ModuleProgressionBase):
    id: int
    id_participant: str
    id_module: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class CourseProgressionBase(BaseModel):
    progression: float = 0.0
    activity_status: ActivityStatus = ActivityStatus.INACTIVE
    last_activity_date: Optional[datetime] = None
    hubspot_contact_id: Optional[str] = None
    hubspot_transaction_id: Optional[str] = None

class CourseProgressionCreate(CourseProgressionBase):
    id_participant: str
    id_lam: str

class CourseProgressionResponse(CourseProgressionBase):
    id: int
    id_participant: str
    id_lam: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

# API Response schemas
class ParticipantProgressResponse(BaseModel):
    course_id: str
    participant_id: str
    progression: float
    activity_status: ActivityStatus
    last_activity_date: Optional[datetime] = None
    course_title: Optional[str] = None

class CourseProgressResponse(BaseModel):
    course_id: str
    course_title: str
    participant_id: str
    participant_name: str
    participant_email: str
    progression: float
    activity_status: ActivityStatus
    last_activity_date: Optional[datetime] = None
    modules: Optional[List[ModuleProgressionResponse]] = None

class SyncResponse(BaseModel):
    status: str
    message: str
    participants_synced: int = 0
    courses_synced: int = 0
    modules_synced: int = 0
    progressions_updated: int = 0
    errors: List[str] = []

class DendreoLMPData(BaseModel):
    """Schema for raw Dendreo LMP data"""
    id_lam: str
    intitule: str
    description: Optional[str] = None
    type_lam: Optional[str] = None
    participants: List[dict] = []
    modules: List[dict] = []
