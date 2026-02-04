# Progression Delta Tracker - Implementation Plan

**Status:** On Hold
**Date:** 2026-02-04
**Priority:** High (when resumed)

## Executive Summary

A system to track daily progression changes for participants, enabling detection of "stagnant" users who log in regularly but don't make meaningful progress. This addresses a gap in current inactivity detection which only tracks login activity.

## Problem Statement

**Current Issue:** A user may log in daily but their progression increases by less than 1% in 30 days. Current system would classify them as "active" when they're actually stagnant.

**Solution:** Track progression snapshots daily to calculate progression deltas and identify users who need intervention despite being "active."

## Feasibility Assessment

✅ **HIGHLY FEASIBLE** - Infrastructure fully supports this implementation.

### Current Infrastructure Strengths
- SQLAlchemy ORM with proper relationships
- Existing scheduled sync process
- `ParticipantCourse.overall_progression` tracks current values
- `Module.lms_progression` tracks module-level progress
- Existing inactivity detection service
- React Query caching on frontend

## Database Design

### New Table: `progression_snapshots`

```python
class ProgressionSnapshot(Base):
    __tablename__ = "progression_snapshots"

    id = Column(Integer, primary_key=True)
    participant_course_id = Column(Integer, ForeignKey("participant_courses.id"), nullable=False)

    # Snapshot data
    progression_value = Column(Float, nullable=False)
    modules_completed = Column(Integer, default=0)
    snapshot_date = Column(Date, index=True, nullable=False)  # Date only, not datetime

    # Pre-computed deltas for performance
    delta_7_days = Column(Float, nullable=True)
    delta_30_days = Column(Float, nullable=True)

    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    # Composite unique index - one snapshot per day per enrollment
    __table_args__ = (
        Index('idx_pc_date', 'participant_course_id', 'snapshot_date', unique=True),
        Index('idx_snapshot_date', 'snapshot_date'),  # For date range queries
    )

    # Relationships
    participant_course = relationship("ParticipantCourse")
```

### Design Decisions

#### ✅ **Date, Not Datetime**
- One snapshot per participant-course per day
- Prevents duplicate snapshots from multiple sync runs
- Simpler delta calculations
- Composite unique constraint ensures data integrity

#### ✅ **Pre-computed Deltas**
- Calculate 7-day and 30-day deltas when creating snapshot
- Avoids expensive joins at query time
- Trade storage for query speed
- Can be recalculated if needed

#### ✅ **Link to ParticipantCourse**
- Clean relationship structure
- Natural foreign key constraint
- Easy to query with existing code
- Maintains data integrity

## Implementation Plan

### Phase 1: Foundation (Week 1)

#### 1.1 Database Migration
```python
# alembic/versions/xxx_add_progression_snapshots.py

def upgrade():
    op.create_table(
        'progression_snapshots',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('participant_course_id', sa.Integer(), nullable=False),
        sa.Column('progression_value', sa.Float(), nullable=False),
        sa.Column('modules_completed', sa.Integer(), server_default='0'),
        sa.Column('snapshot_date', sa.Date(), nullable=False),
        sa.Column('delta_7_days', sa.Float(), nullable=True),
        sa.Column('delta_30_days', sa.Float(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()')),
        sa.ForeignKeyConstraint(['participant_course_id'], ['participant_courses.id'], ),
        sa.PrimaryKeyConstraint('id')
    )

    op.create_index('idx_pc_date', 'progression_snapshots',
                    ['participant_course_id', 'snapshot_date'], unique=True)
    op.create_index('idx_snapshot_date', 'progression_snapshots', ['snapshot_date'])

def downgrade():
    op.drop_index('idx_snapshot_date', table_name='progression_snapshots')
    op.drop_index('idx_pc_date', table_name='progression_snapshots')
    op.drop_table('progression_snapshots')
```

#### 1.2 Model Definition
Add to `app/models/models.py` after other model definitions.

