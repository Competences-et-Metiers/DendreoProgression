#!/usr/bin/env python3
"""
HubSpot ID Import Script
Matches emails from Excel file with participants in database and creates/updates their HubSpot transaction IDs
in the participant_hubspot_data table using data from participant_courses.
"""

import sys
import logging
import pandas as pd
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from pathlib import Path
from datetime import datetime

# Add the app directory to the path
sys.path.append(str(Path(__file__).parent))

from app.config.settings import settings
from app.models.models import Participant, ParticipantHubspotData, ParticipantCourse, Course

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def import_hubspot_ids(excel_file_path: str):
    """
    Import HubSpot IDs from Excel file and match with participants by email
    Creates/updates participant_hubspot_data records using data from participant_courses
    
    Args:
        excel_file_path: Path to the Excel file containing HubSpot IDs and emails
    """
    
    try:
        logger.info(f"Reading Excel file: {excel_file_path}")
        
        # Read Excel file
        df = pd.read_excel(excel_file_path)
        
        # Assuming Column A is HubSpot ID and Column B is email
        # Adjust column names if needed
        if 'A' in df.columns and 'B' in df.columns:
            hubspot_col = 'A'
            email_col = 'B'
        else:
            # Try to find columns by position (0-indexed)
            hubspot_col = df.columns[0]  # First column
            email_col = df.columns[1]    # Second column
        
        logger.info(f"Using columns: HubSpot ID = '{hubspot_col}', Email = '{email_col}'")
        logger.info(f"Found {len(df)} rows in Excel file")
        
        # Clean the data
        df = df.dropna(subset=[hubspot_col, email_col])  # Remove rows with missing data
        df[email_col] = df[email_col].str.strip().str.lower()  # Clean emails
        df[hubspot_col] = df[hubspot_col].astype(str).str.strip()  # Clean HubSpot IDs
        
        logger.info(f"After cleaning: {len(df)} valid rows")
        
        # Connect to database
        logger.info(f"Connecting to database: {settings.database_url}")
        engine = create_engine(settings.database_url)
        SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
        db = SessionLocal()
        
        try:
            # Get all participants from database
            participants = db.query(Participant).all()
            logger.info(f"Found {len(participants)} participants in database")
            
            # Create email to participant mapping
            participant_by_email = {p.email.lower().strip(): p for p in participants if p.email}
            logger.info(f"Created mapping for {len(participant_by_email)} participants with emails")
            
            # Track statistics
            stats = {
                "matched": 0,
                "created": 0,
                "updated": 0,
                "not_found": 0,
                "no_participant_courses": 0,
                "already_had_hubspot_id": 0
            }
            
            # Process each row in Excel
            for index, row in df.iterrows():
                hubspot_id = str(row[hubspot_col]).strip()
                email = str(row[email_col]).strip().lower()
                
                # Skip if email is empty or invalid
                if not email or email == 'nan':
                    continue
                
                # Find participant by email
                participant = participant_by_email.get(email)
                
                if participant:
                    stats["matched"] += 1
                    
                    # Get all participant_courses for this participant
                    participant_courses = db.query(ParticipantCourse).filter(
                        ParticipantCourse.participant_id == participant.id,
                        ParticipantCourse.id_lap.isnot(None)  # Only courses with LAP IDs
                    ).all()
                    
                    if participant_courses:
                        # Group participant courses by ADF to avoid duplicates
                        adf_groups = {}
                        for pc in participant_courses:
                            course = db.query(Course).filter(Course.id == pc.course_id).first()
                            if course and course.id_action_formation:
                                adf_id = course.id_action_formation
                                if adf_id not in adf_groups:
                                    adf_groups[adf_id] = pc  # Store the first participant course for this ADF
                        
                        # Process each unique ADF for this participant
                        for adf_id, pc in adf_groups.items():
                            # Check if HubSpot data record already exists
                            existing_hubspot_data = db.query(ParticipantHubspotData).filter(
                                ParticipantHubspotData.participant_id == participant.id,
                                ParticipantHubspotData.id_action_formation == adf_id
                            ).first()
                            
                            if existing_hubspot_data:
                                # Update existing record
                                if existing_hubspot_data.c_id_transaction_hubspot:
                                    stats["already_had_hubspot_id"] += 1
                                    logger.debug(f"Participant {email} already has HubSpot ID: {existing_hubspot_data.c_id_transaction_hubspot} for ADF {adf_id}")
                                else:
                                    existing_hubspot_data.c_id_transaction_hubspot = hubspot_id
                                    existing_hubspot_data.updated_at = datetime.utcnow()
                                    stats["updated"] += 1
                                    logger.debug(f"Updated {email} with HubSpot ID: {hubspot_id} for ADF {adf_id}")
                            else:
                                # Create new HubSpot data record
                                new_hubspot_data = ParticipantHubspotData(
                                    participant_id=participant.id,
                                    id_action_formation=adf_id,
                                    id_lap=pc.id_lap,
                                    c_id_transaction_hubspot=hubspot_id,
                                    created_at=datetime.utcnow(),
                                    updated_at=datetime.utcnow()
                                )
                                db.add(new_hubspot_data)
                                stats["created"] += 1
                                logger.debug(f"Created HubSpot data for {email} with ID: {hubspot_id} for ADF {adf_id}")
                    else:
                        stats["no_participant_courses"] += 1
                        logger.debug(f"Participant {email} found but has no participant courses with LAP IDs")
                else:
                    stats["not_found"] += 1
                    logger.debug(f"Participant not found for email: {email}")
            
            # Commit changes
            db.commit()
            logger.info("✅ Database changes committed successfully")
            
            # Print summary
            logger.info("📊 Import Summary:")
            logger.info(f"  - Total rows processed: {len(df)}")
            logger.info(f"  - Participants matched: {stats['matched']}")
            logger.info(f"  - HubSpot records created: {stats['created']}")
            logger.info(f"  - HubSpot records updated: {stats['updated']}")
            logger.info(f"  - Already had HubSpot ID: {stats['already_had_hubspot_id']}")
            logger.info(f"  - Participants without courses/LAPs: {stats['no_participant_courses']}")
            logger.info(f"  - Not found in database: {stats['not_found']}")
            
            return stats
            
        except Exception as e:
            db.rollback()
            logger.error(f"❌ Database error: {e}")
            raise
        finally:
            db.close()
            
    except Exception as e:
        logger.error(f"❌ Import failed: {e}")
        raise

def main():
    """Main function"""
    if len(sys.argv) != 2:
        print("Usage: python import_hubspot_ids.py <excel_file_path>")
        print("Example: python import_hubspot_ids.py 'import id transac dendreo NO DUPES.xlsx'")
        sys.exit(1)
    
    excel_file_path = sys.argv[1]
    
    # Check if file exists
    if not Path(excel_file_path).exists():
        logger.error(f"❌ File not found: {excel_file_path}")
        sys.exit(1)
    
    try:
        stats = import_hubspot_ids(excel_file_path)
        print(f"\n🎉 Import completed successfully!")
        print(f"📊 Created {stats['created']} new HubSpot data records")
        print(f"📊 Updated {stats['updated']} existing HubSpot data records")
        
        if stats['no_participant_courses'] > 0:
            print(f"⚠️  {stats['no_participant_courses']} participants found but have no courses with LAP IDs")
            print("   These participants may not be enrolled in any courses yet.")
        
    except Exception as e:
        print(f"\n❌ Import failed: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main() 