#!/usr/bin/env python3
"""
HubSpot Connection Test Script
Tests the HubSpot API connection and deal update functionality.
"""

import asyncio
import httpx
import os
import sys
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

async def test_hubspot_connection(api_key: str):
    """Test HubSpot API connection"""
    
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }
    
    # Test 1: Get account info
    logger.info("🔍 Testing HubSpot API connection...")
    
    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            # Test basic connection with account info
            response = await client.get(
                "https://api.hubapi.com/account-info/v3/details",
                headers=headers
            )
            
            if response.status_code == 200:
                account_info = response.json()
                logger.info(f"✅ HubSpot API connection successful!")
                logger.info(f"   Account: {account_info.get('portalId', 'Unknown')}")
                logger.info(f"   Domain: {account_info.get('domain', 'Unknown')}")
                return True
            else:
                logger.error(f"❌ HubSpot API connection failed. Status: {response.status_code}")
                logger.error(f"   Response: {response.text}")
                return False
                
    except httpx.RequestError as e:
        logger.error(f"❌ Request error: {str(e)}")
        return False
    except Exception as e:
        logger.error(f"❌ Unexpected error: {str(e)}")
        return False

async def test_deal_update(api_key: str, deal_id: str = None):
    """Test updating a deal property"""
    
    if not deal_id:
        logger.info("⏭️  Skipping deal update test (no deal ID provided)")
        return True
    
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }
    
    logger.info(f"🔧 Testing deal update for deal ID: {deal_id}")
    
    # Test data
    test_progression = 75.5
    
    data = {
        "properties": {
            "progression_e_learning": str(test_progression)
        }
    }
    
    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            url = f"https://api.hubapi.com/crm/v3/objects/deals/{deal_id}"
            response = await client.patch(url, json=data, headers=headers)
            
            if response.status_code == 200:
                logger.info(f"✅ Deal update successful!")
                logger.info(f"   Updated deal {deal_id} with progression: {test_progression}%")
                return True
            elif response.status_code == 404:
                logger.warning(f"⚠️  Deal {deal_id} not found")
                return False
            else:
                logger.error(f"❌ Deal update failed. Status: {response.status_code}")
                logger.error(f"   Response: {response.text}")
                return False
                
    except httpx.RequestError as e:
        logger.error(f"❌ Request error: {str(e)}")
        return False
    except Exception as e:
        logger.error(f"❌ Unexpected error: {str(e)}")
        return False

async def main():
    """Main test function"""
    
    # Get HubSpot API key
    api_key = os.getenv('HUBSPOT_API_KEY')
    
    if not api_key:
        print("❌ Error: HUBSPOT_API_KEY environment variable is required")
        print("Set it with: $env:HUBSPOT_API_KEY=\"your_api_key_here\"")
        sys.exit(1)
    
    # Get optional deal ID for testing
    deal_id = sys.argv[1] if len(sys.argv) > 1 else None
    
    print("🚀 Starting HubSpot API tests...")
    print(f"🔑 API Key: {api_key[:10]}...{api_key[-4:] if len(api_key) > 14 else api_key}")
    
    # Test 1: Connection
    connection_ok = await test_hubspot_connection(api_key)
    
    if not connection_ok:
        print("\n❌ HubSpot API connection test failed")
        sys.exit(1)
    
    # Test 2: Deal update (if deal ID provided)
    if deal_id:
        deal_update_ok = await test_deal_update(api_key, deal_id)
        
        if deal_update_ok:
            print(f"\n✅ All tests passed! HubSpot API is ready to use.")
        else:
            print(f"\n⚠️  Connection test passed, but deal update failed.")
            print(f"   This might be due to an invalid deal ID or missing property.")
    else:
        print(f"\n✅ Connection test passed!")
        print(f"💡 To test deal updates, run: python test_hubspot_connection.py <deal_id>")

if __name__ == "__main__":
    asyncio.run(main()) 