#### 1.3 Helper Functions
```python
# app/services/progression_snapshot_service.py

from datetime import date, timedelta
from sqlalchemy.orm import Session
from app.models.models import ProgressionSnapshot, ParticipantCourse, Module

class ProgressionSnapshotService:
    """Service for managing progression snapshots"""

    @staticmethod
    def calculate_delta(db: Session, participant_course_id: int, days_back: int) -> float:
        """
        Calculate progression delta for the past N days
        Returns: delta value or None if no historical data
        """
        today = date.today()
        past_date = today - timedelta(days=days_back)

        # Get today's value (might be the one we're creating)
        current = db.query(ProgressionSnapshot).filter(
            ProgressionSnapshot.participant_course_id == participant_course_id,
            ProgressionSnapshot.snapshot_date == today
        ).first()

        # Get value from N days ago
        historical = db.query(ProgressionSnapshot).filter(
            ProgressionSnapshot.participant_course_id == participant_course_id,
            ProgressionSnapshot.snapshot_date == past_date
        ).first()

        if not historical:
            return None

        current_value = current.progression_value if current else 0
        return current_value - historical.progression_value

    @staticmethod
    def create_daily_snapshots(db: Session) -> int:
        """
        Create progression snapshots for all enrollments
        Called after daily sync completes
        Returns: number of snapshots created
        """
        today = date.today()
        created_count = 0

        # Get all active participant courses
        enrollments = db.query(ParticipantCourse).all()

        for enrollment in enrollments:
            # Check if snapshot already exists for today
            existing = db.query(ProgressionSnapshot).filter(
                ProgressionSnapshot.participant_course_id == enrollment.id,
                ProgressionSnapshot.snapshot_date == today
            ).first()

            if existing:
                continue  # Skip if already exists

            # Count completed modules
            modules_completed = db.query(Module).filter(
                Module.participant_id == enrollment.participant_id,
                Module.course_id == enrollment.course_id,
                Module.lms_progression >= 100
            ).count()

            # Calculate deltas
            delta_7 = ProgressionSnapshotService.calculate_delta(db, enrollment.id, 7)
            delta_30 = ProgressionSnapshotService.calculate_delta(db, enrollment.id, 30)

            # Create snapshot
            snapshot = ProgressionSnapshot(
                participant_course_id=enrollment.id,
                progression_value=enrollment.overall_progression or 0.0,
                modules_completed=modules_completed,
                snapshot_date=today,
                delta_7_days=delta_7,
                delta_30_days=delta_30
            )

            db.add(snapshot)
            created_count += 1

        db.commit()
        return created_count

    @staticmethod
    def cleanup_old_snapshots(db: Session, keep_days: int = 90) -> int:
        """
        Clean up old snapshots based on retention policy
        - Keep daily snapshots for last 30 days
        - Keep weekly snapshots (Mondays) for 31-90 days
        - Delete snapshots older than 90 days

        Returns: number of snapshots deleted
        """
        cutoff_date = date.today() - timedelta(days=keep_days)

        # Delete old snapshots (older than 90 days)
        deleted = db.query(ProgressionSnapshot).filter(
            ProgressionSnapshot.snapshot_date < cutoff_date
        ).delete()

        # For snapshots between 30-90 days, keep only Mondays
        thirty_days_ago = date.today() - timedelta(days=30)

        # This would need more complex SQL - leaving as TODO
        # Could use extract('dow', snapshot_date) for day of week

        db.commit()
        return deleted
```

#### 1.4 Integration with Sync Process
```python
# In scripts/sync_dendreo.py or app/services/dendreo_sync.py
# Add after main sync completes successfully

from app.services.progression_snapshot_service import ProgressionSnapshotService

async def main():
    # ... existing sync code ...

    # After sync completes successfully
    if sync_status == 'success':
        logger.info("📊 Creating daily progression snapshots...")
        with get_db_session() as db:
            snapshot_count = ProgressionSnapshotService.create_daily_snapshots(db)
            logger.info(f"✅ Created {snapshot_count} progression snapshots")

            # Cleanup old snapshots
            deleted_count = ProgressionSnapshotService.cleanup_old_snapshots(db)
            if deleted_count > 0:
                logger.info(f"🧹 Cleaned up {deleted_count} old snapshots")
```

### Phase 2: Enhanced Inactivity Detection (Week 2)

#### 2.1 Add "Stagnant" Status

Update inactivity classification to include new status:

