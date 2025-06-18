from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List

# Course schemas
class CourseBase(BaseModel):
    intitule: Optional[str] = None
    status: Optional[str] = None

class CourseCreate(CourseBase):
    id_action_formation: str
    id_lam: str

class CourseResponse(CourseBase):
    id: int
    id_action_formation: Optional[str] = None
    id_lam: Optional[str] = None
    intitule: Optional[str] = None
    status: Optional[str] = None
    total_modules: Optional[int] = 0
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True

# Participant schemas
class ParticipantBase(BaseModel):
    nom: Optional[str] = None
    prenom: Optional[str] = None
    email: Optional[str] = None

class ParticipantCreate(ParticipantBase):
    id_participant: str

class Participant(ParticipantBase):
    id: int
    id_participant: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True

# ParticipantCourse schemas
class ParticipantCourseBase(BaseModel):
    overall_progression: Optional[float] = 0.0
    activity_status: Optional[str] = None
    id_lap: Optional[str] = None

class ParticipantCourseCreate(ParticipantCourseBase):
    participant_id: int
    course_id: int
    id_lap: Optional[str] = None

class ParticipantCourse(ParticipantCourseBase):
    id: int
    participant_id: int
    course_id: int
    id_lap: Optional[str] = None
    overall_progression: Optional[float] = 0.0
    activity_status: Optional[str] = None
    last_activity: Optional[datetime] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    # Include related objects
    participant: Optional[Participant] = None
    course: Optional["CourseResponse"] = None

    class Config:
        from_attributes = True

# API response schemas
class ParticipantWithProgress(Participant):
    courses: List[ParticipantCourse] = []
    overall_progression: Optional[float] = 0.0
    total_courses: int = 0
    completed_courses: int = 0
    active_courses: int = 0
    id_lap: Optional[str] = None

class CourseWithParticipants(CourseResponse):
    participants: List[ParticipantCourse] = []
    total_participants: int = 0
    average_progression: float = 0.0
    completion_rate: float = 0.0
    id_lap: Optional[str] = None

# Sync schemas
class SyncResponse(BaseModel):
    status: str
    courses_created: int = 0
    courses_updated: int = 0
    participants_created: int = 0
    participants_updated: int = 0
    participant_courses_created: int = 0
    participant_courses_updated: int = 0
    total_records: int = 0
