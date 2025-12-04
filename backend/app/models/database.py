"""
Database models for User and OAuth Token storage
"""
from sqlalchemy import Column, String, Integer, DateTime, ForeignKey, Boolean, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from datetime import datetime, timedelta
from app.database import Base


class User(Base):
    """
    User model for storing user information.

    In future, this will be linked to Firebase authentication.
    For now, we'll use a simple user identifier.
    """

    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    firebase_uid = Column(String(128), unique=True, nullable=True, index=True)  # Firebase UID
    email = Column(String(255), unique=True, nullable=True, index=True)
    dexcom_user_id = Column(String(255), unique=True, nullable=True, index=True)  # Dexcom user ID
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )
    is_active = Column(Boolean, default=True, nullable=False)

    # Relationship to tokens
    tokens = relationship("DexcomToken", back_populates="user", cascade="all, delete-orphan")

    def __repr__(self):
        return f"<User(id={self.id}, email={self.email})>"


class DexcomToken(Base):
    """
    Dexcom OAuth token storage model.

    Stores encrypted access and refresh tokens for Dexcom API access.
    Tokens are encrypted using the encryption service before storage.
    """

    __tablename__ = "dexcom_tokens"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)

    # Encrypted tokens (stored as encrypted strings)
    access_token_encrypted = Column(Text, nullable=False)
    refresh_token_encrypted = Column(Text, nullable=False)

    # Token metadata
    token_type = Column(String(50), default="Bearer", nullable=False)
    expires_in = Column(Integer, nullable=False)  # Seconds until expiration
    expires_at = Column(DateTime(timezone=True), nullable=False)  # Calculated expiration time

    # Audit fields
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )

    # Authorization metadata
    state = Column(String(255), nullable=True)  # OAuth state parameter
    scope = Column(String(255), default="offline_access", nullable=False)

    # Revocation tracking
    is_revoked = Column(Boolean, default=False, nullable=False)
    revoked_at = Column(DateTime(timezone=True), nullable=True)

    # Relationship to user
    user = relationship("User", back_populates="tokens")

    def __repr__(self):
        return f"<DexcomToken(id={self.id}, user_id={self.user_id}, expires_at={self.expires_at})>"

    def is_expired(self) -> bool:
        """Check if the access token is expired"""
        return datetime.now(self.expires_at.tzinfo) >= self.expires_at

    def is_expiring_soon(self, threshold_seconds: int = 300) -> bool:
        """
        Check if the access token is expiring soon (within threshold_seconds).

        Default threshold is 5 minutes (300 seconds).
        This is useful for proactive token refresh.
        """
        threshold = timedelta(seconds=threshold_seconds)
        return datetime.now(self.expires_at.tzinfo) >= (self.expires_at - threshold)

    @staticmethod
    def calculate_expires_at(expires_in: int) -> datetime:
        """
        Calculate the expiration datetime from expires_in seconds.

        Args:
            expires_in: Number of seconds until token expires (typically 7200 for Dexcom)

        Returns:
            datetime: The calculated expiration time
        """
        from datetime import timezone

        return datetime.now(timezone.utc) + timedelta(seconds=expires_in)
