# Testing Guide: Dexcom OAuth 2.0 Authentication

This guide walks you through testing the complete OAuth 2.0 authentication flow for the Dexcom API integration.

## Prerequisites

✅ Backend running on http://localhost:8000
✅ PostgreSQL running (Docker or local)
✅ Dexcom sandbox credentials configured

## Quick Start

### Option 1: Interactive HTML Test (Recommended)

1. Open `test_oauth.html` in your browser:
   ```bash
   open test_oauth.html  # macOS
   xdg-open test_oauth.html  # Linux
   ```

2. Click through the test steps in order:
   - Start OAuth Authorization
   - Check Token Status
   - Test Data Access
   - Revoke Authorization

### Option 2: Manual Command Line Testing

Follow the steps below to test each endpoint manually.

---

## Step-by-Step Testing

### Step 1: Verify Backend is Running

```bash
curl http://localhost:8000/health | jq
```

**Expected Output:**
```json
{
  "status": "healthy",
  "timestamp": "2025-12-04T17:30:43.794137",
  "service": "DMS Backend API"
}
```

---

### Step 2: Get Authorization URL

```bash
curl -s "http://localhost:8000/dexcom/auth/url?state=test_csrf_123" | jq
```

**Expected Output:**
```json
{
  "authorization_url": "https://sandbox-api.dexcom.com/v2/oauth2/login?client_id=...&redirect_uri=http://localhost:8000/dexcom/auth/callback&response_type=code&scope=offline_access&state=test_csrf_123"
}
```

**Action Required:**
Copy the `authorization_url` and open it in your browser.

---

### Step 3: Authorize with Dexcom

**Sandbox Test Credentials:**
- Username: `dexcomtest+g7` (or your sandbox account)
- Password: (your sandbox password)

