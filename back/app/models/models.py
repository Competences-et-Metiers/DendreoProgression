from sqlalchemy import Column, Integer, String, DateTime, Float, Text, ForeignKey, Boolean
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from datetime import datetime

Base = declarative_base()

class Participant(Base):
    __tablename__ = "participants"

    id = Column(Integer, primary_key=True, autoincrement=True)
    id_participant = Column(String, unique=True)  # Dendreo participant ID
    nom = Column(String)
    prenom = Column(String)
    email = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    courses = relationship("ParticipantCourse", back_populates="participant")

class Course(Base):
    __tablename__ = "courses"

    id = Column(Integer, primary_key=True, autoincrement=True)
    id_action_formation = Column(String, unique=True)  # ADF ID from Dendreo
    id_lam = Column(String)  # LAM ID that groups modules
    intitule = Column(String)  # Course name from ADF
    status = Column(String)  # Based on id_etape_process
    mode_organisation = Column(String)
    hubspot_transaction_url = Column(String, nullable=True)
    hubspot_transaction_id = Column(String, nullable=True)
    total_modules = Column(Integer, default=0)  # Total number of e-learning modules
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    participants = relationship("ParticipantCourse", back_populates="course")
    modules = relationship("Module", back_populates="course")

class Module(Base):
    __tablename__ = "modules"

    id = Column(Integer, primary_key=True, autoincrement=True)
    id_lmp = Column(String, unique=True)  # Original module ID from Dendreo
    id_lam = Column(String)  # LAM ID that links to course
    course_id = Column(Integer, ForeignKey("courses.id"))
    participant_id = Column(Integer, ForeignKey("participants.id"), nullable=False)

    # Module progression data
    lms_progression = Column(Float, default=0.0)
    lms_last_access_at = Column(DateTime, nullable=True)
    mode_organisation = Column(String(50), nullable=False)

    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    course = relationship("Course", back_populates="modules")
    participant = relationship("Participant")

class ParticipantCourse(Base):
    __tablename__ = "participant_courses"

    id = Column(Integer, primary_key=True, autoincrement=True)
    participant_id = Column(Integer, ForeignKey("participants.id"))
    course_id = Column(Integer, ForeignKey("courses.id"))

    # Calculated fields
    overall_progression = Column(Float, default=0.0)
    activity_status = Column(String(20), default="inactive")  # active, inactive, completed
    last_activity = Column(DateTime, nullable=True)

    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    participant = relationship("Participant", back_populates="courses")
    course = relationship("Course", back_populates="participants")
