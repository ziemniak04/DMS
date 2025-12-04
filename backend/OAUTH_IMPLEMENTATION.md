# Dexcom OAuth 2.0 Implementation Guide

This document explains the complete OAuth 2.0 implementation for Dexcom API integration in the DMS Backend.

## Overview

The backend now implements a complete OAuth 2.0 flow with:
- ✅ Authorization URL generation
- ✅ OAuth callback handler
- ✅ Token exchange and storage
- ✅ Automatic token refresh
- ✅ Encrypted token storage in PostgreSQL
- ✅ User management

## Architecture

```
┌─────────────┐         ┌─────────────┐         ┌──────────────┐
│   Flutter   │────────▶│   Backend   │────────▶│   Dexcom     │
│   Frontend  │         │   FastAPI   │         │   OAuth API  │
└─────────────┘         └─────────────┘         └──────────────┘
                              │
                              ▼
                        ┌──────────────┐
                        │  PostgreSQL  │
                        │  (Encrypted  │
                        │   Tokens)    │
                        └──────────────┘
```

## OAuth Flow Implementation

### Step 1: Get Authorization URL

**Endpoint:** `GET /dexcom/auth/url`

**Request:**
```bash
curl http://localhost:8000/dexcom/auth/url?state=random_csrf_token
```

**Response:**
```json
{
  "authorization_url": "https://sandbox-api.dexcom.com/v2/oauth2/login?client_id=...&redirect_uri=...&response_type=code&scope=offline_access&state=random_csrf_token"
}
```

**Implementation:** `app/routers/dexcom.py:62-74`

### Step 2: User Authorizes

User is redirected to Dexcom login page where they:
1. Log in with Dexcom credentials
2. Review HIPAA authorization
3. Approve or deny access

### Step 3: OAuth Callback Handler

**Endpoint:** `GET /dexcom/auth/callback`

**Dexcom redirects to:**
```
http://localhost:8000/dexcom/auth/callback?code=AUTH_CODE&state=random_csrf_token
```

**What happens:**
1. Receives authorization code from Dexcom
2. Validates the code (and optionally state for CSRF protection)
3. Exchanges code for access_token and refresh_token
4. Creates or retrieves user from database
5. Encrypts tokens using Fernet encryption
6. Stores encrypted tokens in PostgreSQL
7. Redirects to frontend with success/error status

**Success redirect:**
```
http://localhost:3000/auth/callback?success=true&user_id=1
```

**Error redirect:**
```
http://localhost:3000/auth/callback?error=token_exchange_failed
```

**Implementation:** `app/routers/dexcom.py:77-151`

### Step 4: Token Storage

Tokens are encrypted and stored in the `dexcom_tokens` table:

```python
# Encryption (app/services/token_storage.py)
encrypted_access = encrypt(oauth_token.access_token)
encrypted_refresh = encrypt(oauth_token.refresh_token)

# Storage
DexcomToken(
    user_id=user_id,
    access_token_encrypted=encrypted_access,
    refresh_token_encrypted=encrypted_refresh,
    expires_at=calculated_expiry,
    ...
)
```

**Implementation:** `app/services/token_storage.py:65-104`

### Step 5: Making API Requests

All data endpoints automatically retrieve and validate tokens:

**Endpoint:** `GET /dexcom/egvs`

**Request:**
```bash
curl -H "X-User-ID: 1" \
  "http://localhost:8000/dexcom/egvs?start_date=2024-01-01T00:00:00Z&end_date=2024-01-02T00:00:00Z"
```

**What happens:**
1. Extract user_id from request (X-User-ID header or Firebase JWT)
2. Retrieve user's token from database
3. Check if token is expired or expiring soon (< 5 minutes)
4. If expired, automatically refresh using refresh_token
5. Decrypt access_token
6. Make API request to Dexcom with Bearer token
7. Return data to client

**Implementation:** `app/routers/dexcom.py:290-330` (example: /egvs)

### Step 6: Automatic Token Refresh

Token refresh happens automatically in `token_storage.get_valid_token()`:

