import logging
from typing import Dict, Any, List
from app.services.dendreo_client import DendreoClient, DendreoAPIError
from app.services.data_processor import DataProcessor
from app.models.database import get_db
from datetime import datetime

logger = logging.getLogger(__name__)

class DendreoSyncService:
    def __init__(self):
        self.client = DendreoClient()

    async def sync_all_data(self) -> Dict[str, Any]:
        """Sync all data from Dendreo API with batching"""
        try:
            logger.info("Starting full sync from Dendreo API")
            start_time = datetime.now()

            # Fetch data from API (now properly awaited)
            logger.info("Fetching data from API...")
            try:
                data = await self.client.get_lmps_data()
            except DendreoAPIError as e:
                return {
                    "status": "error",
                    "message": f"Failed to fetch data from Dendreo API: {str(e)}"
                }

            if not isinstance(data, list):
                error_msg = f"Invalid data received from Dendreo API. Expected list but got {type(data)}"
                logger.warning(error_msg)
                return {"status": "error", "message": error_msg}

            if not data:
                error_msg = "No data found in response"
                logger.warning(error_msg)
                return {"status": "error", "message": error_msg}

            logger.info(f"Received {len(data)} records from Dendreo")

            # Filter for e-learning only
            logger.info("Filtering e-learning modules...")
            elearning_records = self._filter_elearning_records(data)

            logger.info(f"Found {len(elearning_records)} records with e-learning modules")

            if not elearning_records:
                return {
                    "status": "success",
                    "message": "No e-learning records found",
                    "stats": {
                        "participants_created": 0,
                        "participants_updated": 0,
                        "courses_created": 0,
                        "courses_updated": 0,
                        "modules_created": 0,
                        "modules_updated": 0,
                        "participant_courses_created": 0,
                        "participant_courses_updated": 0
                    }
                }

            # Process data in batches
            batch_size = 50
            total_stats = {
                "participants_created": 0,
                "participants_updated": 0,
                "courses_created": 0,
                "courses_updated": 0,
                "modules_created": 0,
                "modules_updated": 0,
                "participant_courses_created": 0,
                "participant_courses_updated": 0
            }

            total_batches = (len(elearning_records) + batch_size - 1) // batch_size

            for batch_num in range(total_batches):
                start_idx = batch_num * batch_size
                end_idx = min((batch_num + 1) * batch_size, len(elearning_records))
                batch = elearning_records[start_idx:end_idx]

                logger.info(f"Processing batch {batch_num + 1}/{total_batches} ({len(batch)} records)")

                db = next(get_db())
                try:
                    processor = DataProcessor(db)
                    batch_stats = processor.process_dendreo_data(batch)
                    db.commit()

                    # Accumulate stats
                    for key in total_stats:
                        if key in batch_stats:
                            total_stats[key] += batch_stats[key]

                    logger.info(f"Batch {batch_num + 1} completed: {batch_stats}")

                except Exception as e:
                    error_msg = f"Error processing batch {batch_num + 1}: {str(e)}"
                    logger.error(error_msg)
                    db.rollback()
                    return {"status": "error", "message": error_msg}
                finally:
                    db.close()

            end_time = datetime.now()
            duration = (end_time - start_time).total_seconds()

            return {
                "status": "success",
                "message": f"Sync completed successfully in {duration:.2f} seconds",
                "stats": total_stats
            }

        except Exception as e:
            error_msg = f"Sync failed: {str(e)}"
            logger.error(error_msg)
            return {"status": "error", "message": error_msg}

    def _filter_elearning_records(self, data: List[Dict]) -> List[Dict]:
        """Filter records for e-learning modules only"""
        elearning_records = []

        for record in data:
            # Get module data from the record itself or from a nested 'module' key
            module_data = record.get('module', record)
            mode_organisation = module_data.get('mode_organisation', '')

            if mode_organisation == 'elearning_async':
                elearning_records.append(record)

        return elearning_records

    async def test_sync_small(self) -> Dict[str, Any]:
        """Test sync with small dataset"""
        try:
            logger.info("Starting test sync with small dataset")

            # Read the test data file
            import json
            with open('elearning_test_data.json', 'r') as f:
                test_data = json.load(f)

            logger.info(f"Loaded {len(test_data)} test records")

            db = next(get_db())
            try:
                processor = DataProcessor(db)
                stats = processor.process_dendreo_data(test_data)
                db.commit()
                return {
                    "status": "success",
                    "message": "Test sync completed",
                    "stats": stats
                }
            except Exception as e:
                error_msg = f"Error processing test data: {str(e)}"
                logger.error(error_msg)
                db.rollback()
                return {"status": "error", "message": error_msg}
            finally:
                db.close()

        except Exception as e:
            error_msg = f"Test sync failed: {str(e)}"
            logger.error(error_msg)
            return {"status": "error", "message": error_msg}