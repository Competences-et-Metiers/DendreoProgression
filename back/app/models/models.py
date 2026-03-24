from sqlalchemy import Column, Integer, String, DateTime, Float, Text, ForeignKey, Boolean, UniqueConstraint, JSON
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from datetime import datetime, timezone

Base = declarative_base()

class Participant(Base):
    __tablename__ = "participants"

    id = Column(Integer, primary_key=True, autoincrement=True)
    id_participant = Column(String, unique=True)  # Dendreo participant ID
    nom = Column(String)
    prenom = Column(String)
    email = Column(String)
    id_entreprise = Column(String, nullable=True)  # Company ID from Dendreo
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    # Relationships
    courses = relationship("ParticipantCourse", back_populates="participant")
    hubspot_data = relationship("ParticipantHubspotData", back_populates="participant")
    interventions = relationship("Intervention", back_populates="participant", foreign_keys="[Intervention.participant_id]")

class ModuleCategory(Base):
    """Module category from Dendreo categories_module API."""
    __tablename__ = "module_categories"

    id = Column(Integer, primary_key=True, autoincrement=True)
    id_categorie_module = Column(String, unique=True, nullable=False)  # Dendreo category ID
    intitule = Column(String, nullable=True)  # Category name
    color = Column(String, nullable=True)  # Hex color code
    status = Column(String, default="1")  # "1" = active
    display_order = Column(Integer, default=0)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))


class Course(Base):
    __tablename__ = "courses"
    __table_args__ = (UniqueConstraint('id_action_formation', 'id_lam', name='_adf_lam_uc'),)

    id = Column(Integer, primary_key=True, autoincrement=True)
    id_action_formation = Column(String)  # ADF ID from Dendreo (removed unique=True)
    id_lam = Column(String)  # LAM ID that groups modules
    intitule = Column(String)  # Course name from ADF
    status = Column(String)  # Based on id_etape_process
    categorie_module_id = Column(String, nullable=True)  # Dendreo category ID from ADF
    total_modules = Column(Integer, default=0)  # Total number of e-learning modules
    planned_duration_hours = Column(Float, default=0.0)  # Planned duration in hours from duree_heures
    formateurs = Column(JSON, nullable=True)  # Array of formateur data from ADF
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    # Relationships
    participants = relationship("ParticipantCourse", back_populates="course")
    modules = relationship("Module", back_populates="course")

class Module(Base):
    __tablename__ = "modules"
    __table_args__ = (UniqueConstraint('id_lmp', 'participant_id', name='_lmp_participant_uc'),)

    id = Column(Integer, primary_key=True, autoincrement=True)
    id_lmp = Column(String)  # Original module ID from Dendreo (removed unique=True)
    id_lam = Column(String)  # LAM ID that links to course
    intitule = Column(String)  # Module title from lmps data
    course_id = Column(Integer, ForeignKey("courses.id"))
    participant_id = Column(Integer, ForeignKey("participants.id"), nullable=False)

    # Module progression data
    lms_progression = Column(Float, default=0.0)
    lms_last_access_at = Column(DateTime(timezone=True), nullable=True)
    mode_organisation = Column(String(50), default='elearning_async')

    # Time tracking data
    lms_time_spent = Column(Integer, default=0)  # Time spent in seconds
    lms_started_at = Column(DateTime(timezone=True), nullable=True)
    lms_completed_at = Column(DateTime(timezone=True), nullable=True)

    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    # Relationships
    course = relationship("Course", back_populates="modules")
    participant = relationship("Participant")

class ParticipantCourse(Base):
    __tablename__ = "participant_courses"

    id = Column(Integer, primary_key=True, autoincrement=True)
    participant_id = Column(Integer, ForeignKey("participants.id"))
    course_id = Column(Integer, ForeignKey("courses.id"))
    id_lap = Column(String, nullable=True)  # Dendreo enrollment ID (LAP)
    date_add = Column(DateTime(timezone=True), nullable=True)  # Date participant was added to ADF from Dendreo

    # Calculated fields
    overall_progression = Column(Float, default=0.0)
    activity_status = Column(String(20), default="inactive")  # active, inactive, completed
    last_activity = Column(DateTime(timezone=True), nullable=True)

    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    # Relationships
    participant = relationship("Participant", back_populates="courses")
    course = relationship("Course", back_populates="participants")