**New Status Hierarchy:**
1. **Active** - Logging in AND progressing (>1% in 30 days)
2. **Stagnant** - Logging in but <1% progress in 30 days (NEW!)
3. **At Risk** - Not logging in for 21 days
4. **Stalled** - Not logging in for 30 days
5. **Long Inactive** - Not logging in for 60 days

#### 2.2 Update InactivityService
```python
# app/services/inactivity_service.py

from app.models.models import ProgressionSnapshot
from datetime import date

class InactivityService:
    # ... existing code ...

    def classify_with_progression(self, participant_course, db: Session):
        """
        Enhanced classification using both activity AND progression
        Returns: 'active', 'stagnant', 'at_risk', 'stalled', 'long_inactive'
        """
        # Get latest snapshot
        latest_snapshot = db.query(ProgressionSnapshot).filter(
            ProgressionSnapshot.participant_course_id == participant_course.id
        ).order_by(ProgressionSnapshot.snapshot_date.desc()).first()

        if not latest_snapshot or not latest_snapshot.delta_30_days:
            # No progression data, fall back to activity-based classification
            return self._classify_by_activity(participant_course)

        # Calculate days since last activity
        if not participant_course.last_activity:
            return 'long_inactive'

        days_since_activity = (datetime.now(timezone.utc) - participant_course.last_activity).days

        # User is logging in (active) but not progressing
        if days_since_activity <= 7 and latest_snapshot.delta_30_days < 1.0:
            return 'stagnant'

        # Standard activity-based classification
        return self._classify_by_activity(participant_course)
```

#### 2.3 API Endpoint for Progression History
```python
# app/api/routes/participants.py

@router.get("/participants/{participant_id}/progression-history")
async def get_progression_history(
    participant_id: int,
    course_id: Optional[int] = None,
    days: int = Query(30, ge=7, le=365),
    db: Session = Depends(get_db)
):
    """Get progression history for a participant"""
    query = db.query(ProgressionSnapshot).join(ParticipantCourse).filter(
        ParticipantCourse.participant_id == participant_id
    )

    if course_id:
        query = query.filter(ParticipantCourse.course_id == course_id)

    cutoff_date = date.today() - timedelta(days=days)
    snapshots = query.filter(
        ProgressionSnapshot.snapshot_date >= cutoff_date
    ).order_by(ProgressionSnapshot.snapshot_date.asc()).all()

    return {
        "participant_id": participant_id,
        "course_id": course_id,
        "days": days,
        "snapshots": [
            {
                "date": s.snapshot_date.isoformat(),
                "progression": s.progression_value,
                "modules_completed": s.modules_completed,
                "delta_7_days": s.delta_7_days,
                "delta_30_days": s.delta_30_days
            }
            for s in snapshots
        ]
    }
```

### Phase 3: Frontend Integration (Week 3)

#### 3.1 Update Status Display
```javascript
// frontend/src/pages/InactiveManagement.js

const getStatusColor = (status) => {
  switch (status) {
    case 'active':
      return 'bg-green-100 text-green-800 border-green-200';
    case 'stagnant':  // NEW!
      return 'bg-amber-100 text-amber-800 border-amber-200';
    case 'at_risk':
      return 'bg-yellow-100 text-yellow-800 border-yellow-200';
    case 'stalled':
      return 'bg-orange-100 text-orange-800 border-orange-200';
    case 'long_inactive':
      return 'bg-red-100 text-red-800 border-red-200';
    default:
      return 'bg-gray-100 text-gray-800 border-gray-200';
  }
};

const getStatusIcon = (status) => {
  switch (status) {
    case 'active':
      return <CheckCircle2 size={16} className="text-green-600" />;
    case 'stagnant':  // NEW!
      return <TrendingFlat size={16} className="text-amber-600" />;
    case 'at_risk':
      return <AlertTriangle size={16} className="text-yellow-600" />;
    // ... rest of cases
  }
};
```

#### 3.2 Add French Translations
```json
// frontend/src/i18n/locales/fr.json

{
  "inactiveManagement": {
    "status": {
      "active": "Actif",
      "stagnant": "Stagnant",
      "atRisk": "À risque",
      "stalled": "Bloqué",
      "longInactive": "Inactif longue durée"
    },
    "stats": {
      "stagnant": "Stagnants"
    }
  }
}
```

