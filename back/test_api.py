import requests
import os
from dotenv import load_dotenv
import json

load_dotenv()

def test_dendreo_api():
    api_key = os.getenv('DENDREO_API_KEY')
    base_url = os.getenv('DENDREO_BASE_URL')

    url = f"{base_url}/lmps.php"
    params = {
        'key': api_key,
        'include': 'participant,module'
    }

    print(f"Testing API call to: {url}")
    print(f"Params: {params}")

    try:
        # Test with a short timeout
        response = requests.get(url, params=params, timeout=10)
        print(f"Status Code: {response.status_code}")
        print(f"Response Headers: {dict(response.headers)}")

        if response.status_code == 200:
            data = response.json()
            print(f"Data type: {type(data)}")

            if isinstance(data, list):
                print(f"Number of records: {len(data)}")
                if len(data) > 0:
                    print(f"First record keys: {list(data[0].keys())}")
                    # Save first record to file for inspection
                    with open('sample_record.json', 'w') as f:
                        json.dump(data[0], f, indent=2)
                    print("Saved first record to sample_record.json")
            else:
                print(f"Data: {data}")
        else:
            print(f"Error response: {response.text}")

    except requests.exceptions.Timeout:
        print("Request timed out!")
    except requests.exceptions.ConnectionError:
        print("Connection error!")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_dendreo_api()
