"""
Inactivity Tracking Service

Assesses participant inactivity based on learning progression changes over time,
not login/connection events. Uses rolling time windows to identify stalled learners.
"""

from sqlalchemy.orm import Session
from sqlalchemy import and_, or_
from datetime import datetime, timedelta, timezone
from typing import List, Dict, Optional
from app.models.models import Participant, ParticipantCourse, Course
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
        inactivity_threshold_days: int = 30,
        long_inactivity_threshold_days: int = 60,
        exclude_recent_enrollments_days: int = 7,
        at_risk_threshold_days: int = 21
    ):
        """
        Initialize inactivity service with configurable thresholds

        Args:
            db: Database session
            inactivity_threshold_days: Days without progress to be considered stalled (default: 30)
            long_inactivity_threshold_days: Days without progress for long-term inactive (default: 60)
            exclude_recent_enrollments_days: Exclude enrollments newer than this (default: 7)
            at_risk_threshold_days: Days without progress to be flagged as at-risk (default: 21)
        """
        self.db = db
        self.inactivity_threshold = inactivity_threshold_days
        self.long_inactivity_threshold = long_inactivity_threshold_days
        self.exclude_recent_threshold = exclude_recent_enrollments_days
        self.at_risk_threshold = at_risk_threshold_days

    def get_inactive_participants(
        self,
        group_by_course: bool = False,
        course_id: Optional[int] = None,
        min_progression: Optional[float] = None,
        max_progression: Optional[float] = None
    ) -> InactivitySummary:
        """
        Get inactive participants with optional course grouping

        Args:
            group_by_course: Whether to group results by course
            course_id: Filter by specific course ID
            min_progression: Only include participants with progression >= this value
            max_progression: Only include participants with progression <= this value

        Returns:
            InactivitySummary with participant details and statistics
        """
        now = datetime.now(timezone.utc)

        # Build query for participant courses
        query = (
            self.db.query(ParticipantCourse)
            .join(Participant, ParticipantCourse.participant_id == Participant.id)
            .join(Course, ParticipantCourse.course_id == Course.id)
            .filter(ParticipantCourse.last_activity.isnot(None))
        )

        # Apply filters
        if course_id:
            query = query.filter(ParticipantCourse.course_id == course_id)

        if min_progression is not None:
            query = query.filter(ParticipantCourse.overall_progression >= min_progression)

        if max_progression is not None:
            query = query.filter(ParticipantCourse.overall_progression <= max_progression)

        # Exclude completed courses (progression >= 100)
        query = query.filter(ParticipantCourse.overall_progression < 100.0)

        enrollments = query.all()

        # Statistics counters
        stats = {
            'total_checked': len(enrollments),
            'total_inactive': 0,
            'stalled': 0,
            'long_inactive': 0,
            'at_risk': 0,
            'newly_enrolled_excluded': 0,
            'completed_excluded': 0
        }

        # Collect inactive participants
        inactive_details: List[InactiveParticipantDetail] = []
        by_course_map: Dict[int, List[InactiveParticipantDetail]] = {}

        for enrollment in enrollments:
            # Calculate time metrics
            days_since_activity = (now - enrollment.last_activity).days if enrollment.last_activity else 999
            days_since_enrollment = (now - enrollment.created_at).days if enrollment.created_at else 0

            # Exclude recently enrolled participants (< 7 days by default)
            if days_since_enrollment < self.exclude_recent_threshold:
                stats['newly_enrolled_excluded'] += 1
                continue

            # Classify inactivity
            inactivity_status, inactivity_reason = self._classify_inactivity(
                days_since_activity=days_since_activity,
                progression=enrollment.overall_progression,
                days_since_enrollment=days_since_enrollment
            )

            # Skip if not inactive
            if inactivity_status == 'active':
                continue

            # Count inactive types
            stats['total_inactive'] += 1
            if inactivity_status == 'stalled':
                stats['stalled'] += 1
            elif inactivity_status == 'long_inactive':
                stats['long_inactive'] += 1
            elif inactivity_status == 'at_risk':
                stats['at_risk'] += 1

            # Create detail record
            detail = InactiveParticipantDetail(
                id=enrollment.participant.id,
                id_participant=enrollment.participant.id_participant,
                nom=enrollment.participant.nom,
                prenom=enrollment.participant.prenom,
                email=enrollment.participant.email,
                course_id=enrollment.course.id,
                course_title=enrollment.course.intitule,
                id_action_formation=enrollment.course.id_action_formation,
                current_progression=enrollment.overall_progression or 0.0,
                last_activity=enrollment.last_activity,
                days_inactive=days_since_activity,
                enrollment_date=enrollment.created_at,
                days_since_enrollment=days_since_enrollment,
                inactivity_status=inactivity_status,
                inactivity_reason=inactivity_reason
            )

            inactive_details.append(detail)

            # Group by course if requested
            if group_by_course:
                course_id_key = enrollment.course.id
                if course_id_key not in by_course_map:
                    by_course_map[course_id_key] = []
                by_course_map[course_id_key].append(detail)

        # Build response
        if group_by_course:
            grouped = self._build_course_groups(by_course_map)
            return InactivitySummary(
                total_participants_checked=stats['total_checked'],
                total_inactive=stats['total_inactive'],
                stalled_count=stats['stalled'],
                long_inactive_count=stats['long_inactive'],
                at_risk_count=stats['at_risk'],
                newly_enrolled_excluded=stats['newly_enrolled_excluded'],
                completed_excluded=stats['completed_excluded'],
                by_course=grouped,
                participants=None,
                inactivity_threshold_days=self.inactivity_threshold,
                long_inactivity_threshold_days=self.long_inactivity_threshold,
                exclude_recent_enrollments_days=self.exclude_recent_threshold
            )
        else:
            # Sort by days inactive (most inactive first)
            inactive_details.sort(key=lambda x: x.days_inactive, reverse=True)

            return InactivitySummary(
                total_participants_checked=stats['total_checked'],
                total_inactive=stats['total_inactive'],
                stalled_count=stats['stalled'],
                long_inactive_count=stats['long_inactive'],
                at_risk_count=stats['at_risk'],
                newly_enrolled_excluded=stats['newly_enrolled_excluded'],
                completed_excluded=stats['completed_excluded'],
                by_course=None,
                participants=inactive_details,
                inactivity_threshold_days=self.inactivity_threshold,
                long_inactivity_threshold_days=self.long_inactivity_threshold,
                exclude_recent_enrollments_days=self.exclude_recent_threshold
            )

    def _classify_inactivity(
        self,
        days_since_activity: int,
        progression: float,
        days_since_enrollment: int
    ) -> tuple[str, str]:
        """
        Classify inactivity status based on progression-based criteria

        Args:
            days_since_activity: Days since last activity (progression update)
            progression: Current progression percentage
            days_since_enrollment: Days since enrollment

        Returns:
            Tuple of (status, reason)
        """
        # Active: Recent activity within threshold
        if days_since_activity < self.at_risk_threshold:
            return ('active', 'Recent activity detected')

        # At-risk: 21-29 days without activity (warning stage)
        if self.at_risk_threshold <= days_since_activity < self.inactivity_threshold:
            return (
                'at_risk',
                f'No progression update for {days_since_activity} days (at-risk threshold)'
            )

        # Stalled: 30-59 days without activity
        if self.inactivity_threshold <= days_since_activity < self.long_inactivity_threshold:
            return (
                'stalled',
                f'No progression update for {days_since_activity} days (stalled)'
            )

        # Long inactive: 60+ days without activity
        if days_since_activity >= self.long_inactivity_threshold:
            return (
                'long_inactive',
                f'No progression update for {days_since_activity} days (long-term inactive)'
            )

        return ('active', 'Active')

    def _build_course_groups(
        self,
        by_course_map: Dict[int, List[InactiveParticipantDetail]]
    ) -> List[InactiveParticipantsByCourse]:
        """Build course-grouped response from map"""
        grouped = []

        for course_id, participants in by_course_map.items():
            # Get course info from first participant
            if not participants:
                continue

            first = participants[0]

            # Count by type
            stalled = sum(1 for p in participants if p.inactivity_status == 'stalled')
            long_inactive = sum(1 for p in participants if p.inactivity_status == 'long_inactive')
            at_risk = sum(1 for p in participants if p.inactivity_status == 'at_risk')

            # Sort participants by days inactive
            participants.sort(key=lambda x: x.days_inactive, reverse=True)

            grouped.append(InactiveParticipantsByCourse(
                course_id=course_id,
                course_title=first.course_title,
                id_action_formation=first.id_action_formation,
                total_inactive=len(participants),
                stalled_count=stalled,
                long_inactive_count=long_inactive,
                at_risk_count=at_risk,
                participants=participants
            ))

        # Sort courses by total inactive count (most inactive first)
        grouped.sort(key=lambda x: x.total_inactive, reverse=True)

        return grouped
