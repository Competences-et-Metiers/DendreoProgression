from sqlalchemy import create_engine, Column, Integer, String, Float, DateTime, Text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from app.config.settings import settings
import logging

logger = logging.getLogger(__name__)

engine = create_engine(settings.database_url)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

class Participant(Base):
    __tablename__ = "participants"

    id_participant = Column(String, primary_key=True, index=True)
    nom = Column(String, nullable=False)
    prenom = Column(String, nullable=False)
    email = Column(String, nullable=False, index=True)
    url_transac = Column(String)
    id_transac = Column(String)
    id_lam = Column(String)

class Course(Base):
    __tablename__ = "courses"

    id_lam = Column(String, primary_key=True, index=True)
    intitule = Column(String, nullable=False)
    etat = Column(String, nullable=False)

class ParticipantProgression(Base):
    __tablename__ = "participant_progressions"

    id = Column(Integer, primary_key=True, autoincrement=True)
    course_intitule = Column(String, nullable=False)
    participant_nom = Column(String, nullable=False)
    participant_prenom = Column(String, nullable=False)
    participant_email = Column(String, nullable=False, index=True)
    progression = Column(Float, default=0.0)
    id_transac = Column(String)
    url_transac = Column(String)
    id_lam = Column(String, index=True)

def get_db() -> Session:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def create_tables():
    """Create all tables in the database."""
    Base.metadata.create_all(bind=engine)
    logger.info("Database tables created successfully")