```python
# Check if token is expiring soon (within 5 minutes)
if token_record.is_expiring_soon(threshold_seconds=300):
    # Automatically refresh
    refresh_token = decrypt(token_record.refresh_token_encrypted)
    new_oauth_token = dexcom_client.refresh_access_token(refresh_token)

    # Store new tokens (refresh token is single-use)
    token_record = store_tokens(user_id, new_oauth_token)
```

**Implementation:** `app/services/token_storage.py:106-147`

## API Endpoints

### Authentication Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/dexcom/auth/url` | GET | Get authorization URL |
| `/dexcom/auth/callback` | GET | OAuth callback handler (redirect from Dexcom) |
| `/dexcom/auth/token` | POST | Manual token exchange (alternative to callback) |
| `/dexcom/auth/refresh` | POST | Manual token refresh |
| `/dexcom/auth/status` | GET | Get token status for user |
| `/dexcom/auth/revoke` | POST | Revoke user's authorization |

### Data Endpoints (All require authentication)

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/dexcom/egvs` | GET | Estimated Glucose Values |
| `/dexcom/calibrations` | GET | Calibration entries |
| `/dexcom/data-range` | GET | Available data range |
| `/dexcom/devices` | GET | Device information |
| `/dexcom/events` | GET | User events (insulin, carbs, etc.) |
| `/dexcom/alerts` | GET | Alert data |

## User Authentication

### Current Implementation (Temporary)

For testing, user identification uses `X-User-ID` header:

```bash
curl -H "X-User-ID: 1" http://localhost:8000/dexcom/egvs?...
```

Default user_id = 1 is used if header is not provided.

**Implementation:** `app/routers/dexcom.py:31-54`

### Future Implementation (Firebase)

Replace `get_user_id()` with Firebase JWT validation:

```python
async def get_user_id(request: Request) -> int:
    # Extract Firebase JWT from Authorization header
    auth_header = request.headers.get("Authorization")
    token = auth_header.replace("Bearer ", "")

    # Validate Firebase token
    decoded_token = firebase_admin.auth.verify_id_token(token)
    firebase_uid = decoded_token['uid']

    # Get user from database by firebase_uid
    user = db.query(User).filter(User.firebase_uid == firebase_uid).first()
    return user.id
```

## Security Features

### 1. Token Encryption

All tokens are encrypted using Fernet (symmetric encryption):

```python
from cryptography.fernet import Fernet

# Generate key (once)
key = Fernet.generate_key()

# Encrypt
cipher = Fernet(key)
encrypted = cipher.encrypt(token.encode())

# Decrypt
decrypted = cipher.decrypt(encrypted).decode()
```

**Key storage:** Environment variable `ENCRYPTION_KEY`

**Implementation:** `app/utils/encryption.py`

### 2. Token Expiration Handling

- Access tokens expire after 2 hours (7200 seconds)
- Refresh tokens valid for up to 1 year
- Automatic refresh 5 minutes before expiration
- Expiration time tracked in database

**Implementation:** `app/models/database.py:82-97`

### 3. Token Revocation

Users can revoke authorization:

```bash
curl -X POST -H "X-User-ID: 1" http://localhost:8000/dexcom/auth/revoke
```

Tokens are marked as revoked (not deleted) for audit purposes.

**Implementation:** `app/services/token_storage.py:187-203`

### 4. CSRF Protection

State parameter supported for CSRF protection:

```python
# Generate random state
import secrets
state = secrets.token_urlsafe(32)

# Include in authorization URL
url = client.get_authorization_url(state)

# Validate in callback
# TODO: Compare state with session-stored value
```

## Error Handling

### HTTP 401 - Unauthorized

**Cause:** No valid token found or token expired and refresh failed

**Solution:** User needs to re-authorize via `/dexcom/auth/url`

### HTTP 400 - Bad Request

**Cause:** Invalid authorization code or refresh token

**Possible reasons:**
- Code already used (codes are single-use)
- Code expired (1 minute expiration)
- Refresh token already used
- User revoked authorization
- User changed password

**Solution:** Initiate new OAuth flow

### HTTP 429 - Rate Limit Exceeded

**Cause:** Exceeded Dexcom's 60,000 requests/hour limit

**Solution:** Wait before making more requests

## Testing the Implementation

### 1. Start the Backend

```bash
cd /home/vanguard/dev/PWr/dms/DMS/backend
uvicorn app.main:app --reload
```

### 2. Get Authorization URL

```bash
curl http://localhost:8000/dexcom/auth/url
```

### 3. Visit Authorization URL

Open the returned URL in a browser and log in with Dexcom sandbox credentials.

### 4. Check Database

After authorization, verify token storage:

```sql
SELECT * FROM users;
SELECT user_id, token_type, expires_at, is_expired FROM dexcom_tokens;
```

### 5. Test Data Endpoint

```bash
curl -H "X-User-ID: 1" \
  "http://localhost:8000/dexcom/egvs?start_date=2024-01-01T00:00:00Z&end_date=2024-01-02T00:00:00Z"