**What happens:**
1. Log in with Dexcom sandbox credentials
2. Review and accept HIPAA authorization
3. You'll be redirected to: `http://localhost:8000/dexcom/auth/callback?code=...&state=test_csrf_123`
4. Backend will:
   - Exchange code for tokens
   - Encrypt and store tokens in database
   - Redirect to frontend (http://localhost:3000/auth/callback?success=true&user_id=1)

**If frontend not running:**
You'll see a connection error, but the backend callback was successful. Check the database to confirm.

---

### Step 4: Verify Tokens in Database

```bash
# Check users table
docker exec dms-postgres psql -U dms_user -d dms -c "SELECT id, email, created_at, is_active FROM users;"

# Check tokens table (without showing encrypted data)
docker exec dms-postgres psql -U dms_user -d dms -c "SELECT user_id, token_type, expires_at, is_revoked, scope FROM dexcom_tokens;"
```

**Expected Output:**
```
 user_id | token_type |         expires_at         | is_revoked |     scope
---------+------------+----------------------------+------------+----------------
       1 | Bearer     | 2025-12-04 19:30:00+00     | f          | offline_access
```

---

### Step 5: Check Token Status (API)

```bash
curl -s -H "X-User-ID: 1" http://localhost:8000/dexcom/auth/status | jq
```

**Expected Output:**
```json
{
  "authorized": true,
  "expires_at": "2025-12-04T19:30:00+00:00",
  "is_expired": false,
  "is_expiring_soon": false,
  "scope": "offline_access"
}
```

---

### Step 6: Test Data Access (Automatic Token Refresh)

Get glucose data for the last 24 hours:

```bash
END_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
START_DATE=$(date -u -d '24 hours ago' +"%Y-%m-%dT%H:%M:%SZ")

curl -s -H "X-User-ID: 1" \
  "http://localhost:8000/dexcom/egvs?start_date=$START_DATE&end_date=$END_DATE" | jq
```

**Expected Output:**
```json
{
  "recordType": "egv",
  "recordVersion": "3.0",
  "userId": "...",
  "egvs": [
    {
      "systemTime": "2025-12-04T17:00:00",
      "displayTime": "2025-12-04T17:00:00",
      "value": 120,
      "trendRate": 0.5,
      "trend": "flat",
      "unit": "mg/dL"
    }
    // ... more readings
  ]
}
```

**Note:** The backend automatically:
1. Retrieves the access token from database
2. Checks if it's expired or expiring soon (< 5 minutes)
3. If needed, refreshes the token using the refresh token
4. Stores the new tokens
5. Makes the API request

---

### Step 7: Test Manual Token Refresh

```bash
curl -s -X POST -H "X-User-ID: 1" http://localhost:8000/dexcom/auth/refresh | jq
```

**Expected Output:**
```json
{
  "message": "Token refreshed successfully",
  "expires_at": "2025-12-04T21:30:00+00:00"
}
```

**Verify in Database:**
```bash
docker exec dms-postgres psql -U dms_user -d dms -c \
  "SELECT expires_at, updated_at FROM dexcom_tokens WHERE user_id=1;"
```

---

### Step 8: Test All Data Endpoints

#### Get Data Range
```bash
curl -s -H "X-User-ID: 1" http://localhost:8000/dexcom/data-range | jq
```

#### Get Devices
```bash
curl -s -H "X-User-ID: 1" http://localhost:8000/dexcom/devices | jq
```

#### Get Events
```bash
curl -s -H "X-User-ID: 1" \
  "http://localhost:8000/dexcom/events?start_date=$START_DATE&end_date=$END_DATE" | jq
```

#### Get Alerts
```bash
curl -s -H "X-User-ID: 1" \
  "http://localhost:8000/dexcom/alerts?start_date=$START_DATE&end_date=$END_DATE" | jq
```

#### Get Calibrations
```bash
curl -s -H "X-User-ID: 1" \
  "http://localhost:8000/dexcom/calibrations?start_date=$START_DATE&end_date=$END_DATE" | jq
```

---

### Step 9: Test Token Revocation

```bash
curl -s -X POST -H "X-User-ID: 1" http://localhost:8000/dexcom/auth/revoke | jq
```

**Expected Output:**
```json
{
  "message": "Authorization revoked successfully"
}
```

**Verify in Database:**
```bash
docker exec dms-postgres psql -U dms_user -d dms -c \
  "SELECT is_revoked, revoked_at FROM dexcom_tokens WHERE user_id=1;"
```

**Test Data Access (Should Fail):**
```bash
curl -s -H "X-User-ID: 1" http://localhost:8000/dexcom/egvs?start_date=$START_DATE&end_date=$END_DATE | jq
```

**Expected Error:**
```json
{
  "detail": "No Dexcom authorization found. Please authorize with Dexcom first."
}
```

---

## Error Scenarios to Test

### 1. Expired Access Token (Automatic Refresh)

Wait for token to expire (2 hours), or manually set expiry:

```bash
docker exec dms-postgres psql -U dms_user -d dms -c \
  "UPDATE dexcom_tokens SET expires_at = NOW() - INTERVAL '1 hour' WHERE user_id=1;"
```

Then make a data request:
```bash
curl -s -H "X-User-ID: 1" "http://localhost:8000/dexcom/egvs?start_date=$START_DATE&end_date=$END_DATE" | jq
```

**Expected:** Token should refresh automatically, request succeeds.

---

### 2. Invalid Refresh Token

```bash
# Corrupt the refresh token
docker exec dms-postgres psql -U dms_user -d dms -c \
  "UPDATE dexcom_tokens SET refresh_token_encrypted = 'invalid_token' WHERE user_id=1;"
```

Then try to access data:
```bash
curl -s -H "X-User-ID: 1" "http://localhost:8000/dexcom/egvs?start_date=$START_DATE&end_date=$END_DATE" | jq
```

**Expected Error:**
```json
{
  "detail": "Failed to refresh access token. User may need to re-authorize: ..."
}
```

---

### 3. No Authorization

```bash
# Test with non-existent user
curl -s -H "X-User-ID: 999" "http://localhost:8000/dexcom/egvs?start_date=$START_DATE&end_date=$END_DATE" | jq
```

**Expected Error:**
```json
{
  "detail": "No Dexcom authorization found. Please authorize with Dexcom first."
}
```

---

### 4. Rate Limiting

```bash
# Make 100 rapid requests
for i in {1..100}; do
  curl -s -H "X-User-ID: 1" http://localhost:8000/dexcom/data-range > /dev/null
  echo "Request $i"
done
```

**Note:** Dexcom allows 60,000 requests/hour. Rate limiting is tracked but won't trigger with normal testing.

---

## Monitoring and Debugging

### View Real-time Logs

```bash
docker compose logs -f backend
```

### Check Database State

```bash
# All users
docker exec -it dms-postgres psql -U dms_user -d dms -c "SELECT * FROM users;"

# All tokens (with metadata)
docker exec -it dms-postgres psql -U dms_user -d dms -c \
  "SELECT id, user_id, token_type, expires_at, is_expired(expires_at) as expired, is_revoked FROM dexcom_tokens;"
```

### Interactive Database Session

```bash
docker exec -it dms-postgres psql -U dms_user -d dms
```

Then you can run SQL queries interactively:
```sql
-- See all tables
\dt

-- Describe table structure
\d users
\d dexcom_tokens

-- Query tokens
SELECT user_id, expires_at, NOW(), is_revoked FROM dexcom_tokens;

-- Exit
\q
```

---

## Cleanup and Reset

### Reset All Data

```bash
# Drop all tables
docker exec dms-postgres psql -U dms_user -d dms -c "DROP TABLE IF EXISTS dexcom_tokens, users CASCADE;"

# Restart backend to recreate tables
docker compose restart backend
```

### Revoke All Tokens for User

```bash
docker exec dms-postgres psql -U dms_user -d dms -c \
  "UPDATE dexcom_tokens SET is_revoked=true, revoked_at=NOW() WHERE user_id=1;"
```

### Delete User and Tokens

```bash
docker exec dms-postgres psql -U dms_user -d dms -c "DELETE FROM users WHERE id=1;"
```

---

## Production Checklist

Before deploying to production:

- [ ] Replace sandbox credentials with production Dexcom API credentials
- [ ] Update `DEXCOM_REDIRECT_URI` to production domain
- [ ] Set `DEXCOM_ENVIRONMENT=us` (or eu/jp based on region)
- [ ] Implement Firebase authentication (replace X-User-ID header)
- [ ] Enable HTTPS for all endpoints
- [ ] Set up proper CORS origins
- [ ] Implement Redis for distributed rate limiting
- [ ] Set up database backups
- [ ] Backup encryption key securely
- [ ] Enable database SSL connections
- [ ] Set up monitoring and alerting
- [ ] Implement proper logging (remove DEBUG logs)
- [ ] Add request/response validation middleware
- [ ] Set up API rate limiting per user
- [ ] Test token refresh background jobs
- [ ] Implement PKCE for enhanced security
- [ ] Add state validation for CSRF protection

---

## Troubleshooting

### "Cannot import name 'encrypt'"
**Solution:** Restart backend after code changes
```bash
docker compose restart backend
```

### "Database connection failed"
**Solution:** Check PostgreSQL is running
```bash
docker compose ps
docker compose logs postgres
```

### "Port already in use"
**Solution:** Stop conflicting service or change port in docker-compose.yml

### "Invalid encryption key"
**Solution:** Generate new key and update .env
```bash
python3 -c "import base64, os; print(base64.urlsafe_b64encode(os.urandom(32)).decode())"
```

### "Token refresh failed"
**Solution:** User needs to re-authorize. Start OAuth flow again.

---

## API Documentation

Full API documentation available at:
```
http://localhost:8000/docs
```

This provides:
- Interactive API testing
- Request/response schemas
- Authentication requirements
- Example requests

---

## Support

For issues or questions:
- Backend implementation: See `OAUTH_IMPLEMENTATION.md`
- Database setup: See `DATABASE.md`
- Dexcom API docs: https://developer.dexcom.com/
