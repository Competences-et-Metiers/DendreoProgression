#!/usr/bin/env python3
"""
HubSpot Progression Update Script
Updates HubSpot deals with overall progression data from participant_courses table.
Sends progression_e_learning property to deals for participants who have HubSpot deal IDs.

This script can be run standalone or integrated into the Dendreo sync process.
"""

import sys
import logging
import asyncio
import httpx
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session
from pathlib import Path
from typing import List, Dict, Any, Optional
import os
from datetime import datetime

# Add the app directory to the path
sys.path.append(str(Path(__file__).parent))

from app.models.database import DATABASE_URL
from app.models.models import Participant, ParticipantHubspotData, ParticipantCourse, Course

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class HubSpotProgressionUpdater:
    def __init__(self, api_key: str):
        self.api_key = api_key
        self.base_url = "https://api.hubapi.com"
        self.headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
    
    async def update_deal_progression(self, deal_id: str, progression: float, participant_email: str = None) -> bool:
        """
        Update a HubSpot deal with progression data
        
        Args:
            deal_id: HubSpot deal ID
            progression: Overall progression percentage (0-100)
            participant_email: Email for logging purposes
        
        Returns:
            bool: True if successful, False otherwise
        """
        url = f"{self.base_url}/crm/v3/objects/deals/{deal_id}"
        
        # Prepare the data payload
        # Convert percentage (0-100) to decimal (0-1) for HubSpot
        progression_decimal = round(progression / 100, 4)
        data = {
            "properties": {
                "progression_e_learning": str(progression_decimal)
            }
        }
        
        # Debug logging to see exactly what we're sending
        logger.debug(f"Sending to HubSpot deal {deal_id}: progression_e_learning = {progression_decimal} (original percentage: {progression}%)")
        
        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                response = await client.patch(url, json=data, headers=self.headers)
                
                if response.status_code == 200:
                    logger.info(f"✅ Updated deal {deal_id} with progression {progression:.2f}% for {participant_email}")
                    return True
                elif response.status_code == 404:
                    logger.warning(f"⚠️  Deal {deal_id} not found for {participant_email}")
                    return False
                else:
                    logger.error(f"❌ Failed to update deal {deal_id} for {participant_email}. Status: {response.status_code}, Response: {response.text}")
                    return False
                    
        except httpx.TimeoutException:
            logger.error(f"❌ Timeout updating deal {deal_id} for {participant_email}")
            return False
        except httpx.RequestError as e:
            logger.error(f"❌ Request error updating deal {deal_id} for {participant_email}: {str(e)}")
            return False
        except Exception as e:
            logger.error(f"❌ Unexpected error updating deal {deal_id} for {participant_email}: {str(e)}")
            return False

async def get_participants_with_hubspot_deals(db: Session) -> List[Dict[str, Any]]:
    """
    Get all participants who have HubSpot deal IDs and calculate their overall progression
    
    Returns:
        List of dictionaries containing participant data, deal ID, and progression
    """
    participants_data = []
    
    # Get all participants with HubSpot data
    hubspot_records = db.query(ParticipantHubspotData).filter(
        ParticipantHubspotData.c_id_transaction_hubspot.isnot(None)
    ).all()
    
    logger.info(f"Found {len(hubspot_records)} participants with HubSpot deal IDs")
    
    for hubspot_record in hubspot_records:
        participant = db.query(Participant).filter(
            Participant.id == hubspot_record.participant_id
        ).first()
        
        if not participant:
            logger.warning(f"Participant not found for HubSpot record {hubspot_record.id}")
            continue
        
        # Get all participant courses for this participant and ADF
        participant_courses = db.query(ParticipantCourse).join(Course).filter(
            ParticipantCourse.participant_id == participant.id,
            Course.id_action_formation == hubspot_record.id_action_formation
        ).all()
        
        if participant_courses:
            # Calculate overall progression for this ADF using the pre-calculated values
            progressions = [pc.overall_progression for pc in participant_courses if pc.overall_progression is not None]
            overall_progression = sum(progressions) / len(progressions) if progressions else 0.0
            
            # Debug logging to see what values we're working with
            logger.debug(f"Participant {participant.email} in ADF {hubspot_record.id_action_formation}:")
            logger.debug(f"  Individual progressions: {progressions}")
            logger.debug(f"  Calculated average: {overall_progression}")
        else:
            overall_progression = 0.0
        
        participants_data.append({
            "participant_id": participant.id,
            "participant_email": participant.email,
            "participant_name": f"{participant.prenom} {participant.nom}".strip(),
            "deal_id": hubspot_record.c_id_transaction_hubspot,
            "adf_id": hubspot_record.id_action_formation,
            "overall_progression": overall_progression
        })
    
    return participants_data

