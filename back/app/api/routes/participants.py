from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import or_, and_, func as sa_func
from typing import List, Optional
from app.models.database import get_db
from app.models.models import Participant, ParticipantCourse, Course, ModuleCategory, ParticipantHubspotData
from app.models.schemas import ParticipantWithProgress, ParticipantCourse as ParticipantCourseSchema, InactivitySummary, ModuleCategoryResponse
from app.services.cache_service import cache_service
from app.services.inactivity_service import InactivityService
import logging

logger = logging.getLogger(__name__)
router = APIRouter()

def normalize_search_term(search: str) -> list:
    """Normalize search term to handle accented characters and create multiple search patterns"""
    # Define accent mappings for all common characters
    accent_map = {
        'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
        'à': 'a', 'â': 'a', 'ä': 'a',
        'î': 'i', 'ï': 'i',
        'ô': 'o', 'ö': 'o',
        'ù': 'u', 'û': 'u', 'ü': 'u',
        'ÿ': 'y',
        'ç': 'c'
    }
    
    # Create reverse mapping for generating accented variations
    reverse_accent_map = {}
    for accented, non_accented in accent_map.items():
        if non_accented not in reverse_accent_map:
            reverse_accent_map[non_accented] = []
        reverse_accent_map[non_accented].append(accented)
    
    # Remove accents from search term
    search_no_accent = search
    for accented, non_accented in accent_map.items():
        search_no_accent = search_no_accent.replace(accented, non_accented)
    
    # Create bidirectional patterns - both with and without accents
    patterns = []
    
    # Original search term patterns
    patterns.extend([
        f"%{search}%",  # Original search term
        f"%{search.lower()}%",  # Lowercase
        f"%{search_no_accent}%",  # Without accents
        f"%{search_no_accent.lower()}%"  # Lowercase without accents
    ])
    
    # If the search term has no accents, generate single-substitution variants
    # (swap ONE character at a time). The previous implementation generated every
    # combinatorial product of accents across all vowels — for a 13-character name
    # with many vowels that's hundreds of thousands of variants, producing a SQL
    # query with millions of ILIKE branches and hanging Postgres.
    if search == search_no_accent:
        accented_variations = []
        for i, ch in enumerate(search):
            lower_ch = ch.lower()
            if lower_ch in reverse_accent_map:
                for accent in reverse_accent_map[lower_ch]:
                    accented_variations.append(search[:i] + accent + search[i + 1:])

        for variation in accented_variations:
            if variation != search:
                patterns.extend([
                    f"%{variation}%",
                    f"%{variation.lower()}%"
                ])
    
    # Remove duplicates while preserving order
    unique_patterns = []
    for pattern in patterns:
        if pattern not in unique_patterns:
            unique_patterns.append(pattern)
    
    return unique_patterns

def calculate_activity_status(participant_course: ParticipantCourse, db: Session = None) -> str:
    """Calculate activity status for a participant course"""
    from datetime import datetime, timezone
    from app.models.models import Module, Course

    # Check if completed
    if participant_course.overall_progression and participant_course.overall_progression >= 100.0:
        return "completed"

    # Check last activity - if null in participant_course, calculate from modules
    last_activity = participant_course.last_activity
    
    if not last_activity and db:
        # Get the course and find the ADF
        course = db.query(Course).filter(Course.id == participant_course.course_id).first()
        if course:
            # Get all modules for this participant in this ADF
            adf_lam_ids = db.query(Course.id_lam).filter(
                Course.id_action_formation == course.id_action_formation
            ).distinct().all()
            
            if adf_lam_ids:
                lam_ids_list = [lam_id[0] for lam_id in adf_lam_ids if lam_id[0]]
                modules = db.query(Module).filter(
                    Module.id_lam.in_(lam_ids_list),
                    Module.participant_id == participant_course.participant_id,
                    Module.lms_last_access_at.isnot(None)
                ).all()
                
                if modules:
                    last_activities = [m.lms_last_access_at for m in modules if m.lms_last_access_at]
                    if last_activities:
                        last_activity = max(last_activities)

    if not last_activity:
        return "not_started"

    # Use timezone-aware datetime to compare with database timestamps
    now = datetime.now(timezone.utc)
    
    # Ensure last_activity is timezone-aware
    if last_activity.tzinfo is None:
        last_activity = last_activity.replace(tzinfo=timezone.utc)
    
    days_since_access = (now - last_activity).days

    if days_since_access <= 30:  # 30 days threshold
        return "active"
    else:
        return "inactive"

