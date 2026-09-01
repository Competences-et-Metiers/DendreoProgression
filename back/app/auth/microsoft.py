"""
Microsoft Entra ID (Azure AD) authentication module.

Handles:
- ID token validation via JWKS
- User provisioning and role mapping from security groups
"""

import asyncio
import logging
import time
from typing import Optional

import httpx
from authlib.jose import jwt as authlib_jwt, JsonWebKey
from sqlalchemy.orm import Session

from app.config.settings import settings
from app.models.models import User

logger = logging.getLogger(__name__)

_jwks_cache = None
_openid_config_cache = None
_jwks_refresh_lock = asyncio.Lock()
_jwks_last_refreshed_at = 0.0

# Cap how often we refetch JWKS so a stream of tokens with unknown kids can't
# hammer Microsoft's endpoint. Microsoft rotates keys on the order of weeks.
_JWKS_MIN_REFRESH_INTERVAL_SECONDS = 60


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


async def get_jwks(force_refresh: bool = False) -> dict:
    """
    Fetch and cache Microsoft's JSON Web Key Set for token validation.

    Pass force_refresh=True after a decode failure to pick up rotated keys.
    """
    global _jwks_cache, _jwks_last_refreshed_at

    if _jwks_cache and not force_refresh:
        return _jwks_cache

    async with _jwks_refresh_lock:
        now = time.monotonic()
        # Another coroutine may have refreshed while we waited for the lock,
        # or a recent refresh may already have happened — don't refetch within
        # the rate-limit window even if asked.
        if _jwks_cache and force_refresh and (now - _jwks_last_refreshed_at) < _JWKS_MIN_REFRESH_INTERVAL_SECONDS:
            return _jwks_cache
        if _jwks_cache and not force_refresh:
            return _jwks_cache

        config = await get_openid_config()
        jwks_uri = config["jwks_uri"]
        async with httpx.AsyncClient() as client:
            resp = await client.get(jwks_uri)
            resp.raise_for_status()
            _jwks_cache = resp.json()
        _jwks_last_refreshed_at = now
        logger.info("Refreshed Microsoft JWKS cache")
    return _jwks_cache


async def validate_id_token(id_token: str) -> dict:
    """
    Validate Microsoft ID token signature and claims.
    Returns the decoded token claims.
    """
    jwks = await get_jwks()

    try:
        claims = authlib_jwt.decode(id_token, JsonWebKey.import_key_set(jwks))
    except Exception:
        # Signature or kid mismatch is the symptom of a Microsoft key rotation.
        # Refetch JWKS once and retry; if it still fails, the error propagates.
        jwks = await get_jwks(force_refresh=True)
        claims = authlib_jwt.decode(id_token, JsonWebKey.import_key_set(jwks))

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
    Updates role based on group membership on every login, unless an admin has
    set the role from the app (role_source='manual').
    """
    user = db.query(User).filter(User.microsoft_id == microsoft_id).first()

    role = determine_role_from_groups(groups)

    if user:
        # Update fields on each login (role may have changed in Entra ID).
        # A manually assigned role wins: it has no Entra group to derive it from
        # (e.g. 'billing'), so re-deriving would silently revoke it at next login.
        if user.role_source != 'manual':
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
