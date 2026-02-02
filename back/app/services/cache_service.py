import redis
import json
import logging
from typing import Any, Optional, Dict
from datetime import timedelta
from urllib.parse import urlparse

logger = logging.getLogger(__name__)

class CacheService:
    def __init__(self, redis_url: str = "redis://localhost:6379/0", enabled: bool = True):
        """
        Initialize cache service with dependency injection.
        
        Args:
            redis_url: Redis connection URL
            enabled: Whether caching is enabled
        """
        self.enabled = enabled
        self.redis_client = None
        
        if not self.enabled:
            logger.info("🔄 Caching is disabled")
            return
            
        try:
            if redis_url.startswith('redis://'):
                parsed_url = urlparse(redis_url)
                redis_host = parsed_url.hostname or 'localhost'
                redis_port = parsed_url.port or 6379
                redis_db = int(parsed_url.path.lstrip('/')) if parsed_url.path else 0
            else:
                # Fallback parsing
                redis_host = 'localhost'
                redis_port = 6379
                redis_db = 0
            
            self.redis_client = redis.Redis(
                host=redis_host,
                port=redis_port,
                db=redis_db,
                decode_responses=True,
                socket_connect_timeout=5,
                socket_timeout=5,
                retry_on_timeout=True
            )
            
            # Test connection
            self.redis_client.ping()
            logger.info(f"✅ Redis connected successfully at {redis_host}:{redis_port}")
            
        except (redis.ConnectionError, redis.TimeoutError) as e:
            logger.warning(f"⚠️  Redis connection failed: {e}. Caching disabled.")
            self.enabled = False
            self.redis_client = None
        except Exception as e:
            logger.warning(f"⚠️  Redis setup failed: {e}. Caching disabled.")
            self.enabled = False
            self.redis_client = None

    def _make_key(self, prefix: str, *args) -> str:
        """Create a cache key from prefix and arguments"""
        key_parts = [prefix] + [str(arg) for arg in args]
        return ":".join(key_parts)

    def get(self, key: str) -> Optional[Any]:
        """Get value from cache"""
        if not self.enabled or not self.redis_client:
            return None
            
        try:
            value = self.redis_client.get(key)
            if value:
                return json.loads(value)
            return None
        except Exception as e:
            logger.error(f"Cache get error for key {key}: {e}")
            return None

    def set(self, key: str, value: Any, ttl: int = 300) -> bool:
        """Set value in cache with TTL (default 5 minutes)"""
        if not self.enabled or not self.redis_client:
            return False
            
        try:
            json_value = json.dumps(value, default=str)  # default=str handles datetime objects
            return self.redis_client.setex(key, ttl, json_value)
        except Exception as e:
            logger.error(f"Cache set error for key {key}: {e}")
            return False

    def delete(self, key: str) -> bool:
        """Delete key from cache"""
        if not self.enabled or not self.redis_client:
            return False
            
        try:
            return bool(self.redis_client.delete(key))
        except Exception as e:
            logger.error(f"Cache delete error for key {key}: {e}")
            return False

    def delete_pattern(self, pattern: str) -> int:
        """Delete all keys matching pattern"""
        if not self.enabled or not self.redis_client:
            return 0
            
        try:
            keys = self.redis_client.keys(pattern)
            if keys:
                return self.redis_client.delete(*keys)
            return 0
        except Exception as e:
            logger.error(f"Cache delete pattern error for pattern {pattern}: {e}")
            return 0

    def invalidate_course_cache(self):
        """Invalidate all course-related cache"""
        patterns = [
            "courses:*",
            "dashboard:*",
            "participants:course:*"
        ]
        for pattern in patterns:
            self.delete_pattern(pattern)
        logger.info("🗑️  Course cache invalidated")

    def invalidate_participant_cache(self, participant_id: Optional[int] = None):
        """Invalidate participant-related cache"""
        if participant_id:
            patterns = [
                f"participants:details:{participant_id}",
                f"participants:course:*:{participant_id}",
                "participants:list"
            ]
        else:
            patterns = [
                "participants:*",
                "dashboard:*"
            ]
        
        for pattern in patterns:
            self.delete_pattern(pattern)
        logger.info(f"🗑️  Participant cache invalidated (ID: {participant_id})")

    # Convenience methods for common cache operations
    def get_dashboard_stats(self) -> Optional[Dict]:
        """Get cached dashboard stats"""
        return self.get("dashboard:stats")

    def set_dashboard_stats(self, stats: Dict, ttl: int = 300) -> bool:
        """Cache dashboard stats (5 min TTL)"""
        return self.set("dashboard:stats", stats, ttl)

    def get_courses_list(self) -> Optional[list]:
        """Get cached courses list"""
        return self.get("courses:list")

    def set_courses_list(self, courses: list, ttl: int = 600) -> bool:
        """Cache courses list (10 min TTL)"""
        return self.set("courses:list", courses, ttl)

    def get_participants_list(self) -> Optional[list]:
        """Get cached participants list"""
        return self.get("participants:list")

    def set_participants_list(self, participants: list, ttl: int = 300) -> bool:
        """Cache participants list (5 min TTL)"""
        return self.set("participants:list", participants, ttl)

    def get_participant_details(self, participant_id: int) -> Optional[Dict]:
        """Get cached participant details"""
        return self.get(f"participants:details:{participant_id}")

    def set_participant_details(self, participant_id: int, details: Dict, ttl: int = 300) -> bool:
        """Cache participant details (5 min TTL)"""
        return self.set(f"participants:details:{participant_id}", details, ttl)

    def get_course_participants(self, course_id: int) -> Optional[Dict]:
        """Get cached course participants"""
        return self.get(f"courses:participants:{course_id}")

    def set_course_participants(self, course_id: int, participants: Dict, ttl: int = 300) -> bool:
        """Cache course participants (5 min TTL)"""
        return self.set(f"courses:participants:{course_id}", participants, ttl)

def create_cache_service(redis_url: str = "redis://localhost:6379/0", enabled: bool = True) -> CacheService:
    """Factory function to create cache service instance."""
    return CacheService(redis_url=redis_url, enabled=enabled)

# Create cache service instance using settings
def get_cache_service() -> CacheService:
    """Get cache service instance with proper dependency injection."""
    try:
        from app.config.settings import settings
        return create_cache_service(
            redis_url=settings.redis_url,
            enabled=settings.redis_enabled
        )
    except ImportError:
        # Fallback for testing or when settings aren't available
        return create_cache_service()

# Global cache instance - lazy loaded
_cache_service = None

def get_cache() -> CacheService:
    """Get the global cache service instance (lazy loaded)."""
    global _cache_service
    if _cache_service is None:
        _cache_service = get_cache_service()
    return _cache_service

# For backwards compatibility
cache_service = get_cache() 