@router.get("/", response_model=List[ParticipantWithProgress])
async def get_participants(
        skip: int = Query(0, ge=0),
        limit: int = Query(25, ge=1, le=1000),
        email: Optional[str] = Query(None),
        company: Optional[str] = Query(None),
        search: Optional[str] = Query(None),
        db: Session = Depends(get_db)
):
    """Get all participants with their course progress"""
    try:
        # For basic requests without filters, try cache first
        if skip == 0 and limit == 100 and not email and not company and not search:
            cached_participants = cache_service.get_participants_list()
            if cached_participants:
                logger.info("🚀 Participants list served from cache")
                return cached_participants
            logger.info("👥 Computing participants list from database")
        
        query = db.query(Participant).options(
            joinedload(Participant.courses).joinedload(ParticipantCourse.course)
        )

        # Apply filters
        if search:
            # Split search into tokens so "RIGOULET Maeva" matches "Maeva RIGOULET".
            # Each token must match at least one searchable field (ORed within a token),
            # and ALL tokens must match (ANDed across tokens).
            tokens = [t for t in search.strip().split() if t]
            if tokens:
                per_token_conditions = []
                for token in tokens:
                    token_patterns = normalize_search_term(token)
                    logger.info(f"🔍 Token '{token}' -> {len(token_patterns)} patterns")
                    or_clauses = []
                    for pattern in token_patterns:
                        or_clauses.extend([
                            Participant.email.ilike(pattern),
                            Participant.prenom.ilike(pattern),
                            Participant.nom.ilike(pattern),
                            (Participant.prenom + ' ' + Participant.nom).ilike(pattern),
                            (Participant.nom + ' ' + Participant.prenom).ilike(pattern),
                        ])
                    per_token_conditions.append(or_(*or_clauses))
                query = query.filter(and_(*per_token_conditions))
        elif email:
            query = query.filter(Participant.email.ilike(f"%{email}%"))
        # Note: company field doesn't exist in our model, so removing this filter
        # if company:
        #     query = query.filter(Participant.company.ilike(f"%{company}%"))

        # Apply pagination
        participants = query.offset(skip).limit(limit).all()

        # Batch-fetch linked deal counts for this page
        participant_ids = [p.id for p in participants]
        linked_counts = {}
        if participant_ids:
            count_rows = (
                db.query(
                    ParticipantHubspotData.participant_id,
                    sa_func.count(ParticipantHubspotData.id).label("c")
                )
                .filter(
                    ParticipantHubspotData.participant_id.in_(participant_ids),
                    ParticipantHubspotData.c_id_transaction_hubspot.isnot(None),
                )
                .group_by(ParticipantHubspotData.participant_id)
                .all()
            )
            linked_counts = {pid: int(c) for pid, c in count_rows}

        result = []

        for participant in participants:
            participant_data = ParticipantWithProgress.model_validate(participant)
            participant_data.linked_deals_count = linked_counts.get(participant.id, 0)

            # Filter out courses whose ADF is no longer active (status ∉ {5, 6, 7}).
            # Archived ADFs should drop off the participant summary the same way
            # they're hidden from the ADF list.
            active_pc = [
                pc for pc in (participant.courses or [])
                if pc.course and pc.course.status in ('5', '6', '7')
            ]

            if active_pc:
                progressions = [pc.overall_progression for pc in active_pc if pc.overall_progression is not None]
                participant_data.overall_progression = sum(progressions) / len(progressions) if progressions else 0.0
                participant_data.total_courses = len(active_pc)

                completed_courses = 0
                active_courses = 0

                for pc in active_pc:
                    status = calculate_activity_status(pc, db)
                    pc.activity_status = status
                    if status == 'completed':
                        completed_courses += 1
                    elif status in ('active', 'not_started'):
                        active_courses += 1

                participant_data.completed_courses = completed_courses
                participant_data.active_courses = active_courses
                participant_data.courses = [ParticipantCourseSchema.model_validate(pc) for pc in active_pc]
            else:
                participant_data.overall_progression = 0.0
                participant_data.total_courses = 0
                participant_data.completed_courses = 0
                participant_data.active_courses = 0
                participant_data.courses = []

            result.append(participant_data)

        # Cache the result if it's the default query
        if skip == 0 and limit == 25 and not email and not company and not search:
            cache_service.set_participants_list(result, ttl=300)

        return result

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching participants: {str(e)}")

