"""
Inactivity Tracking Service

Assesses participant inactivity based on learning progression changes over time,
not login/connection events. Uses two thresholds to classify participants as
active, at_risk, or inactive.
"""

from sqlalchemy.orm import Session
from datetime import datetime, timezone
from typing import List, Dict, Optional
from app.models.models import Participant, ParticipantCourse, Course, Module, Creneau, CreneauParticipant
from app.models.schemas import (
    InactiveParticipantDetail,
    InactiveParticipantsByCourse,
    InactivitySummary
)
import logging

logger = logging.getLogger(__name__)


class InactivityService:
    """Service for tracking and reporting participant inactivity"""

    def __init__(
        self,
        db: Session,
        at_risk_threshold_days: int = 14,
        inactivity_threshold_days: int = 30,
        exclude_recent_enrollments_days: int = 7
    ):
        self.db = db
        self.at_risk_threshold = at_risk_threshold_days
        self.inactivity_threshold = inactivity_threshold_days
        self.exclude_recent_threshold = exclude_recent_enrollments_days

    def get_participants(
        self,
        group_by_course: bool = False,
        course_id: Optional[int] = None,
        min_progression: Optional[float] = None,
        max_progression: Optional[float] = None
    ) -> InactivitySummary:
        """
        Get all non-completed participants grouped by ADF, classified as
        active / at_risk / inactive.
        """
        now = datetime.now(timezone.utc)

        query = (
            self.db.query(ParticipantCourse, Participant, Course)
            .join(Participant, ParticipantCourse.participant_id == Participant.id)
            .join(Course, ParticipantCourse.course_id == Course.id)
            .filter(ParticipantCourse.last_activity.isnot(None))
        )

        if course_id:
            course = self.db.query(Course).filter(Course.id == course_id).first()
            if course:
                query = query.filter(Course.id_action_formation == course.id_action_formation)

        enrollments = query.all()

        # Group by (participant_id, id_action_formation) to aggregate LAMs
        adf_groups = {}
        for pc, participant, course in enrollments:
            key = (participant.id, course.id_action_formation)
            if key not in adf_groups:
                adf_groups[key] = {
                    'participant': participant,
                    'adf_id': course.id_action_formation,
                    'adf_title': course.intitule,
                    'enrollments': []
                }
            adf_groups[key]['enrollments'].append({
                'participant_course': pc,
                'course': course
            })

        stats = {
            'total_checked': len(adf_groups),
            'active': 0,
            'at_risk': 0,
            'inactive': 0,
            'newly_enrolled_excluded': 0
        }

        all_details: List[InactiveParticipantDetail] = []
        by_course_map: Dict[str, List[InactiveParticipantDetail]] = {}

        for (participant_id, adf_id), group_data in adf_groups.items():
            participant = group_data['participant']
            enrollments = group_data['enrollments']

            # E-learning last activity
            elearning_last_activities = [e['participant_course'].last_activity for e in enrollments
                             if e['participant_course'].last_activity]
            last_elearning = max(elearning_last_activities) if elearning_last_activities else None

            # Liveroom last attended (only sessions where participant was present)
            last_liveroom = self._get_last_liveroom_date(participant_id, adf_id)

            # Determine effective last activity and its source
            last_activity = None
            last_activity_source = None

            if last_elearning and last_liveroom:
                if last_elearning >= last_liveroom:
                    last_activity = last_elearning
                    last_activity_source = "elearning"
                else:
                    last_activity = last_liveroom
                    last_activity_source = "classe_virtuelle"
            elif last_elearning:
                last_activity = last_elearning
                last_activity_source = "elearning"
            elif last_liveroom:
                last_activity = last_liveroom
                last_activity_source = "classe_virtuelle"

            if not last_activity:
                continue

            # Get earliest enrollment date (prefer date_add from Dendreo, fallback to created_at)
            enrollment_dates = []
            for e in enrollments:
                pc = e['participant_course']
                date = pc.date_add if pc.date_add else pc.created_at
                if date:
                    enrollment_dates.append(date)
            enrollment_date = min(enrollment_dates) if enrollment_dates else None

            total_duration = sum(e['course'].planned_duration_hours or 0.0 for e in enrollments)

            # Query all LAMs for this ADF (same as course detail page)
            adf_lam_rows = self.db.query(Course.id_lam).filter(
                Course.id_action_formation == adf_id
            ).distinct().all()
            lam_ids = [row[0] for row in adf_lam_rows if row[0]]
            if lam_ids:
                all_modules = self.db.query(Module).filter(
                    Module.participant_id == participant.id,
                    Module.id_lam.in_(lam_ids)
                ).all()
            else:
                all_modules = []

            elearning_modules = [m for m in all_modules if m.mode_organisation == 'elearning_async']
            total_time_spent_seconds = sum(m.lms_time_spent or 0 for m in all_modules)
            total_time_spent_hours = total_time_spent_seconds / 3600.0

            # Compute progression from e-learning module data (same as course detail page)
            if elearning_modules:
                avg_progression = sum(m.lms_progression or 0 for m in elearning_modules) / len(elearning_modules)
            else:
                avg_progression = 0.0

            # Skip fully completed participants
            if avg_progression >= 100.0:
                continue

            if min_progression is not None and avg_progression < min_progression:
                continue
            if max_progression is not None and avg_progression > max_progression:
                continue

            days_since_activity = (now - last_activity).days if last_activity else 999
            days_since_enrollment = (now - enrollment_date).days if enrollment_date else 0

            # Exclude recently enrolled participants
            if days_since_enrollment < self.exclude_recent_threshold:
                stats['newly_enrolled_excluded'] += 1
                continue

            inactivity_status, inactivity_reason = self._classify(days_since_activity)

            stats[inactivity_status] += 1

            formateurs = enrollments[0]['course'].formateurs if enrollments[0]['course'].formateurs else None

            detail = InactiveParticipantDetail(
                id=participant.id,
                id_participant=participant.id_participant,
                nom=participant.nom,
                prenom=participant.prenom,
                email=participant.email,
                course_id=enrollments[0]['course'].id,
                course_title=group_data['adf_title'],
                id_action_formation=adf_id,
                total_modules=len(enrollments),
                total_planned_duration_hours=total_duration,
                total_time_spent_hours=total_time_spent_hours,
                current_progression=avg_progression,
                last_activity=last_activity,
                last_activity_source=last_activity_source,
                days_inactive=days_since_activity,
                enrollment_date=enrollment_date,
                days_since_enrollment=days_since_enrollment,
                inactivity_status=inactivity_status,
                inactivity_reason=inactivity_reason,
                formateurs=formateurs
            )

            all_details.append(detail)

            if group_by_course:
                if adf_id not in by_course_map:
                    by_course_map[adf_id] = []
                by_course_map[adf_id].append(detail)

        total_participants = stats['active'] + stats['at_risk'] + stats['inactive']

        summary_kwargs = dict(
            total_participants_checked=stats['total_checked'],
            total_participants=total_participants,
            active_count=stats['active'],
            at_risk_count=stats['at_risk'],
            inactive_count=stats['inactive'],
            newly_enrolled_excluded=stats['newly_enrolled_excluded'],
            at_risk_threshold_days=self.at_risk_threshold,
            inactivity_threshold_days=self.inactivity_threshold,
            exclude_recent_enrollments_days=self.exclude_recent_threshold
        )

        if group_by_course:
            grouped = self._build_adf_groups(by_course_map)
            return InactivitySummary(by_course=grouped, participants=None, **summary_kwargs)
        else:
            all_details.sort(key=lambda x: x.days_inactive, reverse=True)
            return InactivitySummary(by_course=None, participants=all_details, **summary_kwargs)

    def _get_last_liveroom_date(self, participant_id: int, adf_id: str) -> Optional[datetime]:
        """
        Get the most recent creneau date_fin where the participant was present (presence='1')
        for a given ADF. Excludes future sessions.
        """
        now = datetime.now(timezone.utc)
        result = (
            self.db.query(Creneau.date_fin)
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

    def _classify(self, days_since_activity: int) -> tuple[str, str]:
        """Classify into active / at_risk / inactive based on days since last activity."""
        if days_since_activity < self.at_risk_threshold:
            return ('active', 'Recent activity detected')

        if days_since_activity < self.inactivity_threshold:
            return (
                'at_risk',
                f'No activity for {days_since_activity} days'
            )

        return (
            'inactive',
            f'No activity for {days_since_activity} days'
        )

    def _build_adf_groups(
        self,
        by_adf_map: Dict[str, List[InactiveParticipantDetail]]
    ) -> List[InactiveParticipantsByCourse]:
        """Build ADF-grouped response from map"""
        grouped = []

        for adf_id, participants in by_adf_map.items():
            if not participants:
                continue

            first = participants[0]

            active = sum(1 for p in participants if p.inactivity_status == 'active')
            at_risk = sum(1 for p in participants if p.inactivity_status == 'at_risk')
            inactive = sum(1 for p in participants if p.inactivity_status == 'inactive')

            participants.sort(key=lambda x: x.days_inactive, reverse=True)

            grouped.append(InactiveParticipantsByCourse(
                course_id=first.course_id or 0,
                course_title=first.course_title,
                id_action_formation=adf_id,
                total_participants=len(participants),
                active_count=active,
                at_risk_count=at_risk,
                inactive_count=inactive,
                participants=participants
            ))

        grouped.sort(key=lambda x: x.inactive_count, reverse=True)
        return grouped
