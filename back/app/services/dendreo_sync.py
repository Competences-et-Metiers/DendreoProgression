import httpx
import logging
from datetime import datetime
from typing import List, Dict, Optional
from sqlalchemy.orm import Session
from sqlalchemy import and_

from app.config.settings import settings
from app.models.models import Participant, Course, Module, ModuleProgression, CourseProgression
from app.models.database import SessionLocal

logger = logging.getLogger(__name__)

class DendreoSyncService:
    def __init__(self):
        self.base_url = settings.dendreo_base_url
        self.api_key = settings.dendreo_api_key

    async def fetch_dendreo_data(self) -> Dict:
        """Fetch all data from Dendreo API"""
        url = f"{self.base_url}/lmps.php"
        params = {
            "key": self.api_key,
            "include": "participant,module"
        }

        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                response = await client.get(url, params=params)
                response.raise_for_status()
                data = response.json()
                logger.info(f"Fetched {len(data.get('lmps', []))} LMPs from Dendreo")
                return data
        except Exception as e:
            logger.error(f"Error fetching Dendreo data: {e}")
            raise

    def sync_participants(self, db: Session, lmp_data: Dict) -> int:
        """Sync participants from LMP data"""
        synced_count = 0

        for lmp in lmp_data.get("lmps", []):
            for participant_data in lmp.get("participants", []):
                try:
                    # Check if participant exists
                    existing = db.query(Participant).filter(
                        Participant.id_participant == participant_data["id_participant"]
                    ).first()

                    if existing:
                        # Update existing participant
                        existing.nom = participant_data.get("nom", "")
                        existing.prenom = participant_data.get("prenom", "")
                        existing.email = participant_data.get("email", "")
                        existing.portable = participant_data.get("portable")
                        existing.civilite = participant_data.get("civilite")
                        existing.adresse = participant_data.get("adresse")
                        existing.code_postal = participant_data.get("code_postal")
                        existing.ville = participant_data.get("ville")
                        existing.pays = participant_data.get("pays")
                        existing.entreprise = participant_data.get("ent_raison_sociale")
                        existing.updated_at = datetime.utcnow()
                    else:
                        # Create new participant
                        new_participant = Participant(
                            id_participant=participant_data["id_participant"],
                            nom=participant_data.get("nom", ""),
                            prenom=participant_data.get("prenom", ""),
                            email=participant_data.get("email", ""),
                            portable=participant_data.get("portable"),
                            civilite=participant_data.get("civilite"),
                            adresse=participant_data.get("adresse"),
                            code_postal=participant_data.get("code_postal"),
                            ville=participant_data.get("ville"),
                            pays=participant_data.get("pays"),
                            entreprise=participant_data.get("ent_raison_sociale")
                        )
                        db.add(new_participant)

                    synced_count += 1

                except Exception as e:
                    logger.error(f"Error syncing participant {participant_data.get('id_participant', 'unknown')}: {e}")
                    continue

        db.commit()
        logger.info(f"Synced {synced_count} participants")
        return synced_count

    def sync_courses_and_modules(self, db: Session, lmp_data: Dict) -> tuple[int, int]:
        """Sync courses (LMPs) and their modules"""
        courses_synced = 0
        modules_synced = 0

        for lmp in lmp_data.get("lmps", []):
            try:
                # Sync Course (LMP)
                existing_course = db.query(Course).filter(
                    Course.id_lam == lmp["id_lam"]
                ).first()

                # Parse dates
                date_debut = None
                date_fin = None
                try:
                    if lmp.get("date_debut"):
                        date_debut = datetime.strptime(lmp["date_debut"], "%Y-%m-%d %H:%M:%S")
                    if lmp.get("date_fin"):
                        date_fin = datetime.strptime(lmp["date_fin"], "%Y-%m-%d %H:%M:%S")
                except:
                    pass

                if existing_course:
                    # Update existing course
                    existing_course.intitule = lmp.get("intitule", "")
                    existing_course.description = lmp.get("description", "")
                    existing_course.type_lam = lmp.get("type_lam")
                    existing_course.date_debut = date_debut
                    existing_course.date_fin = date_fin
                    existing_course.duree_heures = float(lmp.get("duree_heures", 0)) if lmp.get("duree_heures") else None
                    existing_course.prix = float(lmp.get("prix", 0)) if lmp.get("prix") else None
                    existing_course.quantite = float(lmp.get("quantite", 0)) if lmp.get("quantite") else None
                    existing_course.updated_at = datetime.utcnow()
                else:
                    # Create new course
                    new_course = Course(
                        id_lam=lmp["id_lam"],
                        intitule=lmp.get("intitule", ""),
                        description=lmp.get("description", ""),
                        type_lam=lmp.get("type_lam"),
                        date_debut=date_debut,
                        date_fin=date_fin,
                        duree_heures=float(lmp.get("duree_heures", 0)) if lmp.get("duree_heures") else None,
                        prix=float(lmp.get("prix", 0)) if lmp.get("prix") else None,
                        quantite=float(lmp.get("quantite", 0)) if lmp.get("quantite") else None
                    )
                    db.add(new_course)

                courses_synced += 1

                # Sync Modules
                for module_data in lmp.get("modules", []):
                    try:
                        existing_module = db.query(Module).filter(
                            Module.id_module == module_data["id_module"]
                        ).first()

                        if existing_module:
                            # Update existing module
                            existing_module.id_lam = lmp["id_lam"]
                            existing_module.intitule = module_data.get("intitule", "")
                            existing_module.description = module_data.get("description", "")
                            existing_module.ordre = int(module_data.get("ordre", 0)) if module_data.get("ordre") else None
                            existing_module.duree_heures = float(module_data.get("duree_heures", 0)) if module_data.get("duree_heures") else None
                            existing_module.prix = float(module_data.get("prix", 0)) if module_data.get("prix") else None
                            existing_module.quantite = float(module_data.get("quantite", 0)) if module_data.get("quantite") else None
                            existing_module.updated_at = datetime.utcnow()
                        else:
                            # Create new module
                            new_module = Module(
                                id_module=module_data["id_module"],
                                id_lam=lmp["id_lam"],
                                intitule=module_data.get("intitule", ""),
                                description=module_data.get("description", ""),
                                ordre=int(module_data.get("ordre", 0)) if module_data.get("ordre") else None,
                                duree_heures=float(module_data.get("duree_heures", 0)) if module_data.get("duree_heures") else None,
                                prix=float(module_data.get("prix", 0)) if module_data.get("prix") else None,
                                quantite=float(module_data.get("quantite", 0)) if module_data.get("quantite") else None
                            )
                            db.add(new_module)

                        modules_synced += 1

                    except Exception as e:
                        logger.error(f"Error syncing module {module_data.get('id_module', 'unknown')}: {e}")
                        continue

            except Exception as e:
                logger.error(f"Error syncing course {lmp.get('id_lam', 'unknown')}: {e}")
                continue

        db.commit()
        logger.info(f"Synced {courses_synced} courses and {modules_synced} modules")
        return courses_synced, modules_synced

    def sync_module_progressions(self, db: Session, lmp_data: Dict) -> int:
        """Sync module progressions from LMP data"""
        progressions_synced = 0

        for lmp in lmp_data.get("lmps", []):
            for participant_data in lmp.get("participants", []):
                participant_id = participant_data["id_participant"]

                for module_data in lmp.get("modules", []):
                    module_id = module_data["id_module"]

                    try:
                        # Check if progression exists
                        existing = db.query(ModuleProgression).filter(
                            and_(
                                ModuleProgression.id_participant == participant_id,
                                ModuleProgression.id_module == module_id
                            )
                        ).first()

                        # Parse progression data
                        progression = float(module_data.get("progression", 0)) if module_data.get("progression") else 0.0
                        temps_passe = int(module_data.get("temps_passe_secondes", 0)) if module_data.get("temps_passe_secondes") else 0
                        is_completed = progression >= 100.0

                        # Parse last connection date
                        date_derniere_connexion = None
                        if module_data.get("date_derniere_connexion"):
                            try:
                                date_derniere_connexion = datetime.strptime(
                                    module_data["date_derniere_connexion"],
                                    "%Y-%m-%d %H:%M:%S"
                                )
                            except:
                                pass

                        if existing:
                            # Update existing progression
                            existing.progression = progression
                            existing.date_derniere_connexion = date_derniere_connexion
                            existing.temps_passe_secondes = temps_passe
                            existing.is_completed = is_completed
                            existing.updated_at = datetime.utcnow()
                        else:
                            # Create new progression
                            new_progression = ModuleProgression(
                                id_participant=participant_id,
                                id_module=module_id,
                                progression=progression,
                                date_derniere_connexion=date_derniere_connexion,
                                temps_passe_secondes=temps_passe,
                                is_completed=is_completed
                            )
                            db.add(new_progression)

                        progressions_synced += 1

                    except Exception as e:
                        logger.error(f"Error syncing progression for participant {participant_id}, module {module_id}: {e}")
                        continue

        db.commit()
        logger.info(f"Synced {progressions_synced} module progressions")
        return progressions_synced

    def calculate_course_progressions(self, db: Session) -> int:
        """Calculate course progressions based on module progressions"""
        calculated_count = 0

        # Get all participants
        participants = db.query(Participant).all()

        for participant in participants:
            # Get all courses this participant is enrolled in
            courses_query = db.query(Course).join(
                Module, Course.id_lam == Module.id_lam
            ).join(
                ModuleProgression,
                and_(
                    ModuleProgression.id_module == Module.id_module,
                    ModuleProgression.id_participant == participant.id_participant
                )
            ).distinct()

            courses = courses_query.all()

            for course in courses:
                try:
                    # Get all modules for this course
                    modules = db.query(Module).filter(Module.id_lam == course.id_lam).all()

                    # Get progressions for this participant's modules in this course
                    progressions = db.query(ModuleProgression).filter(
                        and_(
                            ModuleProgression.id_participant == participant.id_participant,
                            ModuleProgression.id_module.in_([m.id_module for m in modules])
                        )
                    ).all()

                    if not progressions:
                        continue

                    # Calculate average progress
                    total_progress = sum([p.progression for p in progressions])
                    avg_progress = total_progress / len(progressions) if progressions else 0.0

                    # Determine activity status
                    activity_status = self._determine_activity_status(progressions)

                    # Find latest activity date
                    latest_activity = max([
                        p.date_derniere_connexion for p in progressions
                        if p.date_derniere_connexion
                    ], default=None)

                    # Check if course progression exists
                    existing_course_prog = db.query(CourseProgression).filter(
                        and_(
                            CourseProgression.id_participant == participant.id_participant,
                            CourseProgression.id_lam == course.id_lam
                        )
                    ).first()

                    if existing_course_prog:
                        # Update existing
                        existing_course_prog.progression = avg_progress
                        existing_course_prog.activity_status = activity_status
                        existing_course_prog.last_activity_date = latest_activity
                        existing_course_prog.updated_at = datetime.utcnow()
                    else:
                        # Create new
                        new_course_prog = CourseProgression(
                            id_participant=participant.id_participant,
                            id_lam=course.id_lam,
                            progression=avg_progress,
                            activity_status=activity_status,
                            last_activity_date=latest_activity
                        )
                        db.add(new_course_prog)

                    calculated_count += 1

                except Exception as e:
                    logger.error(f"Error calculating course progression for participant {participant.id_participant}, course {course.id_lam}: {e}")
                    continue

        db.commit()
        logger.info(f"Calculated {calculated_count} course progressions")
        return calculated_count

    def _determine_activity_status(self, progressions: List[ModuleProgression]) -> str:
        """Determine activity status based on module progressions"""
        if not progressions:
            return "inactive"

        # If all modules are completed
        if all(p.is_completed for p in progressions):
            return "completed"

        # Check for recent activity (within 30 days)
        recent_activity = False
        for prog in progressions:
            if prog.date_derniere_connexion:
                days_since_activity = (datetime.utcnow() - prog.date_derniere_connexion).days
                if days_since_activity <= 30:
                    recent_activity = True
                    break

        return "active" if recent_activity else "inactive"

    async def full_sync(self) -> Dict:
        """Perform a full synchronization"""
        db = SessionLocal()
        try:
            logger.info("Starting full Dendreo synchronization...")

            # Fetch data from Dendreo
            lmp_data = await self.fetch_dendreo_data()

            # Sync all data
            participants_count = self.sync_participants(db, lmp_data)
            courses_count, modules_count = self.sync_courses_and_modules(db, lmp_data)
            progressions_count = self.sync_module_progressions(db, lmp_data)
            course_progressions_count = self.calculate_course_progressions(db)

            result = {
                "status": "success",
                "timestamp": datetime.utcnow().isoformat(),
                "synced_counts": {
                    "participants": participants_count,
                    "courses": courses_count,
                    "modules": modules_count,
                    "module_progressions": progressions_count,
                    "course_progressions": course_progressions_count
                },
                "lmps_processed": len(lmp_data.get("lmps", []))
            }

            logger.info("Full synchronization completed successfully")
            return result

        except Exception as e:
            logger.error(f"Error during full sync: {e}")
            db.rollback()
            raise
        finally:
            db.close()