class ParticipantHubspotData(Base):
    __tablename__ = "participant_hubspot_data"
    __table_args__ = (UniqueConstraint('participant_id', 'id_action_formation', name='_participant_adf_uc'),)

    id = Column(Integer, primary_key=True, autoincrement=True)
    participant_id = Column(Integer, ForeignKey("participants.id"), nullable=False)
    id_action_formation = Column(String, nullable=False)  # ADF ID
    id_lap = Column(String, nullable=True)  # LAP ID from laps.php response
    c_url_transaction_hubspot = Column(String, nullable=True)
    c_id_transaction_hubspot = Column(String, nullable=True)
    is_manual_link = Column(Boolean, default=False, nullable=False)  # True = staff-set link, sync won't overwrite
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    # Relationships
    participant = relationship("Participant", back_populates="hubspot_data")

class SyncMetadata(Base):
    __tablename__ = "sync_metadata"

    id = Column(Integer, primary_key=True, autoincrement=True)
    sync_type = Column(String, nullable=False)  # e.g., 'sync_all', 'sync_test'
    last_sync_at = Column(DateTime(timezone=True), nullable=False)
    status = Column(String, nullable=False)  # 'success', 'error', 'in_progress'
    stats = Column(Text, nullable=True)  # JSON string of sync statistics
    error_message = Column(Text, nullable=True)
    api_calls_count = Column(Integer, default=0, nullable=False)  # Total Dendreo API calls during this sync
    hubspot_api_calls_count = Column(Integer, default=0, nullable=False)  # Total HubSpot API calls during this sync
    duration_seconds = Column(Float, nullable=True)  # How long the sync took
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))


class Creneau(Base):
    """Liveroom session (classe virtuelle) from Dendreo creneaux API."""
    __tablename__ = "creneaux"

    id = Column(Integer, primary_key=True, autoincrement=True)
    id_creneau = Column(String, unique=True, nullable=False)  # Dendreo creneau ID
    id_action_formation = Column(String, nullable=False)  # ADF ID
    id_lam = Column(String, nullable=True)  # LAM ID from creneau
    name = Column(String, nullable=True)  # Session name e.g. "Session 01"
    date_debut = Column(DateTime(timezone=True), nullable=True)
    date_fin = Column(DateTime(timezone=True), nullable=True)
    duration = Column(Integer, default=0)  # Duration in seconds
    id_salle_de_formation = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    # Relationships
    participants = relationship("CreneauParticipant", back_populates="creneau")


class CreneauParticipant(Base):
    """Participant attendance record (LCP) for a liveroom session."""
    __tablename__ = "creneau_participants"

    id = Column(Integer, primary_key=True, autoincrement=True)
    id_lcp = Column(String, unique=True, nullable=False)  # Dendreo LCP ID
    id_creneau = Column(String, nullable=False)  # Dendreo creneau ID
    id_lmp = Column(String, nullable=True)  # Module link from LCP
    id_lap = Column(String, nullable=True)  # LAP enrollment link
    id_participant = Column(String, nullable=False)  # Dendreo participant ID
    participant_id = Column(Integer, ForeignKey("participants.id"), nullable=True)  # DB FK
    creneau_id = Column(Integer, ForeignKey("creneaux.id"), nullable=True)  # DB FK
    presence = Column(String(10), default="")  # "0"=absent, "1"=present, ""=unmarked
    heures_presence = Column(Float, default=0.0)
    heures_absence = Column(Float, default=0.0)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    # Relationships
    creneau = relationship("Creneau", back_populates="participants")
    participant = relationship("Participant")


