#!/usr/bin/env python3
"""
Script to check if the database is empty (no participants or courses)
Returns exit code 0 if database is empty, 1 if it has data
"""

import sys
import os
from pathlib import Path

# Add the parent directory to the path so we can import from app
sys.path.insert(0, str(Path(__file__).parent.parent))

from app.models.database import get_db_session
from app.models.models import Participant, Course

def is_database_empty():
    """
    Check if the database is empty by looking for participants or courses
    Returns True if empty, False if has data
    """
    try:
        with get_db_session() as db:
            # Check for participants
            participant_count = db.query(Participant).count()
            if participant_count > 0:
                print(f"Found {participant_count} participants in database")
                return False
            
            # Check for courses
            course_count = db.query(Course).count()
            if course_count > 0:
                print(f"Found {course_count} courses in database")
                return False
            
            print("Database is empty (no participants or courses found)")
            return True
            
    except Exception as e:
        print(f"Error checking database: {str(e)}")
        # If we can't check, assume it's not empty to be safe
        return False

def main():
    """Main function - exits with 0 if database is empty, 1 if not empty"""
    if is_database_empty():
        print("Database is empty - initial sync needed")
        sys.exit(0)
    else:
        print("Database has data - no initial sync needed")
        sys.exit(1)

if __name__ == "__main__":
    main() 