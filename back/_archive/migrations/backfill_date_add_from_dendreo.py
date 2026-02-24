#!/usr/bin/env python3
"""
Backfill date_add column in participant_courses table from Dendreo API
This script fetches the actual date_add from Dendreo's LAP data and updates existing records.
"""

import sys
import logging
import asyncio
from pathlib import Path
from datetime import datetime
from typing import Dict, Set

# Add the app directory to the path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from app.config.settings import settings
from app.models.database import get_db, engine
from app.models.models import ParticipantCourse, Course, Participant
from app.services.dendreo_client import DendreoClient, DendreoAPIError
from sqlalchemy import text

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class DateAddBackfillService:
    def __init__(self, db, client: DendreoClient):
        self.db = db
        self.client = client
        self.stats = {
            "total_participant_courses": 0,
            "records_to_update": 0,
            "records_updated": 0,
            "records_failed": 0,
            "adfs_processed": 0
        }

    async def backfill_date_add(self):
        """Backfill date_add for all participant_courses from Dendreo LAP data"""
        try:
            logger.info("🚀 Starting date_add backfill from Dendreo API")

            # Get all participant_courses that need date_add
            participant_courses = self.db.query(ParticipantCourse).filter(
                ParticipantCourse.id_lap.isnot(None),
                ParticipantCourse.date_add.is_(None)
            ).all()

            self.stats["total_participant_courses"] = len(participant_courses)
            logger.info(f"📊 Found {len(participant_courses)} participant_courses without date_add")

            if not participant_courses:
                logger.info("✅ No records to backfill")
                return self.stats

            # Group by ADF to minimize API calls
            adf_to_pc_map: Dict[str, list] = {}  # {id_action_formation: [participant_courses]}
            for pc in participant_courses:
                course = self.db.query(Course).filter(Course.id == pc.course_id).first()
                if course and course.id_action_formation:
                    if course.id_action_formation not in adf_to_pc_map:
                        adf_to_pc_map[course.id_action_formation] = []
                    adf_to_pc_map[course.id_action_formation].append(pc)

            self.stats["records_to_update"] = len(participant_courses)
            logger.info(f"📦 Processing {len(adf_to_pc_map)} unique ADFs")

            # Process each ADF
            for adf_id, pcs in adf_to_pc_map.items():
                try:
                    await self._process_adf_for_backfill(adf_id, pcs)
                    self.stats["adfs_processed"] += 1

                    # Commit after each ADF to avoid large transactions
                    self.db.commit()
                    logger.info(f"✅ Completed ADF {adf_id} ({self.stats['adfs_processed']}/{len(adf_to_pc_map)})")

                except Exception as e:
                    logger.error(f"❌ Error processing ADF {adf_id}: {e}")
                    self.db.rollback()
                    self.stats["records_failed"] += len(pcs)
                    continue

            logger.info(f"🎉 Backfill completed! Stats: {self.stats}")
            return self.stats

        except Exception as e:
            logger.error(f"❌ Backfill failed: {str(e)}")
            self.db.rollback()
            raise

    async def _process_adf_for_backfill(self, adf_id: str, participant_courses: list):
        """Process a single ADF to backfill date_add for its participant_courses"""
        try:
            # Fetch LAP data for this ADF
            laps_data = await self.client.get_laps(adf_id)
            if not laps_data:
                logger.warning(f"⚠️  No LAP data found for ADF {adf_id}")
                return

            logger.info(f"📦 Found {len(laps_data)} LAPs for ADF {adf_id}")

            # Create a mapping of id_lap -> date_add from LAP data
            lap_date_map: Dict[str, datetime] = {}
            for lap_record in laps_data:
                id_lap = lap_record.get('id_lap')
                participant_data = lap_record.get('participant', {})
                date_add_str = participant_data.get('date_add')

                if id_lap and date_add_str:
                    try:
                        date_add = datetime.strptime(date_add_str, '%Y-%m-%d %H:%M:%S')
                        lap_date_map[id_lap] = date_add
                    except ValueError as e:
                        logger.warning(f"Invalid date format for LAP {id_lap}: {e}")

            logger.info(f"📅 Extracted {len(lap_date_map)} date_add values from LAPs")

            # Update participant_courses with date_add
            updated_count = 0
            for pc in participant_courses:
                if pc.id_lap in lap_date_map:
                    pc.date_add = lap_date_map[pc.id_lap]
                    pc.updated_at = datetime.utcnow()
                    updated_count += 1
                else:
                    logger.warning(f"⚠️  No date_add found for LAP {pc.id_lap} in ADF {adf_id}")
                    self.stats["records_failed"] += 1

            self.stats["records_updated"] += updated_count
            logger.info(f"✅ Updated {updated_count} participant_courses for ADF {adf_id}")

        except DendreoAPIError as e:
            logger.error(f"❌ API error for ADF {adf_id}: {e}")
            raise
        except Exception as e:
            logger.error(f"❌ Error processing ADF {adf_id}: {e}")
            raise

async def main():
    """Main backfill function"""
    try:
        logger.info("🔧 Initializing backfill service...")

        # Initialize database and client
        db = next(get_db())
        client = DendreoClient()

        # Create backfill service
        service = DateAddBackfillService(db, client)

        # Run backfill
        stats = await service.backfill_date_add()

        # Print summary
        print("\n" + "=" * 60)
        print("📊 BACKFILL SUMMARY")
        print("=" * 60)
        print(f"Total participant_courses found: {stats['total_participant_courses']}")
        print(f"Records to update: {stats['records_to_update']}")
        print(f"ADFs processed: {stats['adfs_processed']}")
        print(f"Records updated: {stats['records_updated']}")
        print(f"Records failed: {stats['records_failed']}")
        print("=" * 60)

        if stats['records_failed'] > 0:
            print(f"\n⚠️  Warning: {stats['records_failed']} records could not be updated")
            print("Check the logs for details")

        print("\n🎉 Backfill completed successfully!")

    except Exception as e:
        logger.error(f"❌ Backfill failed: {str(e)}")
        print(f"\n❌ Backfill failed: {str(e)}")
        sys.exit(1)
    finally:
        if 'db' in locals():
            db.close()

if __name__ == "__main__":
    # Run the async main function
    asyncio.run(main())
