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
    total_planned_duration_hours: float = 0.0  # E-learning + liveroom planned duration
    total_time_spent_hours: float = 0.0  # E-learning + liveroom time spent

    # Liveroom-specific time tracking
    liveroom_planned_duration_hours: float = 0.0  # Sum of all creneau durations for the ADF
    liveroom_time_spent_hours: float = 0.0  # Sum of creneau durations where participant was present

    # Progression tracking (aggregated)
    current_progression: float = 0.0  # Average progression across all LAMs
    last_activity: Optional[datetime] = None  # Most recent activity across all LAMs
    last_activity_source: Optional[str] = None  # "elearning" or "classe_virtuelle"
    days_inactive: int = 0
    enrollment_date: Optional[datetime] = None  # Earliest enrollment date
    days_since_enrollment: int = 0

    # Upcoming liveroom sessions
    next_session_date: Optional[datetime] = None  # Next upcoming session start date
    upcoming_sessions_count: int = 0  # Number of future planned sessions

    # Inactivity classification
    inactivity_status: str  # 'active', 'at_risk', 'inactive', 'never_started'
    inactivity_reason: str  # Human-readable explanation

    # Formateurs (from course)
    formateurs: Optional[List[dict]] = None

    # Category (from ADF)
    category_name: Optional[str] = None
    category_color: Optional[str] = None

    # Intervention status (populated by inactivity service)
    has_active_snooze: Optional[bool] = False
    snooze_until: Optional[datetime] = None
    is_dismissed: Optional[bool] = False

    class Config:
        from_attributes = True

class InactiveParticipantsByCourse(BaseModel):
    """Grouped inactive participants by course"""
    course_id: int
    course_title: Optional[str] = None
    id_action_formation: Optional[str] = None

    # Category
    category_name: Optional[str] = None
    category_color: Optional[str] = None

    # Aggregated stats
    total_participants: int = 0
    active_count: int = 0
    at_risk_count: int = 0
    inactive_count: int = 0
    never_started_count: int = 0

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
    never_started_count: int = 0
    newly_enrolled_excluded: int = 0

    # Grouped data (optional)
    by_course: Optional[List[InactiveParticipantsByCourse]] = None

    # Flat list (when not grouped)
    participants: Optional[List[InactiveParticipantDetail]] = None

    # Configuration used
    at_risk_threshold_days: int = 14
    inactivity_threshold_days: int = 30
    exclude_recent_enrollments_days: int = 0

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
    role: str
    is_active: bool
    auth_provider: str = 'local'
    email: Optional[str] = None
    display_name: Optional[str] = None
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str


class MessageResponse(BaseModel):
    message: str


class MicrosoftLoginRequest(BaseModel):
    id_token: str


class UserViewCreate(BaseModel):
    name: str
    filter_config: dict


class UserViewResponse(BaseModel):
    id: int
    name: str
    filter_config: dict
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class MicrosoftConfigResponse(BaseModel):
    enabled: bool
    client_id: Optional[str] = None
    tenant_id: Optional[str] = None


class ModuleCategoryResponse(BaseModel):
    id: int
    id_categorie_module: str
    intitule: Optional[str] = None
    color: Optional[str] = None
    status: Optional[str] = None
    display_order: int = 0

    class Config:
        from_attributes = True


# Intervention schemas
class InterventionCreate(BaseModel):
    """Request body for creating an intervention."""
    participant_id: int
    participant_course_id: Optional[int] = None
    id_action_formation: Optional[str] = None
    intervention_type: str  # 'snooze', 'note', 'email', 'call', 'dismiss'
    details: Optional[dict] = None  # Type-specific payload

class InterventionResponse(BaseModel):
    """Single intervention record."""
    id: int
    participant_id: int
    participant_course_id: Optional[int] = None
    id_action_formation: Optional[str] = None
    user_id: int
    user_display_name: Optional[str] = None
    intervention_type: str
    details: Optional[dict] = None
    hubspot_note_id: Optional[str] = None
    snooze_until: Optional[datetime] = None
    is_active: bool = True
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class TimelineEntry(BaseModel):
    """Unified timeline entry merging local interventions + HubSpot data."""
    source: str  # 'local', 'hubspot_note', 'hubspot_call'
    timestamp: Optional[datetime] = None
    # Local intervention fields
    intervention_id: Optional[int] = None
    intervention_type: Optional[str] = None
    user_id: Optional[int] = None
    user_display_name: Optional[str] = None
    details: Optional[dict] = None
    is_active: Optional[bool] = None
    snooze_until: Optional[datetime] = None
    # HubSpot fields
    hubspot_id: Optional[str] = None
    body: Optional[str] = None
    call_duration: Optional[int] = None
    call_direction: Optional[str] = None
    call_recording_url: Optional[str] = None
    hubspot_owner_id: Optional[str] = None
    hubspot_owner_name: Optional[str] = None

class ParticipantTimelineResponse(BaseModel):
    """Full timeline for a participant in a specific ADF context."""
    participant_id: int
    id_action_formation: Optional[str] = None
    entries: List[TimelineEntry] = []
    has_active_snooze: bool = False
    snooze_until: Optional[datetime] = None
    is_dismissed: bool = False


# HubSpot deal linking schemas
class DealInfo(BaseModel):
    id: str
    dealname: str
    amount: Optional[str] = None

class LinkDealRequest(BaseModel):
    participant_id: int
    id_action_formation: str
    deal_id: str

class UnlinkDealRequest(BaseModel):
    participant_id: int
    id_action_formation: str
