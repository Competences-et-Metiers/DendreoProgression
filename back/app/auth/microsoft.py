"""
Microsoft Entra ID (Azure AD) authentication module.

Handles:
- ID token validation via JWKS
- User provisioning and role mapping from security groups
"""

import logging
from typing import Optional

import httpx
from authlib.jose import jwt as authlib_jwt, JsonWebKey
from sqlalchemy.orm import Session

from app.config.settings import settings
from app.models.models import User

logger = logging.getLogger(__name__)

# Cache JWKS keys (they rotate infrequently)
_jwks_cache = None
_openid_config_cache = None


def _get_openid_config_url() -> str:
    return f"https://login.microsoftonline.com/{settings.azure_ad_tenant_id}/v2.0/.well-known/openid-configuration"


async def get_openid_config() -> dict:
    """Fetch and cache the OpenID Connect discovery document."""
    global _openid_config_cache
    if _openid_config_cache:
        return _openid_config_cache

    async with httpx.AsyncClient() as client:
        resp = await client.get(_get_openid_config_url())
        resp.raise_for_status()
        _openid_config_cache = resp.json()
    return _openid_config_cache


async def get_jwks() -> dict:
    """Fetch and cache Microsoft's JSON Web Key Set for token validation."""
    global _jwks_cache
    if _jwks_cache:
        return _jwks_cache

    config = await get_openid_config()
    jwks_uri = config["jwks_uri"]

    async with httpx.AsyncClient() as client:
        resp = await client.get(jwks_uri)
        resp.raise_for_status()
        _jwks_cache = resp.json()
    return _jwks_cache


async def validate_id_token(id_token: str) -> dict:
    """
    Validate Microsoft ID token signature and claims.
    Returns the decoded token claims.
    """
    jwks = await get_jwks()

    claims = authlib_jwt.decode(
        id_token,
        JsonWebKey.import_key_set(jwks),
    )

    # Validate standard claims (exp, iat, nbf)
    claims.validate()

    # Verify audience matches our client ID
    if claims.get("aud") != settings.azure_ad_client_id:
        raise ValueError("ID token audience does not match client ID")

    # Verify issuer matches our tenant
    expected_issuer = f"https://login.microsoftonline.com/{settings.azure_ad_tenant_id}/v2.0"
    if claims.get("iss") != expected_issuer:
        raise ValueError("ID token issuer does not match tenant")

    return dict(claims)


def determine_role_from_groups(groups: list) -> str:
    """
    Map Microsoft security group memberships to app role.
    Admin group takes precedence over manager group if user is in both.
    Non-members default to 'user'.
    """
    groups = groups or []

    if settings.azure_ad_admin_group_id and settings.azure_ad_admin_group_id in groups:
        return 'admin'

    if settings.azure_ad_manager_group_id and settings.azure_ad_manager_group_id in groups:
        return 'manager'

    return 'user'


def find_or_create_microsoft_user(
    db: Session,
    microsoft_id: str,
    email: Optional[str],
    display_name: Optional[str],
    groups: list,
) -> User:
    """
    Find existing user by microsoft_id, or create a new one.
    Updates role based on group membership on every login.
    """
    user = db.query(User).filter(User.microsoft_id == microsoft_id).first()

    role = determine_role_from_groups(groups)

    if user:
        # Update fields on each login (role may have changed in Entra ID)
        user.role = role
        user.email = email or user.email
        user.display_name = display_name or user.display_name
        db.commit()
        db.refresh(user)
        return user

    # Create new user
    username = _generate_username(db, email, display_name)

    user = User(
        username=username,
        hashed_password=None,
        role=role,
        is_active=True,
        auth_provider='microsoft',
        microsoft_id=microsoft_id,
        email=email,
        display_name=display_name,
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    logger.info(f"Auto-created Microsoft user '{username}' (role: {role})")
    return user


def _generate_username(db: Session, email: Optional[str], display_name: Optional[str]) -> str:
    """Generate a unique username from email or display name."""
    base = "user"
    if email and "@" in email:
        base = email.split("@")[0]
    elif display_name:
        base = display_name.lower().replace(" ", ".")

    # Ensure uniqueness
    username = base
    counter = 1
    while db.query(User).filter(User.username == username).first():
        username = f"{base}{counter}"
        counter += 1

    return username
