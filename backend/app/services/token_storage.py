"""
Token storage service for managing Dexcom OAuth tokens.

Handles encryption, storage, retrieval, and refresh of tokens.
"""
from sqlalchemy.orm import Session
from typing import Optional, Tuple
from datetime import datetime, timezone
from app.models.database import User, DexcomToken
from app.models.dexcom import OAuthToken
from app.utils.encryption import encrypt, decrypt
from app.services.dexcom_api import DexcomAPIClient
from fastapi import HTTPException, status


class TokenStorageService:
    """Service for managing encrypted token storage and retrieval"""

    def __init__(self, db: Session):
        self.db = db

    def get_or_create_user(
        self, firebase_uid: Optional[str] = None, email: Optional[str] = None
    ) -> User:
        """
        Get existing user or create a new one.

        Args:
            firebase_uid: Firebase user ID (optional for now)
            email: User email (optional for now)

        Returns:
            User: The user instance
        """
        # Try to find existing user
        user = None
        if firebase_uid:
            user = self.db.query(User).filter(User.firebase_uid == firebase_uid).first()
        elif email:
            user = self.db.query(User).filter(User.email == email).first()

        # Create new user if not found
        if not user:
            user = User(firebase_uid=firebase_uid, email=email, is_active=True)
            self.db.add(user)
            self.db.commit()
            self.db.refresh(user)

        return user

    def store_tokens(
        self,
        user_id: int,
        oauth_token: OAuthToken,
        state: Optional[str] = None,
        scope: str = "offline_access",
    ) -> DexcomToken:
        """
        Store or update Dexcom OAuth tokens for a user.

        Encrypts tokens before storage. If user already has tokens, updates them.
        Otherwise, creates a new token record.

        Args:
            user_id: User ID
            oauth_token: OAuthToken from Dexcom API
            state: OAuth state parameter (optional)
            scope: OAuth scope (default: offline_access)

        Returns:
            DexcomToken: The stored/updated token record
        """
        # Encrypt tokens
        encrypted_access = encrypt(oauth_token.access_token)
        encrypted_refresh = encrypt(oauth_token.refresh_token)

        # Calculate expiration time
        expires_at = DexcomToken.calculate_expires_at(oauth_token.expires_in)

        # Check if user already has tokens
        existing_token = (
            self.db.query(DexcomToken)
            .filter(DexcomToken.user_id == user_id, DexcomToken.is_revoked == False)
            .first()
        )

        if existing_token:
            # Update existing tokens
            existing_token.access_token_encrypted = encrypted_access
            existing_token.refresh_token_encrypted = encrypted_refresh
            existing_token.token_type = oauth_token.token_type
            existing_token.expires_in = oauth_token.expires_in
            existing_token.expires_at = expires_at
            existing_token.scope = scope
            existing_token.updated_at = datetime.now(timezone.utc)
            token_record = existing_token
        else:
            # Create new token record
            token_record = DexcomToken(
                user_id=user_id,
                access_token_encrypted=encrypted_access,
                refresh_token_encrypted=encrypted_refresh,
                token_type=oauth_token.token_type,
                expires_in=oauth_token.expires_in,
                expires_at=expires_at,
                state=state,
                scope=scope,
                is_revoked=False,
            )
            self.db.add(token_record)

        self.db.commit()
        self.db.refresh(token_record)
        return token_record

    def get_valid_token(self, user_id: int, auto_refresh: bool = True) -> Tuple[str, DexcomToken]:
        """
        Get a valid access token for the user.

        Automatically refreshes the token if it's expired or expiring soon.

        Args:
            user_id: User ID
            auto_refresh: Whether to automatically refresh expired tokens (default: True)

        Returns:
            Tuple[str, DexcomToken]: (decrypted_access_token, token_record)

        Raises:
            HTTPException: If no valid token found or refresh fails
        """
        # Get the user's latest non-revoked token
        token_record = (
            self.db.query(DexcomToken)
            .filter(DexcomToken.user_id == user_id, DexcomToken.is_revoked == False)
            .order_by(DexcomToken.created_at.desc())
            .first()
        )

        if not token_record:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="No Dexcom authorization found. Please authorize with Dexcom first.",
            )

        # Check if token is expired or expiring soon
        if auto_refresh and token_record.is_expiring_soon(threshold_seconds=300):
            # Token is expired or expiring in the next 5 minutes, refresh it
            try:
                refresh_token = decrypt(token_record.refresh_token_encrypted)
                dexcom_client = DexcomAPIClient()
                new_oauth_token = dexcom_client.refresh_access_token(refresh_token)

                # Store the new tokens
                token_record = self.store_tokens(
                    user_id=user_id, oauth_token=new_oauth_token, scope=token_record.scope
                )
            except Exception as e:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail=f"Failed to refresh access token. User may need to re-authorize: {str(e)}",
                )

        # Decrypt and return access token
        access_token = decrypt(token_record.access_token_encrypted)
        return access_token, token_record

    def get_refresh_token(self, user_id: int) -> str:
        """
        Get the decrypted refresh token for a user.

        Args:
            user_id: User ID

        Returns:
            str: Decrypted refresh token

        Raises:
            HTTPException: If no valid token found
        """
        token_record = (
            self.db.query(DexcomToken)
            .filter(DexcomToken.user_id == user_id, DexcomToken.is_revoked == False)
            .first()
        )

        if not token_record:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="No Dexcom authorization found.",
            )

        return decrypt(token_record.refresh_token_encrypted)

    def revoke_tokens(self, user_id: int) -> None:
        """
        Revoke all tokens for a user.

        This marks tokens as revoked but doesn't delete them for audit purposes.

        Args:
            user_id: User ID
        """
        tokens = self.db.query(DexcomToken).filter(
            DexcomToken.user_id == user_id, DexcomToken.is_revoked == False
        )

        for token in tokens:
            token.is_revoked = True
            token.revoked_at = datetime.now(timezone.utc)

        self.db.commit()

    def get_token_info(self, user_id: int) -> Optional[dict]:
        """
        Get token information for a user (without decrypting sensitive data).

        Args:
            user_id: User ID

        Returns:
            dict: Token metadata (expires_at, is_expired, etc.)
        """
        token_record = (
            self.db.query(DexcomToken)
            .filter(DexcomToken.user_id == user_id, DexcomToken.is_revoked == False)
            .first()
        )

        if not token_record:
            return None

        return {
            "user_id": token_record.user_id,
            "token_type": token_record.token_type,
            "expires_at": token_record.expires_at.isoformat(),
            "is_expired": token_record.is_expired(),
            "is_expiring_soon": token_record.is_expiring_soon(),
            "scope": token_record.scope,
            "created_at": token_record.created_at.isoformat(),
            "updated_at": token_record.updated_at.isoformat(),
        }