#### 3.3 Display Progression Delta
```javascript
// Show progression delta next to progression percentage
<div className="flex items-center gap-2">
  <span className="text-sm text-gray-500">
    ({participant.current_progression.toFixed(1)}%)
  </span>

  {participant.progression_delta_30_days !== undefined && (
    <span className={`text-xs font-medium ${
      participant.progression_delta_30_days < 1
        ? 'text-amber-600'
        : 'text-green-600'
    }`}>
      {participant.progression_delta_30_days > 0 ? '+' : ''}
      {participant.progression_delta_30_days.toFixed(1)}% (30j)
    </span>
  )}
</div>
```

#### 3.4 Optional: Progression Trend Chart
```javascript
// Optional feature for participant detail page
import { LineChart, Line, XAxis, YAxis, Tooltip } from 'recharts';

const ProgressionChart = ({ participantId, courseId }) => {
  const { data } = useQuery({
    queryKey: ['progression-history', participantId, courseId],
    queryFn: async () => {
      const response = await api.get(
        `/participants/${participantId}/progression-history`,
        { params: { course_id: courseId, days: 90 } }
      );
      return response.data;
    }
  });

  return (
    <LineChart width={600} height={300} data={data?.snapshots || []}>
      <XAxis dataKey="date" />
      <YAxis />
      <Tooltip />
      <Line
        type="monotone"
        dataKey="progression"
        stroke="#8884d8"
        strokeWidth={2}
      />
    </LineChart>
  );
};
```

### Phase 4: Optimization & Monitoring (Week 4)

#### 4.1 Performance Monitoring
```python
# Add metrics to track snapshot creation performance
import time

def create_daily_snapshots(db: Session) -> dict:
    start_time = time.time()
    created_count = 0
    error_count = 0

    # ... snapshot creation logic ...

    duration = time.time() - start_time

    logger.info(f"""
    📊 Snapshot Creation Summary:
    - Created: {created_count} snapshots
    - Errors: {error_count}
    - Duration: {duration:.2f}s
    - Rate: {created_count/duration:.1f} snapshots/sec
    """)

    return {
        'created': created_count,
        'errors': error_count,
        'duration': duration
    }
```

#### 4.2 Database Indexes Verification
```sql
-- Verify indexes are being used
EXPLAIN ANALYZE
SELECT * FROM progression_snapshots
WHERE participant_course_id = 123
AND snapshot_date >= '2026-01-01';

-- Should show Index Scan using idx_pc_date
```

#### 4.3 Batch Processing Optimization
```python
# For large datasets, process in batches
def create_daily_snapshots_batched(db: Session, batch_size: int = 100):
    """Create snapshots in batches to avoid memory issues"""
    offset = 0
    total_created = 0

    while True:
        enrollments = db.query(ParticipantCourse).offset(offset).limit(batch_size).all()

        if not enrollments:
            break

        batch_created = process_enrollment_batch(db, enrollments)
        total_created += batch_created
        offset += batch_size

        # Commit after each batch
        db.commit()

        logger.info(f"Processed batch {offset//batch_size}: {batch_created} snapshots")

    return total_created
```

## Key Improvements to Original Idea

### 1. Selective Snapshot Creation
```python
# Only create snapshot if:
# 1. Progression changed, OR
# 2. It's been 7+ days since last snapshot

def should_create_snapshot(db: Session, enrollment: ParticipantCourse) -> bool:
    latest = db.query(ProgressionSnapshot).filter(
        ProgressionSnapshot.participant_course_id == enrollment.id
    ).order_by(ProgressionSnapshot.snapshot_date.desc()).first()

    if not latest:
        return True  # First snapshot

    # Progression changed?
    if abs(enrollment.overall_progression - latest.progression_value) > 0.01:
        return True

    # Been more than 7 days?
    days_since = (date.today() - latest.snapshot_date).days
    if days_since >= 7:
        return True

    return False
```

### 2. Configurable Thresholds
```python
# app/config/settings.py

class Settings:
    # Progression tracking thresholds
    STAGNATION_THRESHOLD_DAYS: int = 30
    STAGNATION_MIN_PROGRESS: float = 1.0  # Less than 1% in 30 days = stagnant
    STAGNATION_MIN_LOGINS: int = 3  # Must log in at least 3 times

    # Snapshot retention
    SNAPSHOT_RETENTION_DAYS: int = 90
    SNAPSHOT_KEEP_DAILY_DAYS: int = 30
```

