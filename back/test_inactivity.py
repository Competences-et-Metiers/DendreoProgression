"""
Quick test script for inactivity tracking feature
"""
import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.models.database import get_db_session
from app.services.inactivity_service import InactivityService


def test_inactivity_service():
    """Test the inactivity service with default thresholds"""
    print("Testing Inactivity Service...")
    print("=" * 60)

    with get_db_session() as db:
        # Initialize service with default thresholds
        service = InactivityService(db=db)

        print("\n1. Testing flat list (not grouped)")
        print("-" * 60)
        result = service.get_inactive_participants(group_by_course=False)

        print(f"Total participants checked: {result.total_participants_checked}")
        print(f"Total inactive: {result.total_inactive}")
        print(f"  - At-risk: {result.at_risk_count}")
        print(f"  - Stalled: {result.stalled_count}")
        print(f"  - Long inactive: {result.long_inactive_count}")
        print(f"Newly enrolled excluded: {result.newly_enrolled_excluded}")
        print(f"Completed excluded: {result.completed_excluded}")

        if result.participants:
            print(f"\nTop 5 most inactive participants:")
            for p in result.participants[:5]:
                print(f"  - {p.nom} {p.prenom}: {p.days_inactive} days inactive "
                      f"({p.inactivity_status}, {p.current_progression:.1f}% complete)")

        print("\n2. Testing grouped by course")
        print("-" * 60)
        result_grouped = service.get_inactive_participants(group_by_course=True)

        print(f"Total inactive: {result_grouped.total_inactive}")
        print(f"Courses with inactive participants: {len(result_grouped.by_course) if result_grouped.by_course else 0}")

        if result_grouped.by_course:
            print(f"\nTop 5 courses by inactive count:")
            for course in result_grouped.by_course[:5]:
                print(f"  - {course.course_title}: {course.total_inactive} inactive "
                      f"(stalled: {course.stalled_count}, long: {course.long_inactive_count})")

        print("\n3. Testing with custom thresholds (stricter)")
        print("-" * 60)
        service_strict = InactivityService(
            db=db,
            inactivity_threshold_days=21,
            long_inactivity_threshold_days=45,
            at_risk_threshold_days=14
        )
        result_strict = service_strict.get_inactive_participants(group_by_course=False)

        print(f"Total inactive (strict thresholds): {result_strict.total_inactive}")
        print(f"  - At-risk (>14 days): {result_strict.at_risk_count}")
        print(f"  - Stalled (>21 days): {result_strict.stalled_count}")
        print(f"  - Long inactive (>45 days): {result_strict.long_inactive_count}")

        print("\n" + "=" * 60)
        print("✓ Test completed successfully!")
        return True


if __name__ == "__main__":
    try:
        test_inactivity_service()
    except Exception as e:
        print(f"\n❌ Test failed with error:")
        print(f"{type(e).__name__}: {str(e)}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
