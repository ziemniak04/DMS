# DMS Backend API

Python FastAPI backend for the Diabetes Management System with Dexcom G6/G7 API integration.

## Features

- **Dexcom API Integration**: Full support for all 6 Dexcom API v3 endpoints
  - Estimated Glucose Values (EGVs)
  - Calibration Entries
  - Data Range
  - Device Information
  - User-Entered Events
  - Alerts
- **OAuth 2.0 Authentication**: Secure Dexcom API access with token management
- **Rate Limiting**: Built-in rate limiting (60,000 requests/hour per Dexcom spec)
- **Data Encryption**: Encrypted storage for sensitive tokens
- **Firebase Authentication**: User authentication and authorization
- **RESTful API**: Clean, well-documented endpoints for Flutter frontend

## Architecture

```
backend/
├── app/
│   ├── main.py              # FastAPI app entry point
│   ├── config.py            # Configuration management
│   ├── models/              # Pydantic data models
│   │   └── dexcom.py        # Dexcom API response models
│   ├── services/            # Business logic
│   │   ├── dexcom_api.py    # Dexcom API client
│   │   └── rate_limiter.py  # Rate limiting service
│   ├── routers/             # API endpoints
│   │   ├── dexcom.py        # Dexcom endpoints
│   │   └── health.py        # Health check
│   └── utils/
│       └── encryption.py    # Encryption utilities
├── requirements.txt
├── .env.example
└── README.md
```

## Quick Start

Choose between **Local Setup** (Python) or **Docker Setup**.

### Option A: Docker Setup (Recommended)

#### 1. Prerequisites