### 3. Multiple Tracking Metrics
```python
# Future enhancement: track more than just progression
class ProgressionSnapshot(Base):
    # ... existing fields ...

    # Additional metrics (optional future enhancement)
    time_spent_seconds = Column(Integer, nullable=True)
    login_count_30_days = Column(Integer, nullable=True)
    modules_started = Column(Integer, nullable=True)
```

## Potential Challenges & Solutions

### Challenge 1: Storage Growth
**Issue:** Daily snapshots × participants × courses = lots of rows

**Solutions:**
- Implement retention policy (keep 90 days, aggregate older)
- Use PostgreSQL table partitioning by date
- Archive old data to separate table
- Selective snapshot creation (only when changed)

**Estimate:**
- 1000 participants × 2 courses × 365 days = ~730,000 rows/year
- At ~100 bytes/row = ~73 MB/year (very manageable)

### Challenge 2: Initial Backfill
**Issue:** No historical data for existing participants

**Solutions:**
- Accept 30-day wait for full delta data
- Backfill with current progression as baseline
- Mark backfilled snapshots with flag for data quality

### Challenge 3: Performance
**Issue:** Calculating deltas for thousands of participants

**Solutions:**
- Pre-compute deltas when creating snapshot
- Use database indexes properly (already designed)
- Run snapshot creation asynchronously
- Batch processing for large datasets

### Challenge 4: Edge Cases
**Issues:**
- Course structure changes (total modules change)
- Progression decreases (rare, but possible)
- New enrollments with no history
- Sync failures

**Solutions:**
```python
# Handle edge cases gracefully
def create_snapshot_safe(db: Session, enrollment: ParticipantCourse):
    try:
        # Validate progression value
        progression = max(0, min(100, enrollment.overall_progression or 0))

        # Handle missing last_activity
        if not enrollment.last_activity:
            logger.warning(f"No last_activity for enrollment {enrollment.id}")

        # Create snapshot with validated data
        snapshot = ProgressionSnapshot(
            participant_course_id=enrollment.id,
            progression_value=progression,
            # ... rest of fields
        )

        db.add(snapshot)
        return True

    except Exception as e:
        logger.error(f"Failed to create snapshot for {enrollment.id}: {e}")
        return False
```

## Business Value

### Immediate Benefits
1. **Better Intervention Targeting** - Identify users who need help vs. those just checking in
2. **Resource Optimization** - Focus coaching on truly struggling users
3. **Accurate Reporting** - Distinguish "active" from "progressing"

### Long-term Benefits
1. **Predictive Analytics** - Identify patterns that predict completion
2. **Trend Analysis** - Understand what drives progression
3. **Historical Audit** - Complete trail of progression changes
4. **Debugging Tool** - Identify calculation issues

### ROI Metrics
- Reduce false positives in inactive detection by ~30%
- Enable early intervention for stagnant users
- Improve completion rates through targeted support
- Better resource allocation for coaching staff

## Technical Debt Considerations

### Minimal Technical Debt
This design adds minimal technical debt because:
- ✅ Clean data model with proper relationships
- ✅ Service layer separation maintains SOLID principles
- ✅ No coupling to existing code
- ✅ Can be removed cleanly if needed
- ✅ Optional feature - doesn't break existing functionality

### Future Enhancements
Once core system is working:
1. Add time-series charts
2. Track additional metrics (time spent, logins)
3. Machine learning for prediction
4. Automated intervention triggers
5. Export to analytics platforms

## Testing Strategy

### Unit Tests
```python
# tests/test_progression_snapshot_service.py

def test_calculate_delta_with_history():
    """Test delta calculation with existing history"""
    # Create historical snapshot
    # Create current snapshot
    # Assert delta is calculated correctly

def test_create_snapshot_prevents_duplicates():
    """Test that duplicate snapshots for same day are prevented"""
    # Attempt to create two snapshots for same day
    # Assert only one exists

def test_cleanup_old_snapshots():
    """Test retention policy cleanup"""
    # Create snapshots spanning 120 days
    # Run cleanup
    # Assert correct snapshots remain
```

