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
    formateurs: Optional[List[dict]] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True

# Participant schemas
class ParticipantBase(BaseModel):
    nom: Optional[str] = None
    prenom: Optional[str] = None
    email: Optional[str] = None
    id_entreprise: Optional[str] = None

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
    date_add: Optional[datetime] = None
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

# Inactivity tracking schemas
class InactiveParticipantDetail(BaseModel):
    """Detailed information about an inactive participant"""
    id: int
    id_participant: Optional[str] = None
    nom: Optional[str] = None
    prenom: Optional[str] = None
    email: Optional[str] = None

    # ADF-level inactivity details (aggregated across all LAMs)
    course_id: Optional[int] = None  # Optional: first course_id in the group for reference
    course_title: Optional[str] = None
    id_action_formation: Optional[str] = None

    # Aggregated fields (across all LAMs in the ADF)
    total_modules: int = 0  # Number of LAMs in this ADF
    total_planned_duration_hours: float = 0.0  # Sum of all LAM durations
    total_time_spent_hours: float = 0.0  # Sum of actual time spent across all modules

    # Progression tracking (aggregated)
    current_progression: float = 0.0  # Average progression across all LAMs
    last_activity: Optional[datetime] = None  # Most recent activity across all LAMs
    days_inactive: int = 0
    enrollment_date: Optional[datetime] = None  # Earliest enrollment date
    days_since_enrollment: int = 0

    # Inactivity classification
    inactivity_status: str  # 'active', 'at_risk', 'inactive'
    inactivity_reason: str  # Human-readable explanation

    # Formateurs (from course)
    formateurs: Optional[List[dict]] = None

    class Config:
        from_attributes = True

class InactiveParticipantsByCourse(BaseModel):
    """Grouped inactive participants by course"""
    course_id: int
    course_title: Optional[str] = None
    id_action_formation: Optional[str] = None

    # Aggregated stats
    total_participants: int = 0
    active_count: int = 0
    at_risk_count: int = 0
    inactive_count: int = 0

    # Inactive participants in this course
    participants: List[InactiveParticipantDetail] = []

    class Config:
        from_attributes = True

class InactivitySummary(BaseModel):
    """Overall inactivity summary with optional course grouping"""
    total_participants_checked: int = 0
    total_participants: int = 0

    # Breakdown by status
    active_count: int = 0
    at_risk_count: int = 0
    inactive_count: int = 0
    newly_enrolled_excluded: int = 0

    # Grouped data (optional)
    by_course: Optional[List[InactiveParticipantsByCourse]] = None

    # Flat list (when not grouped)
    participants: Optional[List[InactiveParticipantDetail]] = None

    # Configuration used
    at_risk_threshold_days: int = 14
    inactivity_threshold_days: int = 30
    exclude_recent_enrollments_days: int = 7

    class Config:
        from_attributes = True

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


# Auth schemas
class LoginRequest(BaseModel):
    username: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class UserResponse(BaseModel):
    id: int
    username: str
    is_active: bool
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str


class MessageResponse(BaseModel):
    message: str
