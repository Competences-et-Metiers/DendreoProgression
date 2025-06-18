import redis
import json
import logging
from typing import Any, Optional, Dict
from datetime import timedelta
import os

logger = logging.getLogger(__name__)

class CacheService:
    def __init__(self):
        # Use environment variables or defaults
        redis_host = os.getenv('REDIS_HOST', 'localhost')
        redis_port = int(os.getenv('REDIS_PORT', '6379'))
        redis_db = int(os.getenv('REDIS_DB', '0'))
        
        try:
            self.redis_client = redis.Redis(
                host=redis_host,
                port=redis_port,
                db=redis_db,
                decode_responses=True,
                socket_connect_timeout=5,
                socket_timeout=5
            )
            # Test connection
            self.redis_client.ping()
            logger.info(f"✅ Redis connected successfully at {redis_host}:{redis_port}")
            self.enabled = True
        except (redis.ConnectionError, redis.TimeoutError) as e:
            logger.warning(f"⚠️  Redis connection failed: {e}. Caching disabled.")
            self.enabled = False
            self.redis_client = None

    def _make_key(self, prefix: str, *args) -> str:
        """Create a cache key from prefix and arguments"""
        key_parts = [prefix] + [str(arg) for arg in args]
        return ":".join(key_parts)

    def get(self, key: str) -> Optional[Any]:
        """Get value from cache"""
        if not self.enabled:
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
        if not self.enabled:
            return False
            
        try:
            json_value = json.dumps(value, default=str)  # default=str handles datetime objects
            return self.redis_client.setex(key, ttl, json_value)
        except Exception as e:
            logger.error(f"Cache set error for key {key}: {e}")
            return False

    def delete(self, key: str) -> bool:
        """Delete key from cache"""
        if not self.enabled:
            return False
            
        try:
            return bool(self.redis_client.delete(key))
        except Exception as e:
            logger.error(f"Cache delete error for key {key}: {e}")
            return False

    def delete_pattern(self, pattern: str) -> int:
        """Delete all keys matching pattern"""
        if not self.enabled:
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

# Create global cache instance
cache_service = CacheService() 