- Docker and Docker Compose installed
- Dexcom Developer Account ([Register here](https://developer.dexcom.com/))
- Firebase project (for authentication)

#### 2. Configuration

Create a `.env` file from the example:

```bash
cd backend
cp .env.example .env
```

Edit `.env` with your credentials (see Configuration section below).

#### 3. Run with Docker Compose

```bash
# Build and start the backend
docker-compose up -d

# View logs
docker-compose logs -f backend

# Stop the backend
docker-compose down
```

The API will be available at:
- API: http://localhost:8000
- Interactive docs: http://localhost:8000/docs
- Health check: http://localhost:8000/health

#### 4. Docker Commands

```bash
# Rebuild after code changes
docker-compose up -d --build

# Run commands inside container
docker-compose exec backend python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"

# View container status
docker-compose ps

# Stop and remove containers
docker-compose down -v
```

### Option B: Local Python Setup

#### 1. Prerequisites

- Python 3.9 or higher
- Dexcom Developer Account ([Register here](https://developer.dexcom.com/))
- Firebase project (for authentication)

#### 2. Installation

```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

#### 3. Configuration

Copy the example environment file:

```bash
cp .env.example .env
```

Edit `.env` and configure:

```bash
# Dexcom API credentials (from Dexcom Developer Portal)
DEXCOM_CLIENT_ID="your_client_id"
DEXCOM_CLIENT_SECRET="your_client_secret"
DEXCOM_REDIRECT_URI="http://localhost:8000/auth/callback"
DEXCOM_ENVIRONMENT="sandbox"  # Use 'sandbox' for testing

# Generate encryption key for storing tokens
ENCRYPTION_KEY="your_encryption_key"

# Firebase configuration
FIREBASE_PROJECT_ID="your_project_id"
FIREBASE_CREDENTIALS_PATH="path/to/firebase-credentials.json"
```

Generate an encryption key:

```bash
python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

#### 4. Run the Server

```bash
# Development mode with auto-reload
uvicorn app.main:app --reload --port 8000

# Or using Python
python -m app.main
```

The API will be available at:
- API: http://localhost:8000
- Interactive docs: http://localhost:8000/docs
- Alternative docs: http://localhost:8000/redoc

## Configuration Details

All configuration is done via environment variables in the `.env` file.

## API Endpoints

### Authentication

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/dexcom/auth/url` | GET | Get OAuth authorization URL |
| `/dexcom/auth/token` | POST | Exchange code for tokens |
| `/dexcom/auth/refresh` | POST | Refresh access token |

### Dexcom Data

All data endpoints require authentication via `Authorization: Bearer <access_token>` header.

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/dexcom/egvs` | GET | Get glucose values |
| `/dexcom/calibrations` | GET | Get calibration entries |
| `/dexcom/data-range` | GET | Get available data range |
| `/dexcom/devices` | GET | Get device information |
| `/dexcom/events` | GET | Get user events (insulin, carbs, etc.) |
| `/dexcom/alerts` | GET | Get alerts |

### Health Check

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health check |
| `/` | GET | Root endpoint with API info |

## Usage Examples

### 1. OAuth Flow

```python
# Step 1: Get authorization URL
GET /dexcom/auth/url?state=random_state

# Response:
{
  "authorization_url": "https://sandbox-api.dexcom.com/v2/oauth2/login?client_id=..."
}

# Step 2: User grants access, gets redirected with code
# Your redirect URI receives: http://localhost:8000/auth/callback?code=AUTH_CODE

# Step 3: Exchange code for tokens
POST /dexcom/auth/token?code=AUTH_CODE

# Response:
{
  "access_token": "...",
  "token_type": "Bearer",
  "expires_in": 7200,
  "refresh_token": "..."
}
```

### 2. Fetch Glucose Data

```python
GET /dexcom/egvs?startDate=2024-01-01T00:00:00Z&endDate=2024-01-02T00:00:00Z
Authorization: Bearer YOUR_ACCESS_TOKEN

# Response:
{
  "recordType": "egv",
  "recordVersion": "3.0",
  "userId": "...",
  "records": [
    {
      "recordId": "...",
      "systemTime": "2024-01-01T12:00:00",
      "displayTime": "2024-01-01T12:00:00",
      "value": 120,
      "unit": "mg/dL",
      "trend": "flat",
      "trendRate": 0.5,
      ...
    }
  ]
}
```

### 3. Fetch Events (Meals, Insulin, etc.)

```python
GET /dexcom/events?startDate=2024-01-01T00:00:00Z&endDate=2024-01-02T00:00:00Z
Authorization: Bearer YOUR_ACCESS_TOKEN

# Response includes carbs, insulin, exercise, etc.
```

## Dexcom API Details

### Supported Devices
- Dexcom G6
- Dexcom G7
- Dexcom ONE
- Dexcom ONE+ (not available in US)

### Data Delay
- **US**: 1-hour delay for mobile app data
- **Outside US**: 3-hour delay for mobile app data
- **USB Uploader**: Immediate availability

### Rate Limits
- **60,000 requests per hour** per application
- Returns HTTP 429 if exceeded

### Time Range Constraints
- Maximum 30-day range for all time-based queries
- Times are in ISO 8601 format (UTC)
- `startDate` is inclusive, `endDate` is exclusive

### Sandbox Testing
- Use environment: `DEXCOM_ENVIRONMENT=sandbox`
- Test user for G7 data: "SandboxUser7"
- Sandbox URL: https://sandbox-api.dexcom.com

### Production Environments
- **US**: https://api.dexcom.com
- **EU**: https://api.dexcom.eu
- **Japan**: https://api.dexcom.jp

## Docker Production Deployment

### Using Standalone Dockerfile

Build and run the production image:

```bash
# Build the image
docker build -t dms-backend:latest .

# Run the container
docker run -d \
  --name dms-backend \
  -p 8000:8000 \
  --env-file .env \
  -v $(pwd)/firebase-credentials.json:/app/firebase-credentials.json:ro \
  dms-backend:latest
```

### Multi-Service Setup

Uncomment the PostgreSQL and Redis services in `docker-compose.yml` for a complete setup:

```yaml
# Uncomment in docker-compose.yml:
postgres:  # For database
redis:     # For distributed rate limiting
```

Then update your `.env`:

```bash
DATABASE_URL=postgresql://dms_user:dms_password@postgres:5432/dms
```

### Docker Image Features

- Multi-stage build for smaller image size
- Non-root user for security
- Health checks included
- Optimized layer caching
- Hot reload support in development

## Development

### Running Tests

```bash
# Local Python
pytest

# With Docker
docker-compose exec backend pytest
```

### Code Structure

- **models/dexcom.py**: Pydantic models matching Dexcom API responses
- **services/dexcom_api.py**: Core API client with all 6 endpoints
- **routers/dexcom.py**: FastAPI routes exposing endpoints
- **services/rate_limiter.py**: In-memory rate limiting (use Redis in production)
- **utils/encryption.py**: Token encryption/decryption

### Adding Features

1. Add models to `app/models/`
2. Add business logic to `app/services/`
3. Add routes to `app/routers/`
4. Register router in `app/main.py`

## Security Notes

- Store Dexcom refresh tokens **encrypted** in database
- Never commit `.env` file or credentials
- Use HTTPS in production
- Validate Firebase tokens for user authentication
- Implement proper CORS policies
- Consider Redis for distributed rate limiting in production

## TODO

- [ ] Implement Firebase authentication middleware
- [ ] Add database integration (Firestore or Supabase)
- [ ] Implement encrypted token storage
- [ ] Add Redis-based rate limiting for production
- [ ] Implement background sync service for periodic data fetching
- [ ] Add agent system endpoints
- [ ] Implement digital twin model
- [ ] Add PDF report generation
- [ ] Set up monitoring and logging (Sentry, etc.)

## Troubleshooting

### Issue: "ENCRYPTION_KEY not set"
Generate a key:
```bash
# Local Python
python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"

# With Docker
docker-compose exec backend python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

### Issue: "Failed to exchange code for token"
- Check `DEXCOM_CLIENT_ID` and `DEXCOM_CLIENT_SECRET`
- Verify `DEXCOM_REDIRECT_URI` matches your Dexcom app settings

### Issue: Rate limit exceeded
- Check rate limiter usage: The API tracks requests per user
- Consider implementing request caching
- In production, use Redis for distributed rate limiting

### Docker Issues

**Port already in use:**
```bash
# Change port in docker-compose.yml
ports:
  - "8001:8000"  # Use 8001 instead
```

**Container won't start:**
```bash
# Check logs
docker-compose logs backend

# Restart with rebuild
docker-compose down
docker-compose up -d --build
```

**Permission issues with volumes:**
```bash
# Fix ownership
sudo chown -R 1000:1000 ./app
```

## Resources

- [Dexcom API Documentation](https://developer.dexcom.com/docs)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Pydantic Documentation](https://docs.pydantic.dev/)

## License

Copyright © 2024 DMS Project
