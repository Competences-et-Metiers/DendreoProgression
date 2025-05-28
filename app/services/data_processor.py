import logging
from typing import List, Dict, Any, Tuple
from sqlalchemy.orm import Session
from app.models.database import Participant, Course, ParticipantProgression
from app.models.schemas import DendreoADF, DendreoParticipant
from app.services.dendreo_client import DendreoClient
from app.services.hubspot_client import HubSpotClient

logger = logging.getLogger(__name__)

class DataProcessor:
    def __init__(self, db: Session):
        self.db = db
        self.dendreo_client = DendreoClient()
        self.hubspot_client = HubSpotClient()

    async def close(self):
        await self.dendreo_client.close()
        await self.hubspot_client.close()

    def calculate_course_progression(self, modules: List[Dict[str, Any]]) -> float:
        """Calculate average progression across all modules in a course"""
        if not modules:
            return 0.0

        total_progression = 0.0
        module_count = 0

        for module in modules:
            progression = float(module.get("lms_progression", "0.00"))
            total_progression += progression
            module_count += 1

        return total_progression / module_count if module_count > 0 else 0.0

    def determine_activity_status(self, progression: float) -> str:
        """Determine participant activity status based on progression"""
        if progression >= 100.0:
            return "completed"
        elif progression > 0.0:
            return "active"
        else:
            return "inactive"

    async def sync_dendreo_data(self) -> Tuple[int, int, List[str]]:
        """Main method to sync all data from Dendreo API"""
        errors = []
        processed_courses = 0
        processed_participants = 0

        try:
            # Get all active ADFs
            active_adfs = await self.dendreo_client.get_actions_de_formation()
            logger.info(f"Processing {len(active_adfs)} active ADFs")

            # Get LMPS data for progression calculation
            lmps_data = await self.dendreo_client.get_lmps()
            lmps_by_lam = {lmp.get("id_lam"): lmp for lmp in lmps_data}

            for adf in active_adfs:
                try:
                    # Process course data
                    await self._process_course(adf)
                    processed_courses += 1

                    # Get detailed participant data with HubSpot properties
                    participants = await self.dendreo_client.get_laps(adf.id_action_de_formation)

                    for participant in participants:
                        try:
                            await self._process_participant_progression(
                                adf, participant, lmps_by_lam
                            )
                            processed_participants += 1
                        except Exception as e:
                            error_msg = f"Error processing participant {participant.id_participant}: {e}"
                            logger.error(error_msg)
                            errors.append(error_msg)

                except Exception as e:
                    error_msg = f"Error processing ADF {adf.id_action_de_formation}: {e}"
                    logger.error(error_msg)
                    errors.append(error_msg)

            self.db.commit()
            logger.info(f"Sync completed: {processed_courses} courses, {processed_participants} participants")

        except Exception as e:
            error_msg = f"Critical error during sync: {e}"
            logger.error(error_msg)
            errors.append(error_msg)
            self.db.rollback()

        return processed_courses, processed_participants, errors

    async def _process_course(self, adf: DendreoADF):
        """Process and store course data"""
        for module in adf.modules:
            # Calculate course progression and status
            progression = self.calculate_course_progression([module.__dict__])
            status = self.determine_activity_status(progression)

            # Update or create course record
            course = self.db.query(Course).filter(Course.id_lam == module.id_lam).first()
            if course:
                course.intitule = adf.intitule
                course.etat = status
            else:
                course = Course(
                    id_lam=module.id_lam,
                    intitule=adf.intitule,
                    etat=status
                )
                self.db.add(course)

    async def _process_participant_progression(
            self, adf: DendreoADF, participant: DendreoParticipant, lmps_by_lam: Dict[str, Any]
    ):
        """Process participant progression and update HubSpot"""
        # Calculate overall course progression for this participant
        total_progression = 0.0
        module_count = 0

        for module in adf.modules:
            lmp_data = lmps_by_lam.get(module.id_lam)
            if lmp_data and lmp_data.get("participant", {}).get("id_participant") == participant.id_participant:
                progression = float(lmp_data.get("lms_progression", "0.00"))
                total_progression += progression
                module_count += 1

        average_progression = total_progression / module_count if module_count > 0 else 0.0

        # Update or create participant record
        db_participant = self.db.query(Participant).filter(
            Participant.id_participant == participant.id_participant
        ).first()

        if db_participant:
            db_participant.nom = participant.nom
            db_participant.prenom = participant.prenom
            db_participant.email = participant.email
            db_participant.url_transac = participant.c_url_transaction_hubspot
            db_participant.id_transac = participant.c_id_transaction_hubspot
        else:
            db_participant = Participant(
                id_participant=participant.id_participant,
                nom=participant.nom,
                prenom=participant.prenom,
                email=participant.email,
                url_transac=participant.c_url_transaction_hubspot,
                id_transac=participant.c_id_transaction_hubspot
            )
            self.db.add(db_participant)

        # Update progression records for each module
        for module in adf.modules:
            lmp_data = lmps_by_lam.get(module.id_lam)
            module_progression = 0.0

            if lmp_data and lmp_data.get("participant", {}).get("id_participant") == participant.id_participant:
                module_progression = float(lmp_data.get("lms_progression", "0.00"))

            progression_record = self.db.query(ParticipantProgression).filter(
                ParticipantProgression.participant_email == participant.email,
                ParticipantProgression.id_lam == module.id_lam
            ).first()

            if progression_record:
                progression_record.course_intitule = adf.intitule
                progression_record.participant_nom = participant.nom
                progression_record.participant_prenom = participant.prenom
                progression_record.progression = module_progression
                progression_record.id_transac = participant.c_id_transaction_hubspot
                progression_record.url_transac = participant.c_url_transaction_hubspot
            else:
                progression_record = ParticipantProgression(
                    course_intitule=adf.intitule,
                    participant_nom=participant.nom,
                    participant_prenom=participant.prenom,
                    participant_email=participant.email,
                    progression=module_progression,
                    id_transac=participant.c_id_transaction_hubspot,
                    url_transac=participant.c_url_transaction_hubspot,
                    id_lam=module.id_lam
                )
                self.db.add(progression_record)

        # Update HubSpot if transaction ID exists
        if participant.c_id_transaction_hubspot:
            await self.hubspot_client.update_transaction_progression(
                participant.c_id_transaction_hubspot, average_progression
            )