@router.get("/count")
async def get_participants_count(
        email: Optional[str] = Query(None),
        company: Optional[str] = Query(None),
        search: Optional[str] = Query(None),
        db: Session = Depends(get_db)
):
    """Get total count of participants"""
    try:
        query = db.query(Participant)

        # Apply filters
        if search:
            # Search across email, first name, and last name with accent-insensitive search
            search_patterns = normalize_search_term(search)
            
            # Build OR conditions for each pattern
            search_conditions = []
            
            for pattern in search_patterns:
                search_conditions.extend([
                    Participant.email.ilike(pattern),
                    Participant.prenom.ilike(pattern),
                    Participant.nom.ilike(pattern),
                    (Participant.prenom + ' ' + Participant.nom).ilike(pattern)
                ])
            
            query = query.filter(or_(*search_conditions))
        elif email:
            query = query.filter(Participant.email.ilike(f"%{email}%"))
        # Note: company field doesn't exist in our model, so removing this filter
        # if company:
        #     query = query.filter(Participant.company.ilike(f"%{company}%"))

        count = query.count()
        return {"total": count}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error counting participants: {str(e)}")

@router.get("/inactive", response_model=InactivitySummary)
async def get_inactive_participants(
    group_by_course: bool = Query(False),
    course_id: Optional[int] = Query(None),
    at_risk_threshold_days: int = Query(14, ge=1, le=365),
    inactivity_threshold_days: int = Query(30, ge=1, le=365),
    exclude_recent_enrollments_days: int = Query(0, ge=0, le=90),
    min_progression: Optional[float] = Query(None, ge=0, le=100),
    max_progression: Optional[float] = Query(None, ge=0, le=100),
    db: Session = Depends(get_db)
):
    """Get participants classified by activity status.

    Statuses:
    - active: Last activity within at_risk_threshold_days
    - at_risk: Between at_risk_threshold_days and inactivity_threshold_days
    - inactive: Beyond inactivity_threshold_days
    - never_started: No activity data at all

    Exclusions:
    - Participants enrolled less than exclude_recent_enrollments_days ago
    - Participants with 100% completion
    """
    try:
        # Build cache key from query params
        cache_key = f"{group_by_course}:{course_id}:{at_risk_threshold_days}:{inactivity_threshold_days}:{exclude_recent_enrollments_days}:{min_progression}:{max_progression}"
        cached = cache_service.get_inactivity_data(cache_key)
        if cached:
            logger.info("Inactivity data served from cache")
            return cached

        logger.info(f"Computing inactivity data (group_by_course={group_by_course}, course_id={course_id})")

        service = InactivityService(
            db=db,
            at_risk_threshold_days=at_risk_threshold_days,
            inactivity_threshold_days=inactivity_threshold_days,
            exclude_recent_enrollments_days=exclude_recent_enrollments_days
        )

        result = service.get_participants(
            group_by_course=group_by_course,
            course_id=course_id,
            min_progression=min_progression,
            max_progression=max_progression
        )

        # Cache the result (serialize Pydantic model to dict)
        cache_service.set_inactivity_data(cache_key, result.model_dump(mode='json'), ttl=180)

        logger.info(f"Found {result.total_participants} participants ({result.active_count} active, {result.at_risk_count} at risk, {result.inactive_count} inactive, {result.never_started_count} never started)")
        return result

    except Exception as e:
        logger.error(f"Error fetching participants: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error fetching participants: {str(e)}")

