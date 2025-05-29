import requests
import os
from dotenv import load_dotenv
import json
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

load_dotenv()

def test_small_sync():
    """Test sync with only first few records"""
    api_key = os.getenv('DENDREO_API_KEY')
    base_url = os.getenv('DENDREO_BASE_URL')

    url = f"{base_url}/lmps.php"
    params = {
        'key': api_key,
        'include': 'participant,module'
    }

    logger.info("Fetching data from API...")

    try:
        response = requests.get(url, params=params, timeout=30)

        if response.status_code != 200:
            print(f"API Error: {response.status_code}")
            return

        data = response.json()
        logger.info(f"Received {len(data)} total records")

        # Take only first 5 records for testing
        test_data = data[:5]
        logger.info(f"Testing with {len(test_data)} records")

        # Filter for e-learning
        elearning_records = []
        for i, record in enumerate(test_data):
            module = record.get('module', {})
            mode = module.get('mode_organisation', '')

            print(f"Record {i+1}: mode_organisation = '{mode}'")

            if mode in ['elearning_async', 'elearning_sync']:
                elearning_records.append(record)
                print(f"  -> Added to e-learning records")

        logger.info(f"Found {len(elearning_records)} e-learning records")

        if len(elearning_records) > 0:
            # Save the filtered records for inspection
            with open('elearning_test_data.json', 'w') as f:
                json.dump(elearning_records, f, indent=2)
            print("Saved e-learning test data to elearning_test_data.json")

            # Test processing one record
            test_record = elearning_records[0]
            print("\nTesting single record processing:")
            print(f"Participant: {test_record['participant']['email']}")
            print(f"Module: {test_record['module']['intitule']}")
            print(f"Mode: {test_record['module']['mode_organisation']}")
            print(f"Progression: {test_record.get('lms_progression', 'N/A')}")
            print(f"Last Access: {test_record.get('lms_last_access_at', 'N/A')}")

    except Exception as e:
        logger.error(f"Error: {e}")

if __name__ == "__main__":
    test_small_sync()
