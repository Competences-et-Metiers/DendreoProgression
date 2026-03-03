from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.models.database import get_db
from app.models.models import User
from app.models.schemas import (
    LoginRequest, TokenResponse, UserResponse,
    ChangePasswordRequest, MessageResponse,
    MicrosoftLoginRequest, MicrosoftConfigResponse,
)
from app.auth.utils import verify_password, create_access_token, hash_password
from app.auth.dependencies import get_current_user
from app.config.settings import settings
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

    # Guard: Microsoft-only users cannot use password login
    if user.auth_provider == 'microsoft' and not user.hashed_password:
        logger.warning(f"Login attempt failed: Microsoft-only user '{request.username}' tried password login")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="This account uses Microsoft login. Please sign in with Microsoft.",
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
    # Guard: Microsoft-only users cannot change password
    if current_user.auth_provider == 'microsoft' and not current_user.hashed_password:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Password change is not available for Microsoft-authenticated accounts"
        )

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


@router.get("/microsoft/config", response_model=MicrosoftConfigResponse)
async def get_microsoft_config():
    """
    Return Microsoft auth configuration for the frontend.
    Public endpoint (no auth required).
    """
    if not settings.azure_ad_enabled:
        return MicrosoftConfigResponse(enabled=False)

    return MicrosoftConfigResponse(
        enabled=True,
        client_id=settings.azure_ad_client_id,
        tenant_id=settings.azure_ad_tenant_id,
    )


@router.post("/microsoft", response_model=TokenResponse)
async def microsoft_login(request: MicrosoftLoginRequest, db: Session = Depends(get_db)):
    """
    Validate Microsoft ID token and issue app JWT.

    Flow:
    1. Frontend uses MSAL popup to authenticate with Microsoft
    2. Frontend sends the ID token here
    3. Backend validates ID token signature against Microsoft JWKS
    4. Backend extracts user info and group memberships
    5. Backend finds/creates local User record with role mapping
    6. Backend issues its own JWT (same as password login)
    """
    if not settings.azure_ad_enabled:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Microsoft authentication is not configured"
        )

    try:
        from app.auth.microsoft import validate_id_token, find_or_create_microsoft_user

        # Validate and decode ID token
        claims = await validate_id_token(request.id_token)

        # Extract user info from claims
        microsoft_id = claims.get("oid")  # Object ID - unique per user in tenant
        email = claims.get("preferred_username") or claims.get("email")
        display_name = claims.get("name")
        groups = claims.get("groups", [])

        if not microsoft_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No user identifier in Microsoft token"
            )

        # Find or create user
        user = find_or_create_microsoft_user(db, microsoft_id, email, display_name, groups)

        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User account is inactive"
            )

        # Issue app JWT (same as password login)
        access_token = create_access_token(data={"sub": user.username, "role": user.role})

        logger.info(f"Microsoft user '{user.username}' ({email}) logged in successfully (role: {user.role})")

        return TokenResponse(access_token=access_token)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Microsoft login failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Microsoft authentication failed"
        )