```

### 6. Check Token Status

```bash
curl -H "X-User-ID: 1" http://localhost:8000/dexcom/auth/status
```

## File Structure

```
app/
├── database.py                 # Database connection & session
├── models/
│   ├── database.py            # User & DexcomToken models
│   └── dexcom.py              # Pydantic models for API
├── services/
│   ├── dexcom_api.py          # Dexcom API client
│   └── token_storage.py       # Token encryption & storage
├── routers/
│   └── dexcom.py              # OAuth & data endpoints
└── utils/
    └── encryption.py          # Fernet encryption helpers

alembic/                       # Database migrations
├── env.py                     # Alembic environment
├── script.py.mako            # Migration template
└── versions/                  # Migration files
```

## Configuration

Required environment variables in `.env`:

```bash
# Dexcom API
DEXCOM_CLIENT_ID="your_client_id"
DEXCOM_CLIENT_SECRET="your_client_secret"
DEXCOM_REDIRECT_URI="http://localhost:8000/dexcom/auth/callback"
DEXCOM_ENVIRONMENT="sandbox"

# Database
DATABASE_URL="postgresql://postgres:password@localhost:5432/dms_db"

# Encryption
ENCRYPTION_KEY="your_generated_encryption_key"
```

## Next Steps

### Immediate

1. ✅ OAuth callback endpoint - IMPLEMENTED
2. ✅ Token storage with encryption - IMPLEMENTED
3. ✅ Automatic token refresh - IMPLEMENTED

### Future Enhancements

1. **Firebase Authentication**
   - Replace X-User-ID header with Firebase JWT validation
   - Link Firebase UID to database users

2. **Frontend Integration**
   - Configure correct frontend callback URL
   - Handle success/error redirects
   - Store user session

3. **CSRF Protection**
   - Store state parameter in user session
   - Validate state in callback

4. **PKCE (Proof Key for Code Exchange)**
   - Add code_challenge to authorization request
   - Add code_verifier to token exchange
   - Enhanced security for mobile apps

5. **Token Refresh Background Job**
   - Proactively refresh tokens before expiration
   - Reduce latency on API requests

6. **Rate Limiting**
   - Implement Redis-based rate limiting
   - Track per-user API usage
   - Quota management

7. **Monitoring & Logging**
   - Log all OAuth events
   - Monitor token refresh failures
   - Alert on high error rates

## Compliance & Privacy

- ✅ Tokens encrypted at rest
- ✅ Tokens never exposed to client
- ✅ Users can revoke access anytime
- ✅ Audit trail maintained (created_at, updated_at, revoked_at)
- ⚠️ Ensure HIPAA compliance for production deployment
- ⚠️ Regular security audits recommended

## Troubleshooting

### "No Dexcom authorization found"

**Solution:** User needs to authorize via OAuth flow first

### "Failed to refresh access token"

**Causes:**
- User revoked authorization on Dexcom.com
- User changed password
- Refresh token expired (max 1 year)

**Solution:** Re-initiate OAuth flow

### "Database connection failed"

**Solution:** Check DATABASE_URL and ensure PostgreSQL is running

### "Encryption/Decryption failed"

**Cause:** Wrong ENCRYPTION_KEY or corrupted data

**Solution:** Ensure ENCRYPTION_KEY hasn't changed. If lost, users must re-authorize.

## Support

For issues or questions:
- Backend code: `app/routers/dexcom.py`, `app/services/token_storage.py`
- Database: `DATABASE.md`
- Dexcom API: https://developer.dexcom.com/
