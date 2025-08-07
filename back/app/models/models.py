from sqlalchemy import Column, Integer, String, DateTime, Float, Text, ForeignKey, Boolean, UniqueConstraint
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

class Course(Base):
    __tablename__ = "courses"
    __table_args__ = (UniqueConstraint('id_action_formation', 'id_lam', name='_adf_lam_uc'),)

    id = Column(Integer, primary_key=True, autoincrement=True)
    id_action_formation = Column(String)  # ADF ID from Dendreo (removed unique=True)
    id_lam = Column(String)  # LAM ID that groups modules
    intitule = Column(String)  # Course name from ADF
    status = Column(String)  # Based on id_etape_process
    total_modules = Column(Integer, default=0)  # Total number of e-learning modules
    planned_duration_hours = Column(Float, default=0.0)  # Planned duration in hours from duree_heures
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
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
