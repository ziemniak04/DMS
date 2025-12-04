"""
Rate limiting service
Tracks API usage to stay within Dexcom's 60,000 requests/hour limit
"""
from datetime import datetime, timedelta
from typing import Dict, Optional
import asyncio


class RateLimiter:
    """
    Simple in-memory rate limiter for Dexcom API calls

    In production, this should use Redis or similar distributed cache
    to track rate limits across multiple backend instances.
    """

    def __init__(self, max_requests: int = 60000, window_seconds: int = 3600):
        """
        Initialize rate limiter

        Args:
            max_requests: Maximum number of requests allowed per window
            window_seconds: Time window in seconds (default: 1 hour)
        """
        self.max_requests = max_requests
        self.window_seconds = window_seconds
        self._request_log: Dict[str, list] = {}  # user_id -> list of timestamps
        self._lock = asyncio.Lock()

    async def is_allowed(self, user_id: str) -> tuple[bool, Optional[int]]:
        """
        Check if request is allowed for user

        Args:
            user_id: User identifier

        Returns:
            Tuple of (is_allowed, remaining_requests)
        """
        async with self._lock:
            now = datetime.utcnow()
            window_start = now - timedelta(seconds=self.window_seconds)

            # Initialize user's request log if not exists
            if user_id not in self._request_log:
                self._request_log[user_id] = []

            # Remove requests outside the current window
            self._request_log[user_id] = [
                ts for ts in self._request_log[user_id] if ts > window_start
            ]

            # Check if under limit
            current_count = len(self._request_log[user_id])
            if current_count >= self.max_requests:
                return False, 0

            # Record this request
            self._request_log[user_id].append(now)
            remaining = self.max_requests - current_count - 1

            return True, remaining

    async def get_usage(self, user_id: str) -> Dict[str, int]:
        """
        Get current usage statistics for user

        Args:
            user_id: User identifier

        Returns:
            Dictionary with usage stats
        """
        async with self._lock:
            now = datetime.utcnow()
            window_start = now - timedelta(seconds=self.window_seconds)

            if user_id not in self._request_log:
                return {
                    "requests_in_window": 0,
                    "max_requests": self.max_requests,
                    "remaining": self.max_requests,
                    "window_seconds": self.window_seconds,
                }

            # Clean old requests
            self._request_log[user_id] = [
                ts for ts in self._request_log[user_id] if ts > window_start
            ]

            current_count = len(self._request_log[user_id])
            return {
                "requests_in_window": current_count,
                "max_requests": self.max_requests,
                "remaining": self.max_requests - current_count,
                "window_seconds": self.window_seconds,
            }

    async def reset_user(self, user_id: str):
        """
        Reset rate limit for specific user (admin function)

        Args:
            user_id: User identifier
        """
        async with self._lock:
            if user_id in self._request_log:
                del self._request_log[user_id]


# Global rate limiter instance
# In production, consider using dependency injection
rate_limiter = RateLimiter(max_requests=60000, window_seconds=3600)
