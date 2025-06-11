from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session, joinedload
from typing import List, Optional, Dict, Any
from app.models.database import get_db
from app.models.models import Course, ParticipantCourse, Participant, Module, ParticipantHubspotData
from app.models.schemas import CourseWithParticipants, ParticipantCourse as ParticipantCourseSchema
from app.schemas.course import CourseResponse, ModuleResponse
from sqlalchemy import func
import logging

logger = logging.getLogger(__name__)
router = APIRouter()

@router.get("/stats")
async def get_dashboard_stats(db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Get overall dashboard statistics"""
    try:
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
        
        return {
            "total_courses": total_courses,
            "total_participants": total_participants,
            "total_modules": total_modules,
            "total_enrollments": total_participant_courses,
            "completed_enrollments": completed_courses,
            "average_progression": round(float(avg_progression), 2),
            "completion_rate": round((completed_courses / total_participant_courses * 100), 2) if total_participant_courses > 0 else 0
        }
        
    except Exception as e:
        logger.error(f"Error fetching dashboard stats: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch dashboard stats: {str(e)}")

@router.get("/courses")
async def get_all_courses(db: Session = Depends(get_db)) -> List[Dict[str, Any]]:
    """Get all ADFs with their participants and e-learning module count"""
    try:
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
            
            # Count unique e-learning modules (by id_lam) in this ADF
            # Only count modules where mode_organisation indicates e-learning
            elearning_module_count = db.query(Module.id_lam).join(Course).filter(
                Course.id_action_formation == id_adf,
                Module.mode_organisation.in_(['elearning_async', 'elearning_sync'])
            ).distinct().count()
            
            # Skip ADFs with 0 e-learning modules (like "Bilan de compétences")
            # These courses can't have meaningful progression tracking
            if elearning_module_count == 0:
                continue
            
            participants_data = []
            for pc in participants_query:
                participant = pc.participant
                
                # Get modules for this participant in this ADF to calculate real progression
                participant_modules = db.query(Module).join(Course).filter(
                    Course.id_action_formation == id_adf,
                    Module.participant_id == participant.id
                ).all()
                
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
                    "overall_progression": round(calculated_progression, 2),
                    "activity_status": pc.activity_status,
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
                "mode_organisation": adf_course.mode_organisation,
                "total_modules": elearning_module_count,  # Count of unique e-learning modules by id_lam
                "participant_count": participant_count,
                "participants": participants_data,
                "average_progression": round(float(avg_progression), 2),
                "created_at": adf_course.created_at.isoformat() if adf_course.created_at else None,
                "updated_at": adf_course.updated_at.isoformat() if adf_course.updated_at else None
            })
        
        return result
        
    except Exception as e:
        logger.error(f"Error fetching courses: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch courses: {str(e)}")

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
            modules = db.query(Module).join(Course).filter(
                Course.id_action_formation == course.id_action_formation,
                Module.participant_id == participant.id
            ).all()
            
            # Calculate progression properly: average of all module progressions
            if modules:
                total_progression = sum(module.lms_progression for module in modules)
                calculated_progression = total_progression / len(modules)
            else:
                calculated_progression = 0.0
            
            # Calculate completed modules (progression >= 100)
            completed_modules = sum(1 for module in modules if module.lms_progression >= 100)
            total_modules = len(modules)
            
            # Get last activity from modules
            last_activity = None
            if modules:
                last_activities = [m.lms_last_access_at for m in modules if m.lms_last_access_at]
                if last_activities:
                    last_activity = max(last_activities).isoformat()
            
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
                "overall_progression": round(calculated_progression, 2),  # Use calculated progression
                "activity_status": pc.activity_status,
                "last_activity": last_activity,
                "completed_modules": completed_modules,
                "total_modules": total_modules,
                "hubspot_data": {
                    "c_url_transaction_hubspot": hubspot_data.c_url_transaction_hubspot if hubspot_data else None,
                    "c_id_transaction_hubspot": hubspot_data.c_id_transaction_hubspot if hubspot_data else None,
                    "id_lap": hubspot_data.id_lap if hubspot_data else None
                } if hubspot_data else None,
                "modules": [
                    {
                        "id": module.id,
                        "id_lmp": module.id_lmp,
                        "id_lam": module.id_lam,
                        "progression": module.lms_progression,
                        "last_access": module.lms_last_access_at.isoformat() if module.lms_last_access_at else None,
                        "mode_organisation": module.mode_organisation
                    } for module in modules
                ]
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
                "mode_organisation": course.mode_organisation,
                "total_modules": db.query(Module.id_lam).join(Course).filter(
                    Course.id_action_formation == course.id_action_formation,
                    Module.mode_organisation.in_(['elearning_async', 'elearning_sync'])
                ).distinct().count()  # Count unique e-learning modules by id_lam for the entire ADF
            },
            "participants": participants_data,
            "summary": {
                "total_participants": len(participants_data),
                "completed_participants": sum(1 for p in participants_data if p["overall_progression"] >= 100),
                "average_progression": sum(p["overall_progression"] for p in participants_data) / len(participants_data) if participants_data else 0
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
        participant = db.query(Participant).filter(Participant.id == participant_id).first()
        if not participant:
            raise HTTPException(status_code=404, detail="Participant not found")
        
        # Get all courses for this participant
        participant_courses = db.query(ParticipantCourse).filter(
            ParticipantCourse.participant_id == participant_id
        ).all()
        
        courses_data = []
        for pc in participant_courses:
            course = db.query(Course).filter(Course.id == pc.course_id).first()
            if not course:
                continue
            
            # Get modules for this participant in this ADF (not just this course)
            modules = db.query(Module).join(Course).filter(
                Course.id_action_formation == course.id_action_formation,
                Module.participant_id == participant.id
            ).all()
            
            completed_modules = sum(1 for module in modules if module.lms_progression >= 100)
            
            courses_data.append({
                "course_id": course.id,
                "course_title": course.intitule,
                "progression": pc.overall_progression,
                "activity_status": pc.activity_status,
                "last_activity": pc.last_activity.isoformat() if pc.last_activity else None,
                "completed_modules": completed_modules,
                "total_modules": len(modules)
            })
        
        return {
            "participant": {
                "id": participant.id,
                "id_participant": participant.id_participant,
                "nom": participant.nom,
                "prenom": participant.prenom,
                "email": participant.email,
                "created_at": participant.created_at.isoformat() if participant.created_at else None
            },
            "courses": courses_data,
            "summary": {
                "total_courses": len(courses_data),
                "completed_courses": sum(1 for c in courses_data if c["progression"] >= 100),
                "average_progression": sum(c["progression"] for c in courses_data) / len(courses_data) if courses_data else 0
            }
        }
        
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
