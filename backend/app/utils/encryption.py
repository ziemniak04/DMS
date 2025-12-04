"""
Encryption utilities for sensitive data
Used to encrypt/decrypt Dexcom refresh tokens before storing in database
"""
from cryptography.fernet import Fernet
from app.config import get_settings


class EncryptionService:
    """Service for encrypting and decrypting sensitive data"""

    def __init__(self):
        settings = get_settings()
        key = settings.ENCRYPTION_KEY.encode() if settings.ENCRYPTION_KEY else None

        if not key:
            raise ValueError(
                "ENCRYPTION_KEY not set in environment. "
                "Generate one with: python -c \"from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())\""
            )

        self.cipher = Fernet(key)

    def encrypt(self, plaintext: str) -> str:
        """
        Encrypt plaintext string

        Args:
            plaintext: String to encrypt

        Returns:
            Encrypted string (base64 encoded)
        """
        encrypted_bytes = self.cipher.encrypt(plaintext.encode())
        return encrypted_bytes.decode()

    def decrypt(self, ciphertext: str) -> str:
        """
        Decrypt ciphertext string

        Args:
            ciphertext: Encrypted string (base64 encoded)

        Returns:
            Decrypted plaintext string
        """
        decrypted_bytes = self.cipher.decrypt(ciphertext.encode())
        return decrypted_bytes.decode()


# Global encryption service instance
_encryption_service = None


def get_encryption_service() -> EncryptionService:
    """Get encryption service instance"""
    global _encryption_service
    if _encryption_service is None:
        _encryption_service = EncryptionService()
    return _encryption_service


def encrypt(plaintext: str) -> str:
    """
    Encrypt plaintext string using the global encryption service.

    Args:
        plaintext: String to encrypt

    Returns:
        Encrypted string (base64 encoded)
    """
    service = get_encryption_service()
    return service.encrypt(plaintext)


def decrypt(ciphertext: str) -> str:
    """
    Decrypt ciphertext string using the global encryption service.

    Args:
        ciphertext: Encrypted string (base64 encoded)

    Returns:
        Decrypted plaintext string
    """
    service = get_encryption_service()
    return service.decrypt(ciphertext)
