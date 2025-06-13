from pydantic import BaseModel, EmailStr
from datetime import datetime
from typing import Optional, List

# Course schemas
class CourseBase(BaseModel):
    title: str
    description: Optional[str] = None
    course_type: Optional[str] = None
    duration_hours: Optional[float] = 0.0

class CourseCreate(CourseBase):
    dendreo_course_id: str

class Course(CourseBase):
    id: int
    dendreo_course_id: str
    source: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

# Participant schemas
class ParticipantBase(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    email: Optional[EmailStr] = None
    phone: Optional[str] = None
    company: Optional[str] = None

class ParticipantCreate(ParticipantBase):
    dendreo_participant_id: str

class Participant(ParticipantBase):
    id: int
    dendreo_participant_id: str
    source: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

# ParticipantCourse schemas
class ParticipantCourseBase(BaseModel):
    status: Optional[str] = None
    progression: Optional[float] = 0.0
    score: Optional[float] = 0.0
    time_spent_minutes: Optional[int] = 0
    activity_status: Optional[str] = None
    id_lap: Optional[str] = None

class ParticipantCourseCreate(ParticipantCourseBase):
    participant_id: int
    course_id: int
    dendreo_lmp_id: str
    id_lap: Optional[str] = None

class ParticipantCourse(ParticipantCourseBase):
    id: int
    participant_id: int
    course_id: int
    id_lap: Optional[str] = None
    overall_progression: Optional[float] = 0.0
    activity_status: Optional[str] = None
    last_activity: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

    # Include related objects
    participant: Optional[Participant] = None
    course: Optional[Course] = None

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

class CourseWithParticipants(Course):
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