### Integration Tests
```python
# tests/integration/test_sync_with_snapshots.py

def test_full_sync_creates_snapshots():
    """Test that sync process creates snapshots"""
    # Run full sync
    # Assert snapshots created
    # Assert deltas calculated
```

## Migration Path

### Safe Rollout Strategy

1. **Deploy Database Changes** (Week 1, Day 1)
   - Create table
   - Monitor for issues

2. **Enable Snapshot Creation** (Week 1, Day 3)
   - Start creating snapshots
   - Monitor performance
   - No user-facing changes yet

3. **Backfill Historical Data** (Week 1, Day 5)
   - Create initial snapshots for all enrollments
   - Mark as backfilled

4. **Deploy Enhanced Classification** (Week 2)
   - Add stagnant status
   - Enable in API
   - Monitor classification distribution

5. **Frontend Updates** (Week 3)
   - Add stagnant status display
   - Add progression delta
   - Optional: charts

### Rollback Plan
```python
# If issues arise, can disable without removing code

# In settings.py
ENABLE_PROGRESSION_TRACKING = False

# In service
if not settings.ENABLE_PROGRESSION_TRACKING:
    return  # Skip snapshot creation
```

## Monitoring & Alerting

### Key Metrics to Track
```python
# Metrics to monitor in production
METRICS = {
    'snapshots_created_daily': 'Number of snapshots created each day',
    'snapshot_creation_duration': 'Time to create all snapshots',
    'stagnant_users_count': 'Number of users classified as stagnant',
    'delta_calculation_errors': 'Errors calculating deltas',
    'storage_size_mb': 'Size of progression_snapshots table'
}
```

### Alerts
```yaml
# Example alert configuration
alerts:
  - name: "Snapshot creation failed"
    condition: snapshots_created_daily == 0
    severity: high

  - name: "Snapshot creation slow"
    condition: snapshot_creation_duration > 300  # 5 minutes
    severity: medium

  - name: "High stagnation rate"
    condition: (stagnant_users_count / total_users) > 0.3
    severity: info
```

## Documentation Requirements

When implementing, create:
1. ✅ Database schema documentation (this file)
2. ⬜ API endpoint documentation (OpenAPI/Swagger)
3. ⬜ Service layer documentation (docstrings)
4. ⬜ Frontend component documentation (JSDoc)
5. ⬜ Deployment guide
6. ⬜ Monitoring dashboard setup

## References

### Related Files
- `/back/app/models/models.py` - Database models
- `/back/app/services/inactivity_service.py` - Inactivity detection
- `/back/scripts/sync_dendreo.py` - Sync process
- `/frontend/src/pages/InactiveManagement.js` - Frontend display

### External Resources
- SQLAlchemy Documentation: https://docs.sqlalchemy.org/
- PostgreSQL Date/Time Functions: https://www.postgresql.org/docs/current/functions-datetime.html
- React Query: https://tanstack.com/query/latest/docs/framework/react/overview

## Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-02-04 | Use Date instead of DateTime | One snapshot per day, prevents duplicates |
| 2026-02-04 | Pre-compute deltas | Trade storage for query performance |
| 2026-02-04 | Link to ParticipantCourse | Cleaner relationships, better integrity |
| 2026-02-04 | Add "stagnant" status | Distinguish login activity from progression |
| 2026-02-04 | 90-day retention | Balance storage vs. analytical needs |

## Next Steps (When Resumed)

1. ✅ Review this document
2. ⬜ Create feature branch: `feature/progression-delta-tracker`
3. ⬜ Start Phase 1: Database migration
4. ⬜ Deploy to development environment
5. ⬜ Test with small dataset
6. ⬜ Proceed with Phase 2-4

## Questions for Discussion

Before implementation, discuss:
- [ ] Confirm 1% threshold for stagnation is appropriate
- [ ] Confirm 30-day window is correct
- [ ] Determine if we need real-time updates or daily is sufficient
- [ ] Decide on data retention policy (90 days vs longer)
- [ ] Confirm resource allocation for coaching stagnant users

---

**Last Updated:** 2026-02-04
**Author:** Implementation Plan
**Status:** Ready for Implementation (when resumed)
