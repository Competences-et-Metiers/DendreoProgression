"""
Inactivity Tracking Service

Assesses participant inactivity based on learning progression changes over time,
not login/connection events. Classifies participants as active, inactive, or
never_started based on the inactivity threshold.
"""

from sqlalchemy.orm import Session
from sqlalchemy import func as sa_func
from datetime import datetime, timezone
from typing import List, Dict, Optional, Tuple
from app.models.models import Participant, ParticipantCourse, Course, Module, Creneau, CreneauParticipant, ModuleCategory, Intervention, ParticipantHubspotData
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
        exclude_recent_enrollments_days: int = 0
    ):
        self.db = db
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
        active / inactive / never_started.
        """
        now = datetime.now(timezone.utc)

        # Build category lookup map: {id_categorie_module: {name, color}}
        category_map = {}
        for cat in self.db.query(ModuleCategory).all():
            category_map[cat.id_categorie_module] = {
                'name': cat.intitule,
                'color': cat.color
            }

        # Pre-build set of (participant_id, adf_id) with liveroom attendance
        # so we include participants who only have liveroom activity (no LMS access)
        liveroom_pairs = set()
        liveroom_results = (
            self.db.query(CreneauParticipant.participant_id, Creneau.id_action_formation)
            .join(Creneau, CreneauParticipant.creneau_id == Creneau.id)
            .filter(CreneauParticipant.presence == "1")
            .distinct()
            .all()
        )
        for pid, adf in liveroom_results:
            liveroom_pairs.add((pid, adf))

        # Pre-build liveroom duration maps for time tracking
        # Map: (adf_id, id_lam) -> total scheduled duration (seconds) from creneaux
        liveroom_total_per_lam: Dict[tuple, int] = {}
        for adf, lam, dur in self.db.query(
            Creneau.id_action_formation, Creneau.id_lam, Creneau.duration
        ).all():
            key = (adf, lam)
            liveroom_total_per_lam[key] = liveroom_total_per_lam.get(key, 0) + (dur or 0)

        # Map: (participant_id, adf_id) -> time spent (seconds) from attended creneaux
        liveroom_time_spent_map: Dict[tuple, int] = {}
        attended_rows = (
            self.db.query(CreneauParticipant.participant_id, Creneau.id_action_formation, Creneau.duration)
            .join(Creneau, CreneauParticipant.creneau_id == Creneau.id)
            .filter(CreneauParticipant.presence == "1")
            .all()
        )
        for pid, adf, duration in attended_rows:
            key = (pid, adf)
            liveroom_time_spent_map[key] = liveroom_time_spent_map.get(key, 0) + (duration or 0)

        # Map: id_lam -> mode_organisation (used to attribute planned hours correctly)
        module_modes: Dict[str, str] = {}
        for lam, mode in self.db.query(Module.id_lam, Module.mode_organisation).distinct().all():
            if lam:
                module_modes[lam] = mode or 'elearning_async'

        # Pre-build upcoming sessions map: (participant_id, adf_id) -> (count, earliest_date)
        upcoming_sessions_map: Dict[Tuple[int, str], Tuple[int, datetime]] = {}
        upcoming_rows = (
            self.db.query(
                CreneauParticipant.participant_id,
                Creneau.id_action_formation,
                sa_func.count(Creneau.id).label('cnt'),
                sa_func.min(Creneau.date_debut).label('next_date')
            )
            .join(Creneau, CreneauParticipant.creneau_id == Creneau.id)
            .filter(Creneau.date_debut > now)
            .group_by(CreneauParticipant.participant_id, Creneau.id_action_formation)
            .all()
        )
        for pid, adf, cnt, next_date in upcoming_rows:
            upcoming_sessions_map[(pid, adf)] = (cnt, next_date)

        # Pre-build last-attended-liveroom map: (participant_id, adf_id) -> latest past date_fin.
        # Replaces one query per (participant, ADF) inside the main loop.
        last_liveroom_map: Dict[Tuple[int, str], datetime] = {}
        last_liveroom_rows = (
            self.db.query(
                CreneauParticipant.participant_id,
                Creneau.id_action_formation,
                sa_func.max(Creneau.date_fin).label('last_fin')
            )
            .join(Creneau, CreneauParticipant.creneau_id == Creneau.id)
            .filter(
                CreneauParticipant.presence == "1",
                Creneau.date_fin <= now
            )
            .group_by(CreneauParticipant.participant_id, Creneau.id_action_formation)
            .all()
        )
        for pid, adf, last_fin in last_liveroom_rows:
            last_liveroom_map[(pid, adf)] = last_fin

        # Pre-build ADF -> LAM ids map (single query, was one query per ADF in the loop).
        # No status filter here, matching the original per-ADF lookup.
        adf_lams_map: Dict[str, List[str]] = {}
        for adf, lam in self.db.query(
            Course.id_action_formation, Course.id_lam
        ).distinct().all():
            if lam:
                adf_lams_map.setdefault(adf, []).append(lam)

        # Pre-build module aggregates: (participant_id, id_lam) -> (count, progression_sum, time_sum).
        # Replaces the per-participant Module query; summing across an ADF's LAMs in
        # Python reproduces the previous avg-progression and total-time figures exactly.
        module_agg: Dict[Tuple[int, str], Tuple[int, float, int]] = {}
        module_rows = self.db.query(
            Module.participant_id,
            Module.id_lam,
            sa_func.count(Module.id).label('cnt'),
            sa_func.sum(Module.lms_progression).label('prog_sum'),
            sa_func.sum(Module.lms_time_spent).label('time_sum'),
        ).group_by(Module.participant_id, Module.id_lam).all()
        for pid, lam, cnt, prog_sum, time_sum in module_rows:
            module_agg[(pid, lam)] = (int(cnt or 0), float(prog_sum or 0.0), int(time_sum or 0))

        query = (
            self.db.query(ParticipantCourse, Participant, Course)
            .join(Participant, ParticipantCourse.participant_id == Participant.id)
            .join(Course, ParticipantCourse.course_id == Course.id)
            .filter(Course.status.in_(['5', '6', '7']))
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
            'inactive': 0,
            'never_started': 0,
            'newly_enrolled_excluded': 0
        }

        # Pre-build snooze and dismiss sets from InterventionService
        from app.services.intervention_service import InterventionService
        intervention_svc = InterventionService(self.db)
        snoozed_set = intervention_svc.get_snoozed_participant_ids()
        snoozed_details = intervention_svc.get_snoozed_details_map()
        dismissed_set = intervention_svc.get_dismissed_participant_ids()

        # Pre-build latest note dates map: (participant_id, adf_id) -> datetime
        latest_notes_map: Dict[Tuple[int, Optional[str]], datetime] = {}
        note_rows = (
            self.db.query(
                Intervention.participant_id,
                Intervention.id_action_formation,
                sa_func.max(Intervention.created_at).label('latest_note')
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

        # Pre-build EDOF session dates map: (participant_id, adf_id) -> (debut, fin)
        edof_map: Dict[Tuple[int, str], Tuple[Optional[str], Optional[str]]] = {}
        edof_rows = (
            self.db.query(
                ParticipantHubspotData.participant_id,
                ParticipantHubspotData.id_action_formation,
                ParticipantHubspotData.edof_date_debut,
                ParticipantHubspotData.edof_date_fin,
            )
            .filter(
                (ParticipantHubspotData.edof_date_debut.isnot(None))
                | (ParticipantHubspotData.edof_date_fin.isnot(None))
            )
            .all()
        )
        for pid, adf, deb, fin in edof_rows:
            if adf:
                edof_map[(pid, adf)] = (deb, fin)

        all_details: List[InactiveParticipantDetail] = []
        by_course_map: Dict[str, List[InactiveParticipantDetail]] = {}

        for (participant_id, adf_id), group_data in adf_groups.items():
            participant = group_data['participant']
            enrollments = group_data['enrollments']

            # E-learning last activity
            elearning_last_activities = [e['participant_course'].last_activity for e in enrollments
                             if e['participant_course'].last_activity]
            last_elearning = max(elearning_last_activities) if elearning_last_activities else None

            has_liveroom = (participant_id, adf_id) in liveroom_pairs

            # Liveroom last attended (only sessions where participant was present)
            last_liveroom = last_liveroom_map.get((participant_id, adf_id)) if has_liveroom else None

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

            # Get earliest enrollment date (prefer date_add from Dendreo, fallback to created_at)
            enrollment_dates = []
            for e in enrollments:
                pc = e['participant_course']
                date = pc.date_add if pc.date_add else pc.created_at
                if date:
                    enrollment_dates.append(date)
            enrollment_date = min(enrollment_dates) if enrollment_dates else None

            # course.planned_duration_hours holds the full module duration in Dendreo
            # (covers liveroom for elearning_sync, e-learning + liveroom for mixte, etc.).
            module_planned_hours = sum(e['course'].planned_duration_hours or 0.0 for e in enrollments)

            # Attribute planned hours by mode: elearning_sync is fully liveroom,
            # mixte uses scheduled creneau time, elearning_async is fully e-learning.
            lr_planned_hours = 0.0
            for e in enrollments:
                course = e['course']
                hours = course.planned_duration_hours or 0.0
                mode = module_modes.get(course.id_lam, 'elearning_async')
                if mode == 'elearning_sync':
                    lr_planned_hours += hours
                elif mode == 'mixte':
                    scheduled = liveroom_total_per_lam.get((course.id_action_formation, course.id_lam), 0) / 3600.0
                    lr_planned_hours += min(scheduled, hours)

            # Liveroom time spent (sum of attended creneau durations across the ADF)
            lr_spent_seconds = liveroom_time_spent_map.get((participant_id, adf_id), 0)
            lr_spent_hours = lr_spent_seconds / 3600.0

            total_duration = module_planned_hours

            # Aggregate module data across all LAMs of this ADF (same as course detail page),
            # using the pre-built maps instead of per-participant queries.
            lam_ids = adf_lams_map.get(adf_id, [])
            module_count = 0
            progression_sum = 0.0
            elearning_time_spent_seconds = 0
            for lam_id in lam_ids:
                agg = module_agg.get((participant.id, lam_id))
                if agg:
                    module_count += agg[0]
                    progression_sum += agg[1]
                    elearning_time_spent_seconds += agg[2]

            total_time_spent_hours = (elearning_time_spent_seconds / 3600.0) + lr_spent_hours

            # Compute progression from all module data (same as course detail page)
            avg_progression = (progression_sum / module_count) if module_count else 0.0

            # Skip fully completed participants
            if avg_progression >= 100.0:
                continue

            if min_progression is not None and avg_progression < min_progression:
                continue
            if max_progression is not None and avg_progression > max_progression:
                continue

            days_since_activity = (now - last_activity).days if last_activity else 0
            days_since_enrollment = (now - enrollment_date).days if enrollment_date else 0

            # Exclude recently enrolled participants
            if days_since_enrollment < self.exclude_recent_threshold:
                stats['newly_enrolled_excluded'] += 1
                continue

            # Classify: never_started if no activity at all, otherwise use thresholds
            if not last_activity:
                inactivity_status = 'never_started'
                inactivity_reason = 'Never started'
            else:
                inactivity_status, inactivity_reason = self._classify(days_since_activity)

            stats[inactivity_status] += 1

            formateurs = enrollments[0]['course'].formateurs if enrollments[0]['course'].formateurs else None

            # Upcoming sessions
            upcoming_info = upcoming_sessions_map.get((participant_id, adf_id))
            upcoming_count = upcoming_info[0] if upcoming_info else 0
            next_session = upcoming_info[1] if upcoming_info else None

            # Look up category from first course in the group
            cat_id = enrollments[0]['course'].categorie_module_id
            cat_info = category_map.get(cat_id, {}) if cat_id else {}

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
                liveroom_planned_duration_hours=lr_planned_hours,
                liveroom_time_spent_hours=lr_spent_hours,
                current_progression=avg_progression,
                last_activity=last_activity,
                last_activity_source=last_activity_source,
                days_inactive=days_since_activity,
                enrollment_date=enrollment_date,
                days_since_enrollment=days_since_enrollment,
                next_session_date=next_session,
                upcoming_sessions_count=upcoming_count,
                inactivity_status=inactivity_status,
                inactivity_reason=inactivity_reason,
                formateurs=formateurs,
                category_name=cat_info.get('name'),
                category_color=cat_info.get('color'),
                has_active_snooze=(participant_id, adf_id) in snoozed_set,
                snooze_until=snoozed_details.get((participant_id, adf_id)),
                is_dismissed=(participant_id, adf_id) in dismissed_set,
                latest_note_date=latest_notes_map.get((participant_id, adf_id)),
                edof_date_debut=edof_map.get((participant_id, adf_id), (None, None))[0],
                edof_date_fin=edof_map.get((participant_id, adf_id), (None, None))[1],
                edof_sessions=participant.edof_sessions or [],
            )

            all_details.append(detail)

            if group_by_course:
                if adf_id not in by_course_map:
                    by_course_map[adf_id] = []
                by_course_map[adf_id].append(detail)

        total_participants = stats['active'] + stats['inactive'] + stats['never_started']

        summary_kwargs = dict(
            total_participants_checked=stats['total_checked'],
            total_participants=total_participants,
            active_count=stats['active'],
            inactive_count=stats['inactive'],
            never_started_count=stats['never_started'],
            newly_enrolled_excluded=stats['newly_enrolled_excluded'],
            inactivity_threshold_days=self.inactivity_threshold,
            exclude_recent_enrollments_days=self.exclude_recent_threshold
        )

        if group_by_course:
            grouped = self._build_adf_groups(by_course_map)
            return InactivitySummary(by_course=grouped, participants=None, **summary_kwargs)
        else:
            all_details.sort(key=lambda x: x.days_inactive, reverse=True)
            return InactivitySummary(by_course=None, participants=all_details, **summary_kwargs)

    def _classify(self, days_since_activity: int) -> tuple[str, str]:
        """Classify into active / inactive based on days since last activity."""
        if days_since_activity < self.inactivity_threshold:
            return ('active', 'Recent activity detected')

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
            inactive = sum(1 for p in participants if p.inactivity_status == 'inactive')
            never_started = sum(1 for p in participants if p.inactivity_status == 'never_started')

            participants.sort(key=lambda x: x.days_inactive, reverse=True)

            grouped.append(InactiveParticipantsByCourse(
                course_id=first.course_id or 0,
                course_title=first.course_title,
                id_action_formation=adf_id,
                category_name=first.category_name,
                category_color=first.category_color,
                total_participants=len(participants),
                active_count=active,
                inactive_count=inactive,
                never_started_count=never_started,
                participants=participants
            ))

        grouped.sort(key=lambda x: x.inactive_count, reverse=True)
        return grouped
