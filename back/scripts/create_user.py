#!/usr/bin/env python3
"""
Script to create a new user for the Dendreo Progression dashboard.

Usage:
    python scripts/create_user.py <username> <password>

Example:
    python scripts/create_user.py admin mysecretpassword
"""

import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.models.database import SessionLocal, create_tables
from app.models.models import User
from app.auth.utils import hash_password


def create_user(username: str, password: str) -> bool:
    """Create a new user with the given username and password."""
    # Ensure tables exist
    create_tables()

    db = SessionLocal()
    try:
        # Check if user already exists
        existing_user = db.query(User).filter(User.username == username).first()
        if existing_user:
            print(f"Error: User '{username}' already exists.")
            return False

        # Create new user
        hashed_pw = hash_password(password)
        user = User(
            username=username,
            hashed_password=hashed_pw,
            is_active=True
        )

        db.add(user)
        db.commit()
        db.refresh(user)

        print(f"User '{username}' created successfully (ID: {user.id})")
        return True

    except Exception as e:
        db.rollback()
        print(f"Error creating user: {e}")
        return False

    finally:
        db.close()


def main():
    if len(sys.argv) != 3:
        print("Usage: python scripts/create_user.py <username> <password>")
        print("Example: python scripts/create_user.py admin mysecretpassword")
        sys.exit(1)

    username = sys.argv[1]
    password = sys.argv[2]

    if len(username) < 3:
        print("Error: Username must be at least 3 characters long.")
        sys.exit(1)

    if len(password) < 6:
        print("Error: Password must be at least 6 characters long.")
        sys.exit(1)

    success = create_user(username, password)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
