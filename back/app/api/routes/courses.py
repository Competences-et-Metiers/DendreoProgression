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
def get_dashboard_stats(db: Session = Depends(get_db)) -> Dict[str, Any]:
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
def get_all_courses(db: Session = Depends(get_db)) -> List[Dict[str, Any]]:
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
        # Only active ADFs (Dendreo etape_process 5, 6, 7) are listed — inactive ones drop off
        # once sync updates their Course.status.
        #
        # Everything below is batched into a handful of queries. The previous version ran a
        # triple-nested loop (per ADF → per participant → per-participant LAM/Module/HubSpot
        # lookups), which meant thousands of round-trips on every cache miss.
        adfs = [
            row[0] for row in db.query(Course.id_action_formation).filter(
                Course.status.in_(['5', '6', '7'])
            ).distinct().all()
        ]

        if not adfs:
            cache_service.set_courses_list([], ttl=600)
            return []

        active_adf_set = set(adfs)

        # Single pass over the courses table: representative course row per ADF + ADF -> LAM ids.
        # Deliberately unordered: the previous code took an unordered .first() per ADF, so
        # first-seen in natural scan order reproduces which Course row represents each ADF
        # (it supplies the ADF's id, intitule, planned_duration_hours and timestamps).
        adf_course_map: Dict[str, Course] = {}
        adf_lams_map: Dict[str, List[str]] = {}
        for course in db.query(Course).all():
            adf = course.id_action_formation
            if adf not in adf_course_map:
                adf_course_map[adf] = course
            if course.id_lam:
                adf_lams_map.setdefault(adf, []).append(course.id_lam)

        # Distinct LAMs that actually have module rows — the denominator for module_count.
        module_lam_set = {
            row[0] for row in db.query(Module.id_lam).distinct().all() if row[0]
        }

        # One enrollment row per (ADF, participant), inner-joined to Participant as the
        # previous DISTINCT ON query did.
        #
        # NOTE: a participant enrolled in several LAMs of one ADF has several
        # participant_courses rows with differing activity_status, and this endpoint
        # surfaces only one of them. The old DISTINCT ON had no ORDER BY, so which row
        # won was an arbitrary Postgres sort tie-break (stable for a given plan + heap
        # layout, but liable to change after a VACUUM or plan change). Ordering by id
        # makes the pick the participant's earliest enrollment row and keeps it stable.
        enrollment_rows = (
            db.query(
                Course.id_action_formation,
                Participant,
                ParticipantCourse.activity_status,
            )
            .join(ParticipantCourse, ParticipantCourse.course_id == Course.id)
            .join(Participant, Participant.id == ParticipantCourse.participant_id)
            .filter(Course.id_action_formation.in_(active_adf_set))
            .order_by(ParticipantCourse.id)
            .all()
        )

        # (adf, participant_id) -> (participant, activity_status), first occurrence wins
        enrollments_by_adf: Dict[str, List[Any]] = {}
        seen_pairs = set()
        for adf, participant, activity_status in enrollment_rows:
            pair = (adf, participant.id)
            if pair in seen_pairs:
                continue
            seen_pairs.add(pair)
            enrollments_by_adf.setdefault(adf, []).append((participant, activity_status))

        # Module aggregates keyed by (participant_id, id_lam): count, progression sum, time sum.
        module_agg: Dict[tuple, tuple] = {}
        for pid, lam, cnt, prog_sum, time_sum in db.query(
            Module.participant_id,
            Module.id_lam,
            func.count(Module.id),
            func.sum(Module.lms_progression),
            func.sum(Module.lms_time_spent),
        ).group_by(Module.participant_id, Module.id_lam).all():
            module_agg[(pid, lam)] = (int(cnt or 0), float(prog_sum or 0.0), int(time_sum or 0))

        # HubSpot data keyed by (participant_id, ADF) — unique per the table constraint.
        hubspot_map = {
            (h.participant_id, h.id_action_formation): h
            for h in db.query(ParticipantHubspotData).filter(
                ParticipantHubspotData.id_action_formation.in_(active_adf_set)
            ).all()
        }

        result = []
        for id_adf in adfs:
            adf_course = adf_course_map.get(id_adf)
            if not adf_course:
                continue

            lam_ids_list = adf_lams_map.get(id_adf, [])

            # Count all modules for this ADF by matching id_lam (since course_id FK may not be set)
            module_count = len({lam for lam in lam_ids_list if lam in module_lam_set})

            # Skip if no modules at all (empty courses)
            if module_count == 0:
                continue

            adf_enrollments = enrollments_by_adf.get(id_adf, [])

            # Use the deduplicated participant count
            participant_count = len(adf_enrollments)

            participants_data = []
            for participant, activity_status in adf_enrollments:
                # Aggregate this participant's modules across the ADF's LAMs
                module_rows = 0
                progression_sum = 0.0
                total_time_spent = 0
                for lam_id in lam_ids_list:
                    agg = module_agg.get((participant.id, lam_id))
                    if agg:
                        module_rows += agg[0]
                        progression_sum += agg[1]
                        total_time_spent += agg[2]

                # Calculate real progression: average of all module progressions
                calculated_progression = (progression_sum / module_rows) if module_rows else 0.0

                hubspot_data = hubspot_map.get((participant.id, id_adf))

                participants_data.append({
                    "id": participant.id,
                    "id_participant": participant.id_participant,
                    "nom": participant.nom,
                    "prenom": participant.prenom,
                    "email": participant.email,
                    "id_entreprise": participant.id_entreprise,
                    "overall_progression": round(calculated_progression, 2),
                    "activity_status": activity_status,
                    "total_time_spent": total_time_spent,
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
def get_course_time_stats(course_id: int, db: Session = Depends(get_db)) -> Dict[str, Any]:
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
def get_course_participants(course_id: int, db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Get all participants for a specific course with their progression"""
    try:
        # Get course info
        course = db.query(Course).filter(Course.id == course_id).first()
        if not course:
            raise HTTPException(status_code=404, detail="Course not found")
        
        adf_id = course.id_action_formation

        # --- Batched lookups -------------------------------------------------
        # Everything below used to be queried once per participant (and, for liveroom
        # progression, once per module). It's all fetched up front now.

        # ADF -> LAM ids and the Course row per LAM (participant-independent).
        adf_courses = db.query(Course).filter(
            Course.id_action_formation == adf_id
        ).all()
        lam_ids_modules = [c.id_lam for c in adf_courses if c.id_lam]
        course_dates = {c.id_lam: c for c in adf_courses if c.id_lam}

        # One enrollment row per participant, inner-joined to Participant.
        enrollment_rows = (
            db.query(ParticipantCourse, Participant)
            .join(Course, ParticipantCourse.course_id == Course.id)
            .join(Participant, Participant.id == ParticipantCourse.participant_id)
            .filter(Course.id_action_formation == adf_id)
            .order_by(ParticipantCourse.id)
            .all()
        )
        enrollments = []
        seen_participants = set()
        for pc, participant in enrollment_rows:
            if pc.participant_id in seen_participants:
                continue
            seen_participants.add(pc.participant_id)
            enrollments.append((pc, participant))

        participant_ids = [p.id for _, p in enrollments]

        # Modules for every participant in this ADF, grouped by participant.
        modules_by_participant: Dict[int, List[Module]] = {}
        if lam_ids_modules and participant_ids:
            for module in db.query(Module).filter(
                Module.id_lam.in_(lam_ids_modules),
                Module.participant_id.in_(participant_ids)
            ).all():
                modules_by_participant.setdefault(module.participant_id, []).append(module)

        # Liveroom progression inputs: total creneaux per LAM, attended per (participant, LAM).
        creneaux_total_per_lam: Dict[str, int] = {}
        for lam, cnt in db.query(
            Creneau.id_lam, func.count(Creneau.id)
        ).filter(Creneau.id_action_formation == adf_id).group_by(Creneau.id_lam).all():
            creneaux_total_per_lam[lam] = int(cnt or 0)

        attended_per_participant_lam: Dict[tuple, int] = {}
        for pid, lam, cnt in (
            db.query(CreneauParticipant.participant_id, Creneau.id_lam, func.count(CreneauParticipant.id))
            .join(Creneau, CreneauParticipant.creneau_id == Creneau.id)
            .filter(
                Creneau.id_action_formation == adf_id,
                CreneauParticipant.presence == "1"
            )
            .group_by(CreneauParticipant.participant_id, Creneau.id_lam)
            .all()
        ):
            attended_per_participant_lam[(pid, lam)] = int(cnt or 0)

        # Liveroom time spent + last attended date, per participant, for this ADF.
        liveroom_time_by_participant: Dict[int, int] = {}
        last_liveroom_by_participant: Dict[int, Any] = {}
        now_ts = datetime.now(timezone.utc)
        for pid, total_duration in (
            db.query(
                CreneauParticipant.participant_id,
                func.sum(Creneau.duration),
            )
            .join(Creneau, CreneauParticipant.creneau_id == Creneau.id)
            .filter(
                Creneau.id_action_formation == adf_id,
                CreneauParticipant.presence == "1"
            )
            .group_by(CreneauParticipant.participant_id)
            .all()
        ):
            liveroom_time_by_participant[pid] = int(total_duration or 0)

        # Last attended date must exclude future sessions, so it needs its own filter.
        for pid, last_fin in (
            db.query(CreneauParticipant.participant_id, func.max(Creneau.date_fin))
            .join(Creneau, CreneauParticipant.creneau_id == Creneau.id)
            .filter(
                Creneau.id_action_formation == adf_id,
                CreneauParticipant.presence == "1",
                Creneau.date_fin <= now_ts
            )
            .group_by(CreneauParticipant.participant_id)
            .all()
        ):
            last_liveroom_by_participant[pid] = last_fin

        # Upcoming sessions per participant (no presence filter, matching the helper).
        upcoming_by_participant: Dict[int, tuple] = {}
        for pid, cnt, next_date in (
            db.query(
                CreneauParticipant.participant_id,
                func.count(Creneau.id),
                func.min(Creneau.date_debut),
            )
            .join(Creneau, CreneauParticipant.creneau_id == Creneau.id)
            .filter(
                Creneau.id_action_formation == adf_id,
                Creneau.date_debut > now_ts
            )
            .group_by(CreneauParticipant.participant_id)
            .all()
        ):
            upcoming_by_participant[pid] = (int(cnt or 0), next_date)

        # HubSpot data per participant for this ADF.
        hubspot_map = {
            h.participant_id: h
            for h in db.query(ParticipantHubspotData).filter(
                ParticipantHubspotData.id_action_formation == adf_id
            ).all()
        }
        # ---------------------------------------------------------------------

        participants_data = []

        for pc, participant in enrollments:
            modules = modules_by_participant.get(participant.id, [])

            # Build module data with liveroom-based progression for sync/mixte modules
            modules_data = []
            for module in modules:
                mode = module.mode_organisation or ''
                if mode in ('elearning_sync', 'mixte'):
                    total_creneaux = creneaux_total_per_lam.get(module.id_lam, 0)
                    if total_creneaux:
                        attended = attended_per_participant_lam.get((participant.id, module.id_lam), 0)
                        progression = round((attended / total_creneaux) * 100, 2)
                    else:
                        progression = 0.0
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
            lr_spent = liveroom_time_by_participant.get(participant.id, 0)
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
            last_liveroom = last_liveroom_by_participant.get(participant.id)
            last_activity, last_activity_source = _resolve_last_activity(last_elearning, last_liveroom)

            # Get upcoming sessions
            upcoming_count, next_session_date = upcoming_by_participant.get(participant.id, (0, None))

            # Get HubSpot data for this participant and ADF
            hubspot_data = hubspot_map.get(participant.id)

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
                "planned_duration_hours": (course.planned_duration_hours or 0) + (_get_liveroom_total_duration(db, adf_id) / 3600.0),
                "total_modules": db.query(Module.id_lam).filter(
                    Module.id_lam.in_(lam_ids_modules)
                ).distinct().count() if lam_ids_modules else 0
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
def get_participant_details(participant_id: int, db: Session = Depends(get_db)) -> Dict[str, Any]:
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
        
        # Get all unique ADFs for this participant (group by ADF to avoid duplicates).
        # Course comes back on the same row, so the loop below no longer re-queries it.
        participant_courses = db.query(ParticipantCourse, Course).join(
            Course, ParticipantCourse.course_id == Course.id
        ).filter(
            ParticipantCourse.participant_id == participant_id
        ).all()

        # Group by ADF to avoid duplicate courses.
        # Skip ADFs whose status is no longer active (Dendreo etape 5/6/7); they're
        # considered archived and should drop off the participant's view.
        adf_groups = {}
        for pc, course in participant_courses:
            if course and course.id_action_formation and course.status in ('5', '6', '7'):
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

            # Liveroom progression inputs for this ADF, fetched once instead of
            # twice per sync/mixte module.
            creneaux_total_per_lam = {
                lam: int(cnt or 0)
                for lam, cnt in db.query(Creneau.id_lam, func.count(Creneau.id))
                .filter(Creneau.id_action_formation == adf_id)
                .group_by(Creneau.id_lam).all()
            }
            attended_per_lam = {
                lam: int(cnt or 0)
                for lam, cnt in db.query(Creneau.id_lam, func.count(CreneauParticipant.id))
                .join(CreneauParticipant, CreneauParticipant.creneau_id == Creneau.id)
                .filter(
                    Creneau.id_action_formation == adf_id,
                    CreneauParticipant.participant_id == participant.id,
                    CreneauParticipant.presence == "1"
                )
                .group_by(Creneau.id_lam).all()
            }

            # Build module data with liveroom-based progression for sync/mixte modules
            modules_data = []
            for module in modules:
                mode = module.mode_organisation or ''
                if mode in ('elearning_sync', 'mixte'):
                    total_creneaux = creneaux_total_per_lam.get(module.id_lam, 0)
                    if total_creneaux:
                        progression = round(
                            (attended_per_lam.get(module.id_lam, 0) / total_creneaux) * 100, 2
                        )
                    else:
                        progression = 0.0
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
                    # Deal financials captured at link time (see ParticipantHubspotData)
                    "amount": hubspot_deal_data.deal_amount,
                    "type_de_financement": hubspot_deal_data.deal_type_financement,
                    "montant_pec": hubspot_deal_data.deal_montant_pec,
                    "montant_rac": hubspot_deal_data.deal_montant_rac,
                } if hubspot_deal_data and hubspot_deal_data.c_id_transaction_hubspot else None,
                "edof_date_debut": hubspot_deal_data.edof_date_debut if hubspot_deal_data else None,
                "edof_date_fin": hubspot_deal_data.edof_date_fin if hubspot_deal_data else None,
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
                "edof_sessions": participant.edof_sessions or [],
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
def get_courses(db: Session = Depends(get_db)):
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
def get_deadline_data(db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Return all participant-module combinations for active courses.
    Frontend filters by deadline (overdue) status and progression threshold."""
    try:
        # Single JOIN query: Course + Module + Participant (replaces N+1 loop)
        rows = (
            db.query(Course, Module, Participant)
            .join(Module, Module.id_lam == Course.id_lam)
            .join(Participant, Participant.id == Module.participant_id)
            .filter(
                Course.status.in_(['5', '6', '7'])
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
                        CreneauParticipant.creneau_id,
                        CreneauParticipant.heures_presence,
                    )
                    .filter(
                        CreneauParticipant.creneau_id.in_(all_creneau_ids),
                        CreneauParticipant.participant_id.in_(participant_ids),
                        CreneauParticipant.presence == "1"
                    )
                    .all()
                )
                # (pid, cid) -> hours_present (for attended creneaux only)
                attended_hours = {(a.participant_id, a.creneau_id): float(a.heures_presence or 0) for a in attendances}
            else:
                attended_hours = {}

            # Build creneau_id -> date_fin map (for last-access derivation)
            creneau_date_fin = {c.id: c.date_fin for c in creneaux}

            # Planned duration per (adf, lam) — denominator for progression
            planned_hours_map = {
                (course.id_action_formation, course.id_lam): float(course.planned_duration_hours or 0)
                for course, _, _ in rows
            }

            # Compute progression (attended hours / planned hours) and latest attended creneau date
            liveroom_last_access_map = {}
            for pid, adf_id, lam_id in liveroom_keys:
                creneau_ids = creneaux_by_key.get((adf_id, lam_id), [])
                if not creneau_ids:
                    continue
                hours_present = sum(
                    attended_hours.get((pid, cid), 0)
                    for cid in creneau_ids
                )
                planned = planned_hours_map.get((adf_id, lam_id), 0)
                if planned > 0:
                    liveroom_prog_map[(pid, adf_id, lam_id)] = round(min(hours_present / planned, 1.0) * 100, 2)
                elif creneau_ids:
                    # Fallback: count-based when planned duration is unknown
                    attended_count = sum(1 for cid in creneau_ids if (pid, cid) in attended_hours)
                    liveroom_prog_map[(pid, adf_id, lam_id)] = round((attended_count / len(creneau_ids)) * 100, 2)

                attended_dates = [
                    creneau_date_fin[cid]
                    for cid in creneau_ids
                    if (pid, cid) in attended_hours and creneau_date_fin.get(cid)
                ]
                if attended_dates:
                    liveroom_last_access_map[(pid, adf_id, lam_id)] = max(attended_dates)
        else:
            liveroom_last_access_map = {}

        # Build latest note map: (participant_id, adf_id) -> {date, text}
        # First get the max date per (participant, adf)
        from sqlalchemy import and_
        latest_dates_sub = (
            db.query(
                Intervention.participant_id,
                Intervention.id_action_formation,
                func.max(Intervention.created_at).label('max_date')
            )
            .filter(
                Intervention.intervention_type.in_(['note', 'call', 'email']),
                Intervention.is_active == True
            )
            .group_by(Intervention.participant_id, Intervention.id_action_formation)
            .subquery()
        )
        # Then join back to get details of the latest intervention
        latest_notes_map = {}
        note_rows = (
            db.query(Intervention)
            .join(
                latest_dates_sub,
                and_(
                    Intervention.participant_id == latest_dates_sub.c.participant_id,
                    Intervention.id_action_formation == latest_dates_sub.c.id_action_formation,
                    Intervention.created_at == latest_dates_sub.c.max_date
                )
            )
            .filter(
                Intervention.intervention_type.in_(['note', 'call', 'email']),
                Intervention.is_active == True
            )
            .all()
        )
        for note in note_rows:
            if note.id_action_formation:
                details = note.details or {}
                text = details.get('text', '') if isinstance(details, dict) else ''
                latest_notes_map[(note.participant_id, note.id_action_formation)] = {
                    "date": note.created_at,
                    "text": text,
                    "type": note.intervention_type,
                }

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

            note_info = latest_notes_map.get((participant.id, course.id_action_formation))

            # Last connection: combine e-learning timestamp with liveroom attendance for sync/mixte modes
            last_access = module.lms_last_access_at
            if mode in ('elearning_sync', 'mixte'):
                liveroom_last = liveroom_last_access_map.get(
                    (participant.id, course.id_action_formation, course.id_lam)
                )
                if liveroom_last and (not last_access or liveroom_last > last_access):
                    last_access = liveroom_last

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
                "last_access": last_access.isoformat() if last_access else None,
                "date_fin": course.date_fin.isoformat() if course.date_fin else None,
                "date_debut": course.date_debut.isoformat() if course.date_debut else None,
                "category_name": cat_info.get("name"),
                "category_color": cat_info.get("color"),
                "latest_note_date": note_info["date"].isoformat() if note_info else None,
                "latest_note_text": note_info["text"] if note_info else None,
                "latest_note_type": note_info["type"] if note_info else None,
            })

        # Sort by progression ascending (worst first)
        items.sort(key=lambda x: x["progression"])

        return {"items": items, "total": len(items)}

    except Exception as e:
        logger.error(f"Error fetching deadline data: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{course_id}", response_model=CourseResponse)
def get_course(course_id: int, db: Session = Depends(get_db)):
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
def get_course_modules(course_id: int, db: Session = Depends(get_db)):
    """Get all modules for a specific course"""
    course = db.query(Course).filter(Course.id == course_id).first()
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    
    return course.modules

@router.get("/elearning/", response_model=List[CourseWithParticipants])
def get_elearning_courses(
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
