from sqlalchemy import Column, Integer, String, DateTime, Float, Text, ForeignKey, Boolean, UniqueConstraint
from sqlalchemy.orm import relationship
from datetime import datetime
from app.models.database import Base

class Participant(Base):
    __tablename__ = "participants"

    id = Column(Integer, primary_key=True, index=True)
    id_participant = Column(String, unique=True, index=True, nullable=False)
    nom = Column(String, nullable=False)
    prenom = Column(String, nullable=False)
    email = Column(String, nullable=False, index=True)
    portable = Column(String, nullable=True)
    civilite = Column(String, nullable=True)
    adresse = Column(String, nullable=True)
    code_postal = Column(String, nullable=True)
    ville = Column(String, nullable=True)
    pays = Column(String, nullable=True)
    entreprise = Column(String, nullable=True)

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    course_progressions = relationship("CourseProgression", back_populates="participant")
    module_progressions = relationship("ModuleProgression", back_populates="participant")

class Course(Base):
    __tablename__ = "courses"

    id = Column(Integer, primary_key=True, index=True)
    id_lam = Column(String, unique=True, index=True, nullable=False)
    intitule = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    type_lam = Column(String, nullable=True)
    date_debut = Column(DateTime, nullable=True)
    date_fin = Column(DateTime, nullable=True)
    duree_heures = Column(Float, nullable=True)
    prix = Column(Float, nullable=True)
    quantite = Column(Float, nullable=True)

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    modules = relationship("Module", back_populates="course")
    course_progressions = relationship("CourseProgression", back_populates="course")

class Module(Base):
    __tablename__ = "modules"

    id = Column(Integer, primary_key=True, index=True)
    id_module = Column(String, unique=True, index=True, nullable=False)  # Make this unique
    id_lam = Column(String, ForeignKey("courses.id_lam"), nullable=False)
    intitule = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    ordre = Column(Integer, nullable=True)
    duree_heures = Column(Float, nullable=True)
    prix = Column(Float, nullable=True)
    quantite = Column(Float, nullable=True)

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    course = relationship("Course", back_populates="modules")
    module_progressions = relationship("ModuleProgression", back_populates="module")

class ModuleProgression(Base):
    __tablename__ = "module_progressions"

    id = Column(Integer, primary_key=True, index=True)
    id_participant = Column(String, ForeignKey("participants.id_participant"), nullable=False)
    id_module = Column(String, ForeignKey("modules.id_module"), nullable=False)
    progression = Column(Float, default=0.0)
    date_derniere_connexion = Column(DateTime, nullable=True)
    temps_passe_secondes = Column(Integer, default=0)
    is_completed = Column(Boolean, default=False)

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    participant = relationship("Participant", back_populates="module_progressions")
    module = relationship("Module", back_populates="module_progressions")

    # Unique constraint to prevent duplicate progressions for same participant-module
    __table_args__ = (UniqueConstraint('id_participant', 'id_module', name='unique_participant_module'),)

class CourseProgression(Base):
    __tablename__ = "course_progressions"

    id = Column(Integer, primary_key=True, index=True)
    id_participant = Column(String, ForeignKey("participants.id_participant"), nullable=False)
    id_lam = Column(String, ForeignKey("courses.id_lam"), nullable=False)
    progression = Column(Float, default=0.0)
    activity_status = Column(String, default="inactive")  # inactive, active, completed
    last_activity_date = Column(DateTime, nullable=True)

    # HubSpot integration fields
    hubspot_contact_id = Column(String, nullable=True)
    hubspot_transaction_id = Column(String, nullable=True)

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    participant = relationship("Participant", back_populates="course_progressions")
    course = relationship("Course", back_populates="course_progressions")

    # Unique constraint to prevent duplicate progressions for same participant-course
    __table_args__ = (UniqueConstraint('id_participant', 'id_lam', name='unique_participant_course'),)