class Intervention(Base):
    """Staff intervention record for participant inactivity tracking."""
    __tablename__ = "interventions"

    id = Column(Integer, primary_key=True, autoincrement=True)
    participant_id = Column(Integer, ForeignKey("participants.id"), nullable=False, index=True)
    participant_course_id = Column(Integer, ForeignKey("participant_courses.id"), nullable=True)
    id_action_formation = Column(String, nullable=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)

    # Type: 'snooze', 'note', 'email', 'call', 'dismiss'
    intervention_type = Column(String(20), nullable=False, index=True)

    # Flexible JSON details per type:
    # snooze: {snooze_days: int, reason: str}
    # note: {text: str}
    # email: {recipient: str}
    # call: {hubspot_contact_url: str}
    # dismiss: {reason: str}
    details = Column(JSON, nullable=True)

    # HubSpot linkage (if a note was pushed to HS)
    hubspot_note_id = Column(String, nullable=True)

    # Snooze tracking (dedicated column for efficient SQL filtering)
    snooze_until = Column(DateTime(timezone=True), nullable=True, index=True)

    # Active flag (for reversing dismissals or cancelling snoozes)
    is_active = Column(Boolean, default=True, nullable=False)

    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    # Relationships
    participant = relationship("Participant", back_populates="interventions")
    participant_course = relationship("ParticipantCourse")
    user = relationship("User")


class User(Base):
    """User model for authentication."""
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, autoincrement=True)
    username = Column(String(50), unique=True, nullable=False, index=True)
    hashed_password = Column(String(255), nullable=True)  # Nullable for Microsoft-only users
    role = Column(String(20), default='user', nullable=False)  # 'admin' or 'user'
    is_active = Column(Boolean, default=True)
    auth_provider = Column(String(20), default='local', nullable=False)  # 'local' or 'microsoft'
    microsoft_id = Column(String(255), unique=True, nullable=True, index=True)  # Azure AD oid
    email = Column(String(255), nullable=True)
    display_name = Column(String(255), nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))


class AdminSyncConfig(Base):
    """Admin configuration for sync scheduling and cooldown (singleton table)."""
    __tablename__ = "admin_sync_config"

    id = Column(Integer, primary_key=True, autoincrement=True)
    cron_enabled = Column(Boolean, default=True, nullable=False)  # Enable/disable scheduled syncs
    cooldown_hours = Column(Float, default=12.0, nullable=False)  # Skip scheduled sync if last sync is newer than this
    schedule_days = Column(String(20), default='0,1,2,3,4', nullable=False)  # Mon=0..Sun=6, comma-separated
    schedule_time = Column(String(5), default='08:00', nullable=False)  # HH:MM when sync should run
    dendreo_api_limit = Column(Integer, nullable=True)  # Max Dendreo API calls per sync (NULL = unlimited)
    hubspot_api_limit = Column(Integer, nullable=True)  # Max HubSpot API calls per sync (NULL = unlimited)
    dendreo_daily_limit = Column(Integer, nullable=True)  # Max Dendreo API calls per day (NULL = unlimited)
    dendreo_weekly_limit = Column(Integer, nullable=True)  # Max Dendreo API calls per week (NULL = unlimited)
    dendreo_monthly_limit = Column(Integer, nullable=True)  # Max Dendreo API calls per month (NULL = unlimited)
    hubspot_daily_limit = Column(Integer, nullable=True)  # Max HubSpot API calls per day (NULL = unlimited)
    hubspot_weekly_limit = Column(Integer, nullable=True)  # Max HubSpot API calls per week (NULL = unlimited)
    hubspot_monthly_limit = Column(Integer, nullable=True)  # Max HubSpot API calls per month (NULL = unlimited)
    last_updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    updated_by_user_id = Column(Integer, ForeignKey('users.id'), nullable=True)  # Who last updated this config

    # Relationship
    updated_by = relationship("User")