async def update_hubspot_progressions(api_key: str, batch_size: int = 10, delay_seconds: float = 1.0, db_session: Optional[Session] = None):
    """
    Main function to update HubSpot deals with progression data
    
    Args:
        api_key: HubSpot API key
        batch_size: Number of requests to process in parallel
        delay_seconds: Delay between batches to respect rate limits
        db_session: Optional existing database session (for integration with sync process)
    """
    
    # Use provided session or create new one
    if db_session:
        db = db_session
        should_close_db = False
        logger.info("Using provided database session")
    else:
        # Connect to database
        logger.info(f"Connecting to database: {DATABASE_URL}")
        engine = create_engine(DATABASE_URL)
        SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
        db = SessionLocal()
        should_close_db = True
    
    try:
        # Get participants with HubSpot deals
        participants_data = await get_participants_with_hubspot_deals(db)
        
        if not participants_data:
            logger.info("No participants with HubSpot deal IDs found")
            return {
                "status": "success",
                "message": "No participants with HubSpot deal IDs found",
                "total_processed": 0,
                "successful_updates": 0,
                "failed_updates": 0
            }
        
        logger.info(f"Found {len(participants_data)} participants to update")
        
        # Initialize HubSpot client
        hubspot_client = HubSpotProgressionUpdater(api_key)
        
        # Track statistics
        stats = {
            "total_processed": 0,
            "successful_updates": 0,
            "failed_updates": 0
        }
        
        # Process in batches to respect rate limits
        for i in range(0, len(participants_data), batch_size):
            batch = participants_data[i:i + batch_size]
            batch_num = (i // batch_size) + 1
            total_batches = (len(participants_data) + batch_size - 1) // batch_size
            
            logger.info(f"Processing batch {batch_num}/{total_batches} ({len(batch)} participants)")
            
            # Create tasks for this batch
            tasks = []
            for participant in batch:
                task = hubspot_client.update_deal_progression(
                    deal_id=participant["deal_id"],
                    progression=participant["overall_progression"],
                    participant_email=participant["participant_email"]
                )
                tasks.append(task)
            
            # Execute batch in parallel
            results = await asyncio.gather(*tasks, return_exceptions=True)
            
            # Process results
            for j, result in enumerate(results):
                stats["total_processed"] += 1
                
                if isinstance(result, Exception):
                    stats["failed_updates"] += 1
                    logger.error(f"Exception updating {batch[j]['participant_email']}: {result}")
                elif result:
                    stats["successful_updates"] += 1
                else:
                    stats["failed_updates"] += 1
            
            # Delay between batches to respect rate limits
            if i + batch_size < len(participants_data):
                logger.info(f"Waiting {delay_seconds} seconds before next batch...")
                await asyncio.sleep(delay_seconds)
        
        logger.info("📊 Update Summary:")
        logger.info(f"  - Total participants processed: {stats['total_processed']}")
        logger.info(f"  - Successful updates: {stats['successful_updates']}")
        logger.info(f"  - Failed updates: {stats['failed_updates']}")
        logger.info(f"  - Success rate: {(stats['successful_updates'] / stats['total_processed'] * 100):.1f}%")
        
        return {
            "status": "success",
            "message": "HubSpot progression updates completed",
            **stats
        }
        
    except Exception as e:
        logger.error(f"❌ Update process failed: {e}")
        raise
    finally:
        if should_close_db:
            db.close()

async def update_hubspot_progressions_for_sync(db_session: Session, api_key: Optional[str] = None) -> Dict[str, Any]:
    """
    Function specifically for integration with Dendreo sync process
    
    Args:
        db_session: Database session from sync process
        api_key: HubSpot API key (if None, will try to get from environment)
    
    Returns:
        Dict with update results
    """
    
    # Get API key from environment if not provided
    if not api_key:
        api_key = os.getenv('HUBSPOT_API_KEY')
        
    if not api_key:
        logger.warning("⚠️  HubSpot API key not found. Skipping HubSpot progression updates.")
        return {
            "status": "skipped",
            "message": "HubSpot API key not configured",
            "total_processed": 0,
            "successful_updates": 0,
            "failed_updates": 0
        }
    
    logger.info("🔄 Starting HubSpot progression updates after sync...")
    
    try:
        # Use smaller batch size and longer delay for sync integration to be more conservative
        result = await update_hubspot_progressions(
            api_key=api_key,
            batch_size=5,  # Smaller batches during sync
            delay_seconds=2.0,  # Longer delay during sync
            db_session=db_session
        )
        
        logger.info(f"✅ HubSpot progression updates completed: {result['successful_updates']}/{result['total_processed']} successful")
        return result
        
    except Exception as e:
        logger.error(f"❌ HubSpot progression updates failed during sync: {str(e)}")
        # Don't re-raise the exception to avoid breaking the sync process
        return {
            "status": "error",
            "message": f"HubSpot updates failed: {str(e)}",
            "total_processed": 0,
            "successful_updates": 0,
            "failed_updates": 0
        }

def main():
    """Main function"""
    
    # Get HubSpot API key from environment variable
    api_key = os.getenv('HUBSPOT_API_KEY')
    
    if not api_key:
        print("❌ Error: HUBSPOT_API_KEY environment variable is required")
        print("Set it with: $env:HUBSPOT_API_KEY=\"your_api_key_here\"")
        sys.exit(1)
    
    # Parse command line arguments
    batch_size = 10  # Default batch size
    delay_seconds = 1.0  # Default delay
    
    if len(sys.argv) > 1:
        try:
            batch_size = int(sys.argv[1])
        except ValueError:
            print("❌ Error: Batch size must be an integer")
            sys.exit(1)
    
    if len(sys.argv) > 2:
        try:
            delay_seconds = float(sys.argv[2])
        except ValueError:
            print("❌ Error: Delay must be a number")
            sys.exit(1)
    
    print(f"🚀 Starting HubSpot progression updates...")
    print(f"📊 Batch size: {batch_size}")
    print(f"⏱️  Delay between batches: {delay_seconds} seconds")
    
    try:
        # Run the async function
        result = asyncio.run(update_hubspot_progressions(api_key, batch_size, delay_seconds))
        
        print(f"\n🎉 {result['message']}")
        print(f"📊 Processed: {result['total_processed']}")
        print(f"✅ Successful: {result['successful_updates']}")
        print(f"❌ Failed: {result['failed_updates']}")
        
        if result['failed_updates'] > 0:
            print(f"\n⚠️  Some updates failed. Check the logs above for details.")
        
    except Exception as e:
        print(f"\n❌ Update failed: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main() 