from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.models.database import get_db
from app.models.models import User
from app.models.schemas import LoginRequest, TokenResponse, UserResponse, ChangePasswordRequest, MessageResponse
from app.auth.utils import verify_password, create_access_token, hash_password
from app.auth.dependencies import get_current_user
import logging

logger = logging.getLogger(__name__)
router = APIRouter()


@router.post("/login", response_model=TokenResponse)
async def login(request: LoginRequest, db: Session = Depends(get_db)):
    """
    Authenticate user and return JWT token.
    """
    # Find user by username
    user = db.query(User).filter(User.username == request.username).first()

    if user is None:
        logger.warning(f"Login attempt failed: user '{request.username}' not found")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Verify password
    if not verify_password(request.password, user.hashed_password):
        logger.warning(f"Login attempt failed: invalid password for user '{request.username}'")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Check if user is active
    if not user.is_active:
        logger.warning(f"Login attempt failed: user '{request.username}' is inactive")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User account is inactive",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Create access token with role
    access_token = create_access_token(data={"sub": user.username, "role": user.role})

    logger.info(f"User '{request.username}' logged in successfully (role: {user.role})")

    return TokenResponse(access_token=access_token)


@router.get("/me", response_model=UserResponse)
async def get_current_user_info(current_user: User = Depends(get_current_user)):
    """
    Get current authenticated user information.
    """
    return current_user


@router.put("/change-password", response_model=MessageResponse)
async def change_password(
    request: ChangePasswordRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Change password for the currently authenticated user.

    Requires:
    - current_password: User's current password for verification
    - new_password: New password to set
    """
    # Verify current password
    if not verify_password(request.current_password, current_user.hashed_password):
        logger.warning(f"Password change failed: incorrect current password for user '{current_user.username}'")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Current password is incorrect"
        )

    # Validate new password is different
    if request.current_password == request.new_password:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="New password must be different from current password"
        )

    # Hash and update password
    current_user.hashed_password = hash_password(request.new_password)
    db.commit()

    logger.info(f"Password changed successfully for user '{current_user.username}'")

    return MessageResponse(message="Password changed successfully")