@router.get("/categories", response_model=List[ModuleCategoryResponse])
async def get_module_categories(db: Session = Depends(get_db)):
    """Get all active module categories for filtering"""
    try:
        categories = db.query(ModuleCategory).filter(
            ModuleCategory.status == "1"
        ).order_by(ModuleCategory.display_order).all()
        return [ModuleCategoryResponse.model_validate(cat) for cat in categories]
    except Exception as e:
        logger.error(f"Error fetching categories: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error fetching categories: {str(e)}")

@router.get("/{participant_id}", response_model=ParticipantWithProgress)
async def get_participant(participant_id: int, db: Session = Depends(get_db)):
    """Get a specific participant with their course progress"""
    try:
        participant = db.query(Participant).options(
            joinedload(Participant.courses).joinedload(ParticipantCourse.course)
        ).filter(Participant.id == participant_id).first()

        if not participant:
            raise HTTPException(status_code=404, detail="Participant not found")

        # Convert to response model with calculated fields
        participant_data = ParticipantWithProgress.model_validate(participant)

        if participant.courses:
            progressions = [pc.overall_progression for pc in participant.courses if pc.overall_progression is not None]
            participant_data.overall_progression = sum(progressions) / len(progressions) if progressions else 0.0
            participant_data.total_courses = len(participant.courses)

            # Update activity statuses and count them
            completed_courses = 0
            active_courses = 0

            for pc in participant.courses:
                status = calculate_activity_status(pc, db)
                pc.activity_status = status  # Update the status
                if status == 'completed':
                    completed_courses += 1
                elif status == 'active':
                    active_courses += 1

            participant_data.completed_courses = completed_courses
            participant_data.active_courses = active_courses
            participant_data.courses = [ParticipantCourseSchema.model_validate(pc) for pc in participant.courses]

        return participant_data

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching participant: {str(e)}")

@router.get("/email/{email}", response_model=ParticipantWithProgress)
async def get_participant_by_email(email: str, db: Session = Depends(get_db)):
    """Get a participant by email"""
    try:
        participant = db.query(Participant).options(
            joinedload(Participant.courses).joinedload(ParticipantCourse.course)
        ).filter(Participant.email == email).first()

        if not participant:
            raise HTTPException(status_code=404, detail="Participant not found")

        # Convert to response model with calculated fields
        participant_data = ParticipantWithProgress.model_validate(participant)

        if participant.courses:
            progressions = [pc.overall_progression for pc in participant.courses if pc.overall_progression is not None]
            participant_data.overall_progression = sum(progressions) / len(progressions) if progressions else 0.0
            participant_data.total_courses = len(participant.courses)

            # Update activity statuses and count them
            completed_courses = 0
            active_courses = 0

            for pc in participant.courses:
                status = calculate_activity_status(pc, db)
                pc.activity_status = status  # Update the status
                if status == 'completed':
                    completed_courses += 1
                elif status == 'active':
                    active_courses += 1

            participant_data.completed_courses = completed_courses
            participant_data.active_courses = active_courses
            participant_data.courses = [ParticipantCourseSchema.model_validate(pc) for pc in participant.courses]

        return participant_data

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching participant: {str(e)}")
