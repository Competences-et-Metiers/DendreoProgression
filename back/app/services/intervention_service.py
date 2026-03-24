"""
Intervention Service

Handles CRUD operations and business logic for staff interventions
on inactive participants (snooze, note, email, call, dismiss).
"""

from sqlalchemy.orm import Session
from sqlalchemy import and_
from datetime import datetime, timezone, timedelta
from typing import List, Optional, Set, Tuple, Dict
from app.models.models import Intervention, Participant, User
from app.models.schemas import InterventionCreate, InterventionResponse
import logging

logger = logging.getLogger(__name__)


class InterventionService:
    """Service for managing participant interventions."""

    def __init__(self, db: Session):
        self.db = db

    def create_intervention(
        self,
        user_id: int,
        data: InterventionCreate,
        hubspot_note_id: Optional[str] = None
    ) -> InterventionResponse:
        """Create a new intervention record.

        For snooze type: computes snooze_until from details.snooze_days.
        For dismiss type: checks no existing active dismiss for this participant+ADF.
        """
        # Validate participant exists
        participant = self.db.query(Participant).filter(
            Participant.id == data.participant_id
        ).first()
        if not participant:
            raise ValueError(f"Participant {data.participant_id} not found")

        snooze_until = None
        if data.intervention_type == 'snooze' and data.details:
            snooze_days = data.details.get('snooze_days', 0)
            if snooze_days > 0:
                snooze_until = datetime.now(timezone.utc) + timedelta(days=snooze_days)

        if data.intervention_type == 'dismiss' and data.id_action_formation:
            existing = self.db.query(Intervention).filter(
                and_(
                    Intervention.participant_id == data.participant_id,
                    Intervention.id_action_formation == data.id_action_formation,
                    Intervention.intervention_type == 'dismiss',
                    Intervention.is_active == True
                )
            ).first()
            if existing:
                raise ValueError("Participant is already dismissed for this ADF")

        intervention = Intervention(
            participant_id=data.participant_id,
            participant_course_id=data.participant_course_id,
            id_action_formation=data.id_action_formation,
            user_id=user_id,
            intervention_type=data.intervention_type,
            details=data.details,
            hubspot_note_id=hubspot_note_id,
            snooze_until=snooze_until,
            is_active=True,
        )

        self.db.add(intervention)
        self.db.commit()
        self.db.refresh(intervention)

        # Fetch user display name
        user = self.db.query(User).filter(User.id == user_id).first()

        return InterventionResponse(
            id=intervention.id,
            participant_id=intervention.participant_id,
            participant_course_id=intervention.participant_course_id,
            id_action_formation=intervention.id_action_formation,
            user_id=intervention.user_id,
            user_display_name=user.display_name or user.username if user else None,
            intervention_type=intervention.intervention_type,
            details=intervention.details,
            hubspot_note_id=intervention.hubspot_note_id,
            snooze_until=intervention.snooze_until,
            is_active=intervention.is_active,
            created_at=intervention.created_at,
        )

    def get_interventions(
        self,
        participant_id: int,
        id_action_formation: Optional[str] = None
    ) -> List[InterventionResponse]:
        """Get all local interventions for a participant, optionally filtered by ADF."""
        query = self.db.query(Intervention, User).join(
            User, Intervention.user_id == User.id
        ).filter(
            Intervention.participant_id == participant_id
        )

        if id_action_formation:
            query = query.filter(
                Intervention.id_action_formation == id_action_formation
            )

        query = query.order_by(Intervention.created_at.desc())
        results = query.all()

        return [
            InterventionResponse(
                id=intervention.id,
                participant_id=intervention.participant_id,
                participant_course_id=intervention.participant_course_id,
                id_action_formation=intervention.id_action_formation,
                user_id=intervention.user_id,
                user_display_name=user.display_name or user.username,
                intervention_type=intervention.intervention_type,
                details=intervention.details,
                hubspot_note_id=intervention.hubspot_note_id,
                snooze_until=intervention.snooze_until,
                is_active=intervention.is_active,
                created_at=intervention.created_at,
            )
            for intervention, user in results
        ]

    def get_active_snooze(
        self,
        participant_id: int,
        id_action_formation: Optional[str] = None
    ) -> Optional[Intervention]:
        """Check if participant has an active snooze. Returns the snooze record or None."""
        now = datetime.now(timezone.utc)
        query = self.db.query(Intervention).filter(
            and_(
                Intervention.participant_id == participant_id,
                Intervention.intervention_type == 'snooze',
                Intervention.snooze_until > now,
                Intervention.is_active == True
            )
        )
        if id_action_formation:
            query = query.filter(
                Intervention.id_action_formation == id_action_formation
            )
        return query.order_by(Intervention.snooze_until.desc()).first()

    def is_dismissed(
        self,
        participant_id: int,
        id_action_formation: Optional[str] = None
    ) -> bool:
        """Check if participant is dismissed for this ADF."""
        query = self.db.query(Intervention).filter(
            and_(
                Intervention.participant_id == participant_id,
                Intervention.intervention_type == 'dismiss',
                Intervention.is_active == True
            )
        )
        if id_action_formation:
            query = query.filter(
                Intervention.id_action_formation == id_action_formation
            )
        return query.first() is not None

    def get_snoozed_participant_ids(self) -> Set[Tuple[int, str]]:
        """Bulk query: return set of (participant_id, id_action_formation) with active snoozes.
        Used by InactivityService to efficiently filter without N+1 queries."""
        now = datetime.now(timezone.utc)
        results = self.db.query(
            Intervention.participant_id,
            Intervention.id_action_formation
        ).filter(
            and_(
                Intervention.intervention_type == 'snooze',
                Intervention.snooze_until > now,
                Intervention.is_active == True
            )
        ).all()
        return {(r[0], r[1]) for r in results if r[1]}

    def get_snoozed_details_map(self) -> Dict[Tuple[int, str], datetime]:
        """Bulk query: return map of (participant_id, adf_id) -> snooze_until for active snoozes."""
        now = datetime.now(timezone.utc)
        results = self.db.query(
            Intervention.participant_id,
            Intervention.id_action_formation,
            Intervention.snooze_until
        ).filter(
            and_(
                Intervention.intervention_type == 'snooze',
                Intervention.snooze_until > now,
                Intervention.is_active == True
            )
        ).all()
        snooze_map = {}
        for pid, adf, until in results:
            if adf:
                key = (pid, adf)
                # Keep the latest snooze_until if multiple
                if key not in snooze_map or until > snooze_map[key]:
                    snooze_map[key] = until
        return snooze_map

    def get_dismissed_participant_ids(self) -> Set[Tuple[int, str]]:
        """Bulk query: return set of (participant_id, id_action_formation) that are dismissed."""
        results = self.db.query(
            Intervention.participant_id,
            Intervention.id_action_formation
        ).filter(
            and_(
                Intervention.intervention_type == 'dismiss',
                Intervention.is_active == True
            )
        ).all()
        return {(r[0], r[1]) for r in results if r[1]}

    def cancel_intervention(self, intervention_id: int, user_id: int) -> bool:
        """Cancel a snooze or reverse a dismiss.
        For snooze: sets snooze_until to now (expired).
        For dismiss: sets is_active to False."""
        intervention = self.db.query(Intervention).filter(
            Intervention.id == intervention_id
        ).first()

        if not intervention:
            return False

        if intervention.intervention_type == 'snooze':
            intervention.snooze_until = datetime.now(timezone.utc)
            intervention.is_active = False
        elif intervention.intervention_type == 'dismiss':
            intervention.is_active = False
        else:
            return False

        self.db.commit()
        logger.info(
            f"Intervention {intervention_id} ({intervention.intervention_type}) "
            f"cancelled by user {user_id}"
        )
        return True
