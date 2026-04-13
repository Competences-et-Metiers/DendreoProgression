from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session, joinedload
from typing import List, Optional, Dict, Any
from app.models.database import get_db
from app.models.models import Course, ParticipantCourse, Participant, Module, ParticipantHubspotData, Creneau, CreneauParticipant, ModuleCategory, Intervention
from datetime import datetime, timezone
from app.models.schemas import CourseWithParticipants, ParticipantCourse as ParticipantCourseSchema
from app.schemas.course import CourseResponse, ModuleResponse
from app.services.cache_service import cache_service
from sqlalchemy import func
import logging

logger = logging.getLogger(__name__)
router = APIRouter()

def _get_last_liveroom_date(db: Session, participant_id: int, adf_id: str):
    """Get the most recent attended liveroom date_fin for a participant in an ADF."""
    now = datetime.now(timezone.utc)
    result = (
        db.query(Creneau.date_fin)
        .join(CreneauParticipant, CreneauParticipant.creneau_id == Creneau.id)
        .filter(
            Creneau.id_action_formation == adf_id,
            CreneauParticipant.participant_id == participant_id,
            CreneauParticipant.presence == "1",
            Creneau.date_fin <= now
        )
        .order_by(Creneau.date_fin.desc())
        .first()
    )
    return result[0] if result else None

def _get_upcoming_sessions(db: Session, participant_id: int, adf_id: str):
    """Get count and next date of upcoming liveroom sessions for a participant in an ADF."""
    now = datetime.now(timezone.utc)
    from sqlalchemy import func as sa_func
    result = (
        db.query(
            sa_func.count(Creneau.id),
            sa_func.min(Creneau.date_debut)
        )
        .join(CreneauParticipant, CreneauParticipant.creneau_id == Creneau.id)
        .filter(
            Creneau.id_action_formation == adf_id,
            CreneauParticipant.participant_id == participant_id,
            Creneau.date_debut > now
        )
        .first()
    )
    if result and result[0]:
        return result[0], result[1]
    return 0, None

def _resolve_last_activity(last_elearning, last_liveroom):
    """Return (last_activity_datetime, source_string) from the most recent of both."""
    if last_elearning and last_liveroom:
        if last_elearning >= last_liveroom:
            return last_elearning, "elearning"
        return last_liveroom, "classe_virtuelle"
    if last_elearning:
        return last_elearning, "elearning"
    if last_liveroom:
        return last_liveroom, "classe_virtuelle"
    return None, None


def _get_liveroom_time_spent(db: Session, participant_id: int, adf_id: str) -> int:
    """Get total liveroom time spent (seconds) for a participant in an ADF.
    Sums duration of all attended creneaux (presence == '1')."""
    rows = (
        db.query(Creneau.duration)
        .join(CreneauParticipant, CreneauParticipant.creneau_id == Creneau.id)
        .filter(
            Creneau.id_action_formation == adf_id,
            CreneauParticipant.participant_id == participant_id,
            CreneauParticipant.presence == "1"
        )
        .all()
    )
    return sum(r.duration or 0 for r in rows)


def _get_liveroom_total_duration(db: Session, adf_id: str) -> int:
    """Get total planned liveroom duration (seconds) for an ADF from all creneaux."""
    rows = db.query(Creneau.duration).filter(Creneau.id_action_formation == adf_id).all()
    return sum(r.duration or 0 for r in rows)


def _get_liveroom_progression(db: Session, participant_id: int, adf_id: str, id_lam: str) -> Optional[float]:
    """Compute liveroom progression for a module: (attended sessions / total sessions) * 100.
    Returns None if there are no creneaux for this module."""
    creneaux = (
        db.query(Creneau.id)
        .filter(
            Creneau.id_action_formation == adf_id,
            Creneau.id_lam == id_lam
        )
        .all()
    )
    total = len(creneaux)
    if total == 0:
        return None

    creneau_ids = [c.id for c in creneaux]
    attended = db.query(CreneauParticipant).filter(
        CreneauParticipant.creneau_id.in_(creneau_ids),
        CreneauParticipant.participant_id == participant_id,
        CreneauParticipant.presence == "1"
    ).count()

    return round((attended / total) * 100, 2)


