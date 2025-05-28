import logging
from datetime import datetime, timedelta
from typing import List, Dict, Any
from app.models.schemas import CourseProgressResponse
from app.config.settings import settings  # Remove 'back.' prefix

logger = logging.getLogger(__name__)

class DataProcessor:
    def __init__(self):
        self.inactivity_threshold_days = 7  # Consider inactive after 7 days

    def calculate_course_progression(self, modules_data: List[Dict[str, Any]]) -> float:
        """Calculate average progression across all modules in a course"""
        if not modules_data:
            return 0.0

        total_progression = 0.0
        module_count = 0

        for module in modules_data:
            progression = float(module.get("progression", 0))
            total_progression += progression
            module_count += 1

        return total_progression / module_count if module_count > 0 else 0.0

    def determine_activity_status(self, modules_data: List[Dict[str, Any]], course_progression: float) -> str:
        """Determine if participant is active, inactive, or completed"""

        # If course is 100% complete, mark as completed
        if course_progression >= 100.0:
            return "completed"

        # Find the latest incomplete module connection
        latest_connection = None
        has_incomplete_modules = False

        for module in modules_data:
            progression = float(module.get("progression", 0))
            if progression < 100.0:
                has_incomplete_modules = True
                connection_str = module.get("derniere_connexion")
                if connection_str:
                    try:
                        connection_date = datetime.strptime(connection_str, "%Y-%m-%d %H:%M:%S")
                        if latest_connection is None or connection_date > latest_connection:
                            latest_connection = connection_date
                    except ValueError:
                        logger.warning(f"Invalid date format: {connection_str}")

        # If no incomplete modules, should be completed
        if not has_incomplete_modules:
            return "completed"

        # If no connection data available for incomplete modules, consider inactive
        if latest_connection is None:
            return "inactive"

        # Check if latest connection is within threshold
        threshold_date = datetime.now() - timedelta(days=self.inactivity_threshold_days)

        if latest_connection >= threshold_date:
            return "active"
        else:
            return "inactive"

    def process_lmp_data(self, lmp_data: Dict[str, Any]) -> List[CourseProgressResponse]:
        """Process LMP data into course progress responses"""
        results = []

        course_intitule = lmp_data.get("intitule", "Unknown Course")
        id_lam = lmp_data.get("id_lam", "")
        participants = lmp_data.get("participants", [])
        modules = lmp_data.get("modules", [])

        for participant in participants:
            # Get participant's modules data (this would need to be filtered by participant)
            participant_modules = []  # This needs proper filtering logic

            # Calculate progression
            progression = self.calculate_course_progression(participant_modules)

            # Determine activity status
            status = self.determine_activity_status(participant_modules, progression)

            # Create response object
            course_progress = CourseProgressResponse(
                course_intitule=course_intitule,
                participant_nom=participant.get("nom", ""),
                participant_prenom=participant.get("prenom", ""),
                participant_email=participant.get("email", ""),
                progression=progression,
                id_transaction=participant.get("c_id_transaction_hubspot", ""),
                url_transaction=participant.get("c_url_transaction_hubspot", ""),
                id_lam=id_lam,
                activity_status=status
            )

            results.append(course_progress)

        return results

# Create processor instance
data_processor = DataProcessor()
