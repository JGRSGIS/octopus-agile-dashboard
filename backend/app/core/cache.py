"""
Cache management for price and consumption data.
Supports in-memory caching with optional Redis backend.
"""

import json
import logging
from dataclasses import dataclass, field
from datetime import UTC, datetime, timedelta
from typing import Any

from app.core.config import settings

logger = logging.getLogger(__name__)


@dataclass
class CacheEntry:
    """Represents a cached item with expiration."""

    data: Any
    expires_at: datetime
    created_at: datetime = field(default_factory=lambda: datetime.now(UTC))

    @property
    def is_expired(self) -> bool:
        """Check if the cache entry has expired."""
        return datetime.now(UTC) > self.expires_at


class CacheManager:
    """
    Manages caching for the application.
    Uses in-memory cache with optional Redis for distributed caching.
    """

    def __init__(self):
        self._memory_cache: dict[str, CacheEntry] = {}
        self._redis_client = None
        self._initialized = False

    async def initialize(self) -> None:
        """Initialize the cache manager."""
        if self._initialized:
            return

        # Try to initialize Redis if configured
        if settings.REDIS_URL:
            try:
                import redis.asyncio as redis

                self._redis_client = redis.from_url(settings.REDIS_URL)
                await self._redis_client.ping()
                logger.info("Redis cache initialized successfully")
            except Exception as e:
                logger.warning(
                    f"Failed to initialize Redis cache: {e}. Using memory cache only."
                )
                self._redis_client = None

        self._initialized = True
        logger.info("Cache manager initialized")

    async def close(self) -> None:
        """Close cache connections."""
        if self._redis_client:
            await self._redis_client.close()
            logger.info("Redis connection closed")

    async def get(self, key: str) -> Any | None:
        """
        Get a value from cache.
        Checks memory cache first, then Redis if available.
        """
        if not settings.CACHE_ENABLED:
            return None

        # Check memory cache
        if key in self._memory_cache:
            entry = self._memory_cache[key]
            if not entry.is_expired:
                logger.debug(f"Cache hit (memory): {key}")
                return entry.data
            else:
                # Remove expired entry
                del self._memory_cache[key]

        # Check Redis if available
        if self._redis_client:
            try:
                data = await self._redis_client.get(key)
                if data:
                    logger.debug(f"Cache hit (Redis): {key}")
                    parsed = json.loads(data)
                    # Also store in memory for faster subsequent access
                    self._set_memory(key, parsed)
                    return parsed
            except Exception as e:
                logger.warning(f"Redis get error: {e}")

        logger.debug(f"Cache miss: {key}")
        return None

    async def set(self, key: str, value: Any, ttl_seconds: int | None = None) -> None:
        """
        Set a value in cache.
        Stores in both memory and Redis if available.
        """
        if not settings.CACHE_ENABLED:
            return

        ttl = ttl_seconds or settings.CACHE_TTL_SECONDS

        # Set in memory cache
        self._set_memory(key, value, ttl)

        # Set in Redis if available
        if self._redis_client:
            try:
                await self._redis_client.setex(key, ttl, json.dumps(value, default=str))
                logger.debug(f"Cached to Redis: {key} (TTL: {ttl}s)")
            except Exception as e:
                logger.warning(f"Redis set error: {e}")

    def _set_memory(self, key: str, value: Any, ttl_seconds: int | None = None) -> None:
        """Set a value in memory cache."""
        ttl = ttl_seconds or settings.CACHE_TTL_SECONDS
        expires_at = datetime.now(UTC) + timedelta(seconds=ttl)

        self._memory_cache[key] = CacheEntry(data=value, expires_at=expires_at)
        logger.debug(f"Cached to memory: {key} (TTL: {ttl}s)")

    async def delete(self, key: str) -> None:
        """Delete a key from cache."""
        if key in self._memory_cache:
            del self._memory_cache[key]

        if self._redis_client:
            try:
                await self._redis_client.delete(key)
            except Exception as e:
                logger.warning(f"Redis delete error: {e}")

    async def clear(self, pattern: str = "*") -> None:
        """Clear cache entries matching pattern."""
        # Clear memory cache
        if pattern == "*":
            self._memory_cache.clear()
        else:
            keys_to_delete = [
                k for k in self._memory_cache if pattern.replace("*", "") in k
            ]
            for key in keys_to_delete:
                del self._memory_cache[key]

        # Clear Redis if available
        if self._redis_client:
            try:
                if pattern == "*":
                    await self._redis_client.flushdb()
                else:
                    keys = await self._redis_client.keys(pattern)
                    if keys:
                        await self._redis_client.delete(*keys)
            except Exception as e:
                logger.warning(f"Redis clear error: {e}")

    def generate_price_cache_key(
        self, period_from: datetime | None = None, period_to: datetime | None = None
    ) -> str:
        """Generate a cache key for price data."""
        from_str = period_from.isoformat() if period_from else "none"
        to_str = period_to.isoformat() if period_to else "none"
        return f"prices:{settings.REGION}:{from_str}:{to_str}"

    def generate_consumption_cache_key(
        self, period_from: datetime | None = None, period_to: datetime | None = None
    ) -> str:
        """Generate a cache key for consumption data."""
        from_str = period_from.isoformat() if period_from else "none"
        to_str = period_to.isoformat() if period_to else "none"
        return f"consumption:{settings.MPAN}:{from_str}:{to_str}"


# Global cache manager instance
cache_manager = CacheManager()