@router.get("/stats")
async def get_dashboard_stats(db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Get overall dashboard statistics"""
    try:
        # Try to get from cache first
        cached_stats = cache_service.get_dashboard_stats()
        if cached_stats:
            logger.info("🚀 Dashboard stats served from cache")
            return cached_stats
        
        logger.info("📊 Computing dashboard stats from database")
        total_courses = db.query(Course).count()
        total_participants = db.query(Participant).count()
        total_modules = db.query(Module).count()
        total_participant_courses = db.query(ParticipantCourse).count()
        
        # Average progression across all participant courses
        avg_progression = db.query(func.avg(ParticipantCourse.overall_progression)).scalar() or 0
        
        # Count completed courses (progression >= 100)
        completed_courses = db.query(ParticipantCourse).filter(
            ParticipantCourse.overall_progression >= 100
        ).count()
        
        stats = {
            "total_courses": total_courses,
            "total_participants": total_participants,
            "total_modules": total_modules,
            "total_enrollments": total_participant_courses,
            "completed_enrollments": completed_courses,
            "average_progression": round(float(avg_progression), 2),
            "completion_rate": round((completed_courses / total_participant_courses * 100), 2) if total_participant_courses > 0 else 0
        }
        
        # Cache the result for 5 minutes
        cache_service.set_dashboard_stats(stats, ttl=300)
        
        return stats
        
    except Exception as e:
        logger.error(f"Error fetching dashboard stats: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch dashboard stats: {str(e)}")

@router.get("/courses")
async def get_all_courses(db: Session = Depends(get_db)) -> List[Dict[str, Any]]:
    """Get all ADFs with their participants and e-learning module count"""
    try:
        # Try to get from cache first
        cached_courses = cache_service.get_courses_list()
        if cached_courses:
            logger.info("🚀 Courses list served from cache")
            return cached_courses
        
        logger.info("📚 Computing courses list from database")
        # Group courses by ADF (id_action_formation)
        # Each ADF should appear only once, regardless of how many modules (id_lam) it contains
        adfs = db.query(Course.id_action_formation).distinct().all()
        
        result = []
        for (id_adf,) in adfs:
            # Get the first course record for this ADF to get basic info
            adf_course = db.query(Course).filter(Course.id_action_formation == id_adf).first()
            if not adf_course:
                continue
            
            # Get all participants in this ADF (distinct to avoid duplicates)
            participants_query = db.query(ParticipantCourse).join(Course).join(Participant).filter(
                Course.id_action_formation == id_adf
            ).distinct(ParticipantCourse.participant_id).all()
            
            # Use the deduplicated participant count
            participant_count = len(participants_query)
            
            # Count all modules for this ADF by matching id_lam (since course_id FK may not be set)
            adf_lam_ids = db.query(Course.id_lam).filter(
                Course.id_action_formation == id_adf
            ).distinct().all()

            if adf_lam_ids:
                lam_ids_list = [lam_id[0] for lam_id in adf_lam_ids if lam_id[0]]
                module_count = db.query(Module.id_lam).filter(
                    Module.id_lam.in_(lam_ids_list)
                ).distinct().count()
            else:
                module_count = 0

            # Skip if no modules at all (empty courses)
            if module_count == 0:
                continue
            
            participants_data = []
            for pc in participants_query:
                participant = pc.participant
                
                # Get modules for this participant in this ADF to calculate real progression
                # Join by id_lam instead of course_id FK
                adf_lam_ids_for_participant = db.query(Course.id_lam).filter(
                    Course.id_action_formation == id_adf
                ).distinct().all()
                
                if adf_lam_ids_for_participant:
                    lam_ids_for_participant = [lam_id[0] for lam_id in adf_lam_ids_for_participant if lam_id[0]]
                    participant_modules = db.query(Module).filter(
                        Module.id_lam.in_(lam_ids_for_participant),
                        Module.participant_id == participant.id
                    ).all()
                else:
                    participant_modules = []
                
                # Calculate real progression: average of all module progressions
                if participant_modules:
                    total_progression = sum(module.lms_progression for module in participant_modules)
                    calculated_progression = total_progression / len(participant_modules)
                else:
                    calculated_progression = 0.0
                
                # Get HubSpot data for this participant and ADF
                hubspot_data = db.query(ParticipantHubspotData).filter(
                    ParticipantHubspotData.participant_id == participant.id,
                    ParticipantHubspotData.id_action_formation == id_adf
                ).first()
                
                participants_data.append({
                    "id": participant.id,
                    "id_participant": participant.id_participant,
                    "nom": participant.nom,
                    "prenom": participant.prenom,
                    "email": participant.email,
                    "id_entreprise": participant.id_entreprise,
                    "overall_progression": round(calculated_progression, 2),
                    "activity_status": pc.activity_status,
                    "total_time_spent": sum(module.lms_time_spent for module in participant_modules if module.lms_time_spent),
                    "hubspot_data": {
                        "c_url_transaction_hubspot": hubspot_data.c_url_transaction_hubspot if hubspot_data else None,
                        "c_id_transaction_hubspot": hubspot_data.c_id_transaction_hubspot if hubspot_data else None,
                        "id_lap": hubspot_data.id_lap if hubspot_data else None
                    } if hubspot_data else None
                })
            
            # Calculate average progression across all participants in this ADF using real module data
            if participants_data:
                total_progression = sum(p["overall_progression"] for p in participants_data)
                avg_progression = total_progression / len(participants_data)
            else:
                avg_progression = 0
            
            result.append({
                "id": adf_course.id,
                "id_action_formation": id_adf,
                "intitule": adf_course.intitule,
                "status": adf_course.status,
                "total_modules": module_count,
                "planned_duration_hours": adf_course.planned_duration_hours,
                "participant_count": participant_count,
                "participants": participants_data,
                "average_progression": round(float(avg_progression), 2),
                "created_at": adf_course.created_at.isoformat() if adf_course.created_at else None,
                "updated_at": adf_course.updated_at.isoformat() if adf_course.updated_at else None
            })
        
        # Cache the result for 10 minutes
        cache_service.set_courses_list(result, ttl=600)
        
        return result
        
    except Exception as e:
        logger.error(f"Error fetching courses: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch courses: {str(e)}")

@router.get("/courses/{course_id}/time-stats")
async def get_course_time_stats(course_id: int, db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Get time spent statistics for a specific course"""
    try:
        # Get course info
        course = db.query(Course).filter(Course.id == course_id).first()
        if not course:
            raise HTTPException(status_code=404, detail="Course not found")
        
        # Get all modules for this course with time data
        modules = db.query(Module).filter(
            Module.course_id == course_id
        ).all()
        
        # Calculate time statistics
        total_time_spent = sum(module.lms_time_spent for module in modules if module.lms_time_spent)
        avg_time_spent = total_time_spent / len(modules) if modules else 0
        
        # Get participant time data - aggregate by participant
        participant_data = {}
        for module in modules:
            if module.participant:
                participant_id = module.participant.id
                if participant_id not in participant_data:
                    participant_data[participant_id] = {
                        "participant_id": participant_id,
                        "participant_name": f"{module.participant.prenom} {module.participant.nom}",
                        "participant_email": module.participant.email,
                        "total_time_spent": 0,
                        "total_progression": 0,
                        "modules_count": 0,
                        "earliest_started_at": None,
                        "latest_completed_at": None,
                        "modules": []
                    }
                
                # Add module time to participant total
                participant_data[participant_id]["total_time_spent"] += module.lms_time_spent or 0
                participant_data[participant_id]["total_progression"] += module.lms_progression or 0
                participant_data[participant_id]["modules_count"] += 1
                
                # Track earliest start and latest completion
                if module.lms_started_at:
                    if not participant_data[participant_id]["earliest_started_at"] or module.lms_started_at < participant_data[participant_id]["earliest_started_at"]:
                        participant_data[participant_id]["earliest_started_at"] = module.lms_started_at
                
                if module.lms_completed_at:
                    if not participant_data[participant_id]["latest_completed_at"] or module.lms_completed_at > participant_data[participant_id]["latest_completed_at"]:
                        participant_data[participant_id]["latest_completed_at"] = module.lms_completed_at
                
                # Add module details
                participant_data[participant_id]["modules"].append({
                    "module_id": module.id,
                    "module_title": module.intitule,
                    "time_spent": module.lms_time_spent or 0,
                    "progression": module.lms_progression or 0,
                    "started_at": module.lms_started_at.isoformat() if module.lms_started_at else None,
                    "completed_at": module.lms_completed_at.isoformat() if module.lms_completed_at else None
                })
        
        # Convert to list and calculate averages
        participant_time_data = []
        for data in participant_data.values():
            avg_progression = data["total_progression"] / data["modules_count"] if data["modules_count"] > 0 else 0
            participant_time_data.append({
                "participant_id": data["participant_id"],
                "participant_name": data["participant_name"],
                "participant_email": data["participant_email"],
                "total_time_spent": data["total_time_spent"],
                "average_progression": round(avg_progression, 2),
                "modules_count": data["modules_count"],
                "started_at": data["earliest_started_at"].isoformat() if data["earliest_started_at"] else None,
                "completed_at": data["latest_completed_at"].isoformat() if data["latest_completed_at"] else None,
                "modules": data["modules"]
            })
        
        # Sort by total time spent (descending)
        participant_time_data.sort(key=lambda x: x["total_time_spent"], reverse=True)
        
        return {
            "course": {
                "id": course.id,
                "id_action_formation": course.id_action_formation,
                "intitule": course.intitule,
                "status": course.status
            },
            "time_statistics": {
                "total_modules": len(modules),
                "total_time_spent": total_time_spent,
                "average_time_spent": round(avg_time_spent, 2),
                "participants_with_time_data": len([m for m in modules if m.lms_time_spent > 0])
            },
            "participant_time_data": participant_time_data
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching course time stats: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch course time stats: {str(e)}")

@router.get("/courses/{course_id}/participants")
async def get_course_participants(course_id: int, db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Get all participants for a specific course with their progression"""
    try:
        # Get course info
        course = db.query(Course).filter(Course.id == course_id).first()
        if not course:
            raise HTTPException(status_code=404, detail="Course not found")
        
        # Get participant courses for this ADF (not just this specific course)
        # Use distinct to avoid duplicates when the same participant appears multiple times
        participant_courses = db.query(ParticipantCourse).join(Course).filter(
            Course.id_action_formation == course.id_action_formation
        ).distinct(ParticipantCourse.participant_id).all()
        
        participants_data = []
        seen_participants = set()  # Track participants we've already processed
        
        for pc in participant_courses:
            # Skip if we've already processed this participant
            if pc.participant_id in seen_participants:
                continue
            seen_participants.add(pc.participant_id)
            
            participant = db.query(Participant).filter(Participant.id == pc.participant_id).first()
            if not participant:
                continue
            
            # Get modules for this participant in this ADF (not just this course)
            # Join by id_lam instead of course_id FK
            adf_lam_ids_modules = db.query(Course.id_lam).filter(
                Course.id_action_formation == course.id_action_formation
            ).distinct().all()
            
            if adf_lam_ids_modules:
                lam_ids_modules = [lam_id[0] for lam_id in adf_lam_ids_modules if lam_id[0]]
                modules = db.query(Module).filter(
                    Module.id_lam.in_(lam_ids_modules),
                    Module.participant_id == participant.id
                ).all()
                # Build date lookup from Course by id_lam
                course_dates = {c.id_lam: c for c in db.query(Course).filter(
                    Course.id_action_formation == course.id_action_formation,
                    Course.id_lam.in_(lam_ids_modules)
                ).all()}
            else:
                modules = []
                course_dates = {}
            
            # Build module data with liveroom-based progression for sync/mixte modules
            modules_data = []
            for module in modules:
                mode = module.mode_organisation or ''
                if mode in ('elearning_sync', 'mixte'):
                    liveroom_prog = _get_liveroom_progression(db, participant.id, course.id_action_formation, module.id_lam)
                    progression = liveroom_prog if liveroom_prog is not None else 0.0
                else:
                    progression = module.lms_progression

                c_ref = course_dates.get(module.id_lam, course)
                modules_data.append({
                    "id": module.id,
                    "id_lmp": module.id_lmp,
                    "id_lam": module.id_lam,
                    "intitule": module.intitule,
                    "progression": progression,
                    "last_access": module.lms_last_access_at.isoformat() if module.lms_last_access_at else None,
                    "mode_organisation": mode,
                    "time_spent": module.lms_time_spent,
                    "started_at": module.lms_started_at.isoformat() if module.lms_started_at else None,
                    "completed_at": module.lms_completed_at.isoformat() if module.lms_completed_at else None,
                    "date_debut": c_ref.date_debut.isoformat() if c_ref.date_debut else None,
                    "date_fin": c_ref.date_fin.isoformat() if c_ref.date_fin else None
                })
            modules_data.sort(key=lambda m: m["date_debut"] or "9999")

            # Calculate progression from resolved module progressions
            if modules_data:
                calculated_progression = sum(m["progression"] for m in modules_data) / len(modules_data)
            else:
                calculated_progression = 0.0

            # Calculate completed modules (progression >= 100)
            completed_modules = sum(1 for m in modules_data if m["progression"] >= 100)
            total_modules = len(modules_data)

            # Calculate total time spent: e-learning + liveroom attended
            elearning_time_spent = sum(module.lms_time_spent or 0 for module in modules)
            lr_spent = _get_liveroom_time_spent(db, participant.id, course.id_action_formation)
            total_time_spent = elearning_time_spent + lr_spent

            # Get earliest start and latest completion dates
            earliest_started_at = None
            latest_completed_at = None
            if modules:
                start_dates = [m.lms_started_at for m in modules if m.lms_started_at]
                completion_dates = [m.lms_completed_at for m in modules if m.lms_completed_at]
                if start_dates:
                    earliest_started_at = min(start_dates).isoformat()
                if completion_dates:
                    latest_completed_at = max(completion_dates).isoformat()

            # Get last activity from e-learning modules
            last_elearning = None
            if modules:
                elearning_dates = [m.lms_last_access_at for m in modules if m.lms_last_access_at]
                if elearning_dates:
                    last_elearning = max(elearning_dates)

            # Get last liveroom attendance
            last_liveroom = _get_last_liveroom_date(db, participant.id, course.id_action_formation)
            last_activity, last_activity_source = _resolve_last_activity(last_elearning, last_liveroom)

            # Get upcoming sessions
            upcoming_count, next_session_date = _get_upcoming_sessions(db, participant.id, course.id_action_formation)

            # Get HubSpot data for this participant and ADF
            hubspot_data = db.query(ParticipantHubspotData).filter(
                ParticipantHubspotData.participant_id == participant.id,
                ParticipantHubspotData.id_action_formation == course.id_action_formation
            ).first()

            participants_data.append({
                "id": participant.id,
                "id_participant": participant.id_participant,
                "nom": participant.nom,
                "prenom": participant.prenom,
                "email": participant.email,
                "id_entreprise": participant.id_entreprise,
                "overall_progression": round(calculated_progression, 2),
                "activity_status": pc.activity_status,
                "date_add": pc.date_add.isoformat() if pc.date_add else None,
                "last_activity": last_activity.isoformat() if last_activity else None,
                "last_activity_source": last_activity_source,
                "upcoming_sessions_count": upcoming_count,
                "next_session_date": next_session_date.isoformat() if next_session_date else None,
                "completed_modules": completed_modules,
                "total_modules": total_modules,
                "total_time_spent": total_time_spent,
                "started_at": earliest_started_at,
                "completed_at": latest_completed_at,
                "hubspot_data": {
                    "c_url_transaction_hubspot": hubspot_data.c_url_transaction_hubspot if hubspot_data else None,
                    "c_id_transaction_hubspot": hubspot_data.c_id_transaction_hubspot if hubspot_data else None,
                    "id_lap": hubspot_data.id_lap if hubspot_data else None
                } if hubspot_data else None,
                "modules": modules_data
            })

        # Sort participants by progression (descending)
        participants_data.sort(key=lambda x: x["overall_progression"], reverse=True)
        
        return {
            "course": {
                "id": course.id,
                "id_action_formation": course.id_action_formation,
                "id_lam": course.id_lam,
                "intitule": course.intitule,
                "status": course.status,
                "planned_duration_hours": (course.planned_duration_hours or 0) + (_get_liveroom_total_duration(db, course.id_action_formation) / 3600.0),
                "total_modules": db.query(Module.id_lam).filter(
                    Module.id_lam.in_([lam_id[0] for lam_id in db.query(Course.id_lam).filter(
                        Course.id_action_formation == course.id_action_formation
                    ).distinct().all() if lam_id[0]])
                ).distinct().count() if db.query(Course.id_lam).filter(
                    Course.id_action_formation == course.id_action_formation
                ).distinct().all() else 0
            },
            "participants": participants_data,
            "summary": {
                "total_participants": len(participants_data),
                "completed_participants": sum(1 for p in participants_data if p["overall_progression"] >= 100),
                "average_progression": sum(p["overall_progression"] for p in participants_data) / len(participants_data) if participants_data else 0,
                "total_time_spent": sum(p["total_time_spent"] for p in participants_data)
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching course participants: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch course participants: {str(e)}")

@router.get("/participants/{participant_id}")
async def get_participant_details(participant_id: int, db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Get detailed information about a specific participant"""
    try:
        # Try to get from cache first
        cached_details = cache_service.get_participant_details(participant_id)
        if cached_details:
            logger.info(f"🚀 Participant {participant_id} details served from cache")
            return cached_details
        
        logger.info(f"👤 Computing participant {participant_id} details from database")
        participant = db.query(Participant).filter(Participant.id == participant_id).first()
        if not participant:
            raise HTTPException(status_code=404, detail="Participant not found")
        
        # Get all unique ADFs for this participant (group by ADF to avoid duplicates)
        participant_courses = db.query(ParticipantCourse).join(Course).filter(
            ParticipantCourse.participant_id == participant_id
        ).all()
        
        # Group by ADF to avoid duplicate courses
        adf_groups = {}
        for pc in participant_courses:
            course = db.query(Course).filter(Course.id == pc.course_id).first()
            if course and course.id_action_formation:
                adf_id = course.id_action_formation
                if adf_id not in adf_groups:
                    adf_groups[adf_id] = {
                        'course': course,
                        'participant_course': pc
                    }
        
        courses_data = []
        for adf_id, adf_data in adf_groups.items():
            course = adf_data['course']
            pc = adf_data['participant_course']
            
            # Get modules for this participant in this ADF (not just this course)
            # Join by id_lam instead of course_id FK
            adf_lam_ids_details = db.query(Course.id_lam).filter(
                Course.id_action_formation == adf_id
            ).distinct().all()
            
            if adf_lam_ids_details:
                lam_ids_details = [lam_id[0] for lam_id in adf_lam_ids_details if lam_id[0]]
                modules = db.query(Module).filter(
                    Module.id_lam.in_(lam_ids_details),
                    Module.participant_id == participant.id
                ).all()
                # Build date lookup from Course by id_lam
                course_dates_detail = {c.id_lam: c for c in db.query(Course).filter(
                    Course.id_action_formation == adf_id,
                    Course.id_lam.in_(lam_ids_details)
                ).all()}
            else:
                modules = []
                course_dates_detail = {}
            
            # Build module data with liveroom-based progression for sync/mixte modules
            modules_data = []
            for module in modules:
                mode = module.mode_organisation or ''
                if mode in ('elearning_sync', 'mixte'):
                    liveroom_prog = _get_liveroom_progression(db, participant.id, adf_id, module.id_lam)
                    progression = liveroom_prog if liveroom_prog is not None else 0.0
                else:
                    progression = module.lms_progression

                c_ref = course_dates_detail.get(module.id_lam, course)
                modules_data.append({
                    "id": module.id,
                    "id_lmp": module.id_lmp,
                    "id_lam": module.id_lam,
                    "intitule": module.intitule,
                    "progression": progression,
                    "last_access": module.lms_last_access_at.isoformat() if module.lms_last_access_at else None,
                    "mode_organisation": mode,
                    "time_spent": module.lms_time_spent,
                    "started_at": module.lms_started_at.isoformat() if module.lms_started_at else None,
                    "completed_at": module.lms_completed_at.isoformat() if module.lms_completed_at else None,
                    "date_debut": c_ref.date_debut.isoformat() if c_ref.date_debut else None,
                    "date_fin": c_ref.date_fin.isoformat() if c_ref.date_fin else None
                })
            modules_data.sort(key=lambda m: m["date_debut"] or "9999")

            # Calculate progression from resolved module progressions
            if modules_data:
                calculated_progression = sum(m["progression"] for m in modules_data) / len(modules_data)
            else:
                calculated_progression = 0.0

            completed_modules = sum(1 for m in modules_data if m["progression"] >= 100)

            # Get last activity from e-learning modules
            last_elearning = None
            if modules:
                elearning_dates = [m.lms_last_access_at for m in modules if m.lms_last_access_at]
                if elearning_dates:
                    last_elearning = max(elearning_dates)

            # Get last liveroom attendance
            last_liveroom = _get_last_liveroom_date(db, participant.id, adf_id)
            last_activity, last_activity_source = _resolve_last_activity(last_elearning, last_liveroom)

            # Calculate total time spent: e-learning + liveroom attended
            elearning_time_spent = sum(module.lms_time_spent or 0 for module in modules)
            lr_spent = _get_liveroom_time_spent(db, participant.id, adf_id)
            total_time_spent = elearning_time_spent + lr_spent

            # Get planned duration: e-learning + liveroom
            elearning_planned = course.planned_duration_hours or 0
            lr_planned_seconds = _get_liveroom_total_duration(db, adf_id)
            planned_duration_hours = elearning_planned + (lr_planned_seconds / 3600.0)

            # Get HubSpot deal data for this participant and ADF
            hubspot_deal_data = db.query(ParticipantHubspotData).filter(
                ParticipantHubspotData.participant_id == participant.id,
                ParticipantHubspotData.id_action_formation == adf_id
            ).first()

            courses_data.append({
                "course_id": course.id,
                "id_action_formation": adf_id,
                "course_title": course.intitule,
                "progression": calculated_progression,
                "activity_status": pc.activity_status,
                "date_add": pc.date_add.isoformat() if pc.date_add else None,
                "last_activity": last_activity.isoformat() if last_activity else None,
                "last_activity_source": last_activity_source,
                "completed_modules": completed_modules,
                "total_modules": len(modules_data),
                "total_time_spent": total_time_spent,
                "planned_duration_hours": planned_duration_hours,
                "hubspot_deal": {
                    "deal_id": hubspot_deal_data.c_id_transaction_hubspot,
                    "deal_url": hubspot_deal_data.c_url_transaction_hubspot,
                } if hubspot_deal_data and hubspot_deal_data.c_id_transaction_hubspot else None,
                "modules": modules_data
            })
        
        result = {
            "participant": {
                "id": participant.id,
                "id_participant": participant.id_participant,
                "nom": participant.nom,
                "prenom": participant.prenom,
                "email": participant.email,
                "id_entreprise": participant.id_entreprise,
                "created_at": participant.created_at.isoformat() if participant.created_at else None
            },
            "courses": courses_data,
            "summary": {
                "total_courses": len(courses_data),
                "completed_courses": sum(1 for c in courses_data if c["progression"] >= 100),
                "average_progression": sum(c["progression"] for c in courses_data) / len(courses_data) if courses_data else 0
            }
        }
        
        # Cache the result for 5 minutes
        cache_service.set_participant_details(participant_id, result, ttl=300)
        
        return result
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching participant details: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch participant details: {str(e)}")

@router.get("/", response_model=List[CourseResponse])
async def get_courses(db: Session = Depends(get_db)):
    """Get all courses with their modules grouped by ADF"""
    courses = db.query(Course).all()
    
    # Enhance courses with aggregated module data
    for course in courses:
        # Calculate average progression across all modules
        avg_progression = db.query(func.avg(Module.progression)).filter(
            Module.course_id == course.id
        ).scalar() or 0.0
        
        # Get last access time across all modules
        last_access = db.query(func.max(Module.last_access_at)).filter(
            Module.course_id == course.id
        ).scalar()
        
        # Add computed fields
        course.progression = float(avg_progression)
        course.last_access_at = last_access
    
    return courses

@router.get("/deadline-data")
async def get_deadline_data(db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Return all participant-module combinations where date_fin has passed.
    Frontend filters by progression threshold."""
    try:
        now = datetime.now(timezone.utc)

        # Single JOIN query: Course + Module + Participant (replaces N+1 loop)
        rows = (
            db.query(Course, Module, Participant)
            .join(Module, Module.id_lam == Course.id_lam)
            .join(Participant, Participant.id == Module.participant_id)
            .filter(
                Course.status.in_(['5', '6', '7']),
                Course.date_fin != None,
                Course.date_fin < now
            )
            .all()
        )

        if not rows:
            return {"items": [], "total": 0}

        # Build category lookup (single query)
        category_map = {
            cat.id_categorie_module: {"name": cat.intitule, "color": cat.color}
            for cat in db.query(ModuleCategory).all()
        }

        # Collect liveroom modules that need progression calculation
        liveroom_keys = set()
        for course, module, participant in rows:
            mode = module.mode_organisation or ''
            if mode in ('elearning_sync', 'mixte'):
                liveroom_keys.add((participant.id, course.id_action_formation, course.id_lam))

        # Batch liveroom progression: count total and attended creneaux per (adf, lam, participant)
        liveroom_prog_map = {}
        if liveroom_keys:
            all_adf_ids = {k[1] for k in liveroom_keys}
            all_lam_ids = {k[2] for k in liveroom_keys}
            creneaux = (
                db.query(Creneau)
                .filter(
                    Creneau.id_action_formation.in_(all_adf_ids),
                    Creneau.id_lam.in_(all_lam_ids)
                )
                .all()
            )
            # Group creneaux by (adf, lam)
            creneaux_by_key = {}
            for c in creneaux:
                key = (c.id_action_formation, c.id_lam)
                creneaux_by_key.setdefault(key, []).append(c.id)

            # Get all attendance records for these creneaux in one query
            all_creneau_ids = [c.id for c in creneaux]
            participant_ids = {k[0] for k in liveroom_keys}
            if all_creneau_ids and participant_ids:
                attendances = (
                    db.query(
                        CreneauParticipant.participant_id,
                        CreneauParticipant.creneau_id
                    )
                    .filter(
                        CreneauParticipant.creneau_id.in_(all_creneau_ids),
                        CreneauParticipant.participant_id.in_(participant_ids),
                        CreneauParticipant.presence == "1"
                    )
                    .all()
                )
                # Build attendance set for O(1) lookup
                attended_set = {(a.participant_id, a.creneau_id) for a in attendances}
            else:
                attended_set = set()

            # Compute progression per (participant, adf, lam)
            for pid, adf_id, lam_id in liveroom_keys:
                creneau_ids = creneaux_by_key.get((adf_id, lam_id), [])
                total = len(creneau_ids)
                if total == 0:
                    continue
                attended = sum(1 for cid in creneau_ids if (pid, cid) in attended_set)
                liveroom_prog_map[(pid, adf_id, lam_id)] = round((attended / total) * 100, 2)

        # Build latest note date map: (participant_id, adf_id) -> datetime
        latest_notes_map = {}
        note_rows = (
            db.query(
                Intervention.participant_id,
                Intervention.id_action_formation,
                func.max(Intervention.created_at).label('latest_note')
            )
            .filter(
                Intervention.intervention_type.in_(['note', 'call', 'email']),
                Intervention.is_active == True
            )
            .group_by(Intervention.participant_id, Intervention.id_action_formation)
            .all()
        )
        for pid, adf, latest in note_rows:
            if adf:
                latest_notes_map[(pid, adf)] = latest

        items = []
        for course, module, participant in rows:
            cat_info = category_map.get(course.categorie_module_id, {})
            mode = module.mode_organisation or ''

            if mode in ('elearning_sync', 'mixte'):
                progression = liveroom_prog_map.get(
                    (participant.id, course.id_action_formation, course.id_lam), 0.0
                )
            else:
                progression = module.lms_progression

            latest_note = latest_notes_map.get((participant.id, course.id_action_formation))

            items.append({
                "participant_id": participant.id,
                "id_participant": participant.id_participant,
                "nom": participant.nom,
                "prenom": participant.prenom,
                "email": participant.email,
                "id_action_formation": course.id_action_formation,
                "course_title": course.intitule,
                "module_intitule": module.intitule,
                "id_lam": module.id_lam,
                "mode_organisation": mode,
                "progression": round(progression, 2),
                "date_fin": course.date_fin.isoformat() if course.date_fin else None,
                "date_debut": course.date_debut.isoformat() if course.date_debut else None,
                "category_name": cat_info.get("name"),
                "category_color": cat_info.get("color"),
                "latest_note_date": latest_note.isoformat() if latest_note else None,
            })

        # Sort by progression ascending (worst first)
        items.sort(key=lambda x: x["progression"])

        return {"items": items, "total": len(items)}

    except Exception as e:
        logger.error(f"Error fetching deadline data: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{course_id}", response_model=CourseResponse)
async def get_course(course_id: int, db: Session = Depends(get_db)):
    """Get a specific course with its modules"""
    course = db.query(Course).filter(Course.id == course_id).first()
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    
    # Calculate average progression
    avg_progression = db.query(func.avg(Module.progression)).filter(
        Module.course_id == course.id
    ).scalar() or 0.0
    
    # Get last access time
    last_access = db.query(func.max(Module.last_access_at)).filter(
        Module.course_id == course.id
    ).scalar()
    
    # Add computed fields
    course.progression = float(avg_progression)
    course.last_access_at = last_access
    
    return course

@router.get("/{course_id}/modules", response_model=List[ModuleResponse])
async def get_course_modules(course_id: int, db: Session = Depends(get_db)):
    """Get all modules for a specific course"""
    course = db.query(Course).filter(Course.id == course_id).first()
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    
    return course.modules

@router.get("/elearning/", response_model=List[CourseWithParticipants])
async def get_elearning_courses(
        skip: int = Query(0, ge=0),
        limit: int = Query(100, ge=1, le=1000),
        db: Session = Depends(get_db)
):
    """Get only e-learning courses"""
    try:
        query = db.query(Course).options(
            joinedload(Course.participant_courses).joinedload(ParticipantCourse.participant)
        ).filter(Course.course_type == 'e-learning')

        courses = query.offset(skip).limit(limit).all()

        result = []
        for course in courses:
            course_data = CourseWithParticipants.model_validate(course)

            # Calculate statistics
            if course.participant_courses:
                progressions = [pc.progression for pc in course.participant_courses if pc.progression is not None]
                course_data.average_progression = sum(progressions) / len(progressions) if progressions else 0.0
                course_data.total_participants = len(course.participant_courses)
                completed_count = len([pc for pc in course.participant_courses if pc.activity_status == 'completed'])
                course_data.completion_rate = (completed_count / len(course.participant_courses)) * 100 if course.participant_courses else 0.0
                course_data.participants = [ParticipantCourseSchema.model_validate(pc) for pc in course.participant_courses]

            result.append(course_data)

        return result

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching e-learning courses: {str(e)}")
