# Docker Setup Guide

Quick reference for running the DMS Backend with Docker.

## Quick Start

```bash
cd backend

# 1. Create .env file
cp .env.example .env
# Edit .env with your credentials

# 2. Start the backend
docker-compose up -d

# 3. Check it's running
docker-compose ps
curl http://localhost:8000/health
```

## Docker Files Overview

| File | Purpose |
|------|---------|
| `Dockerfile` | Production-ready multi-stage build |
| `docker-compose.yml` | Development orchestration |
| `.dockerignore` | Optimize build context |

## Common Commands

### Starting & Stopping

```bash
# Start in detached mode
docker-compose up -d

# Start with rebuild
docker-compose up -d --build

# Stop
docker-compose down

# Stop and remove volumes
docker-compose down -v
```

### Viewing Logs

```bash
# Follow logs
docker-compose logs -f backend

# Last 100 lines
docker-compose logs --tail=100 backend
```

### Debugging

```bash
# Execute commands in container
docker-compose exec backend python --version
docker-compose exec backend pip list

# Interactive shell
docker-compose exec backend bash

# Check health
curl http://localhost:8000/health
```

### Building

```bash
# Build with docker-compose
docker-compose build

# Build standalone image
docker build -t dms-backend:latest .

# Build with specific tag
docker build -t dms-backend:v1.0.0 .
```

## Production Deployment

### Standalone Container

```bash
# Build production image
docker build -t dms-backend:prod .

# Run with env file
docker run -d \
  --name dms-backend \
  -p 8000:8000 \
  --env-file .env \
  --restart unless-stopped \
  dms-backend:prod

# View logs
docker logs -f dms-backend

# Stop
docker stop dms-backend
docker rm dms-backend
```

### With External Database

```bash
# Start PostgreSQL
docker run -d \
  --name dms-postgres \
  -e POSTGRES_DB=dms \
  -e POSTGRES_USER=dms_user \
  -e POSTGRES_PASSWORD=dms_password \
  -p 5432:5432 \
  postgres:15-alpine

# Update .env
# DATABASE_URL=postgresql://dms_user:dms_password@dms-postgres:5432/dms

# Start backend linked to database
docker run -d \
  --name dms-backend \
  --link dms-postgres:postgres \
  -p 8000:8000 \
  --env-file .env \
  dms-backend:prod
```

### With Docker Network

```bash
# Create network
docker network create dms-network

# Run database
docker run -d \
  --name dms-postgres \
  --network dms-network \
  -e POSTGRES_DB=dms \
  -e POSTGRES_USER=dms_user \
  -e POSTGRES_PASSWORD=dms_password \
  postgres:15-alpine

# Run Redis
docker run -d \
  --name dms-redis \
  --network dms-network \
  redis:7-alpine

# Run backend
docker run -d \
  --name dms-backend \
  --network dms-network \
  -p 8000:8000 \
  --env-file .env \
  dms-backend:prod
```

## Multi-Service Setup

Edit `docker-compose.yml` to uncomment PostgreSQL and Redis:

```yaml
services:
  backend:
    # ... existing config
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:15-alpine
    # ... (uncomment in docker-compose.yml)

  redis:
    image: redis:7-alpine
    # ... (uncomment in docker-compose.yml)
```

Then start everything:

```bash
docker-compose up -d
```

## Environment Variables

Required in `.env`:

```bash
# Dexcom API
DEXCOM_CLIENT_ID=your_client_id
DEXCOM_CLIENT_SECRET=your_client_secret
DEXCOM_REDIRECT_URI=http://localhost:8000/auth/callback
DEXCOM_ENVIRONMENT=sandbox

# Encryption
ENCRYPTION_KEY=your_encryption_key

# Firebase
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_CREDENTIALS_PATH=/app/firebase-credentials.json
```

## Health Checks

The container includes built-in health checks:

```bash
# Check health status
docker inspect --format='{{.State.Health.Status}}' dms-backend

# View health check logs
docker inspect --format='{{range .State.Health.Log}}{{.Output}}{{end}}' dms-backend
```

Health check endpoint: `http://localhost:8000/health`

Expected response:
```json
{
  "status": "healthy",
  "timestamp": "2024-12-04T12:00:00",
  "service": "DMS Backend API"
}
```

## Volumes & Persistence

### Mount Firebase Credentials

```bash
# In docker-compose.yml (already configured)
volumes:
  - ./firebase-credentials.json:/app/firebase-credentials.json:ro
```

### Development Hot Reload

```bash
# In docker-compose.yml (already configured)
volumes:
  - ./app:/app/app  # Mount source code
```

Changes to Python files will trigger auto-reload.

## Security Notes

- Container runs as non-root user (UID 1000)
- Read-only mounts for credentials
- No unnecessary packages in production image
- Multi-stage build reduces attack surface
- Health checks for reliability

## Troubleshooting

### Port Conflict

```bash
# Use different port
docker-compose up -d
# Change ports in docker-compose.yml:
# ports:
#   - "8001:8000"
```

### Container Exits Immediately

```bash
# Check logs
docker-compose logs backend

# Common issues:
# - Missing .env file
# - Invalid ENCRYPTION_KEY
# - Wrong Python version
```

### Permission Denied

```bash
# Fix file ownership
sudo chown -R 1000:1000 app/

# Or run with current user
docker-compose run --user $(id -u):$(id -g) backend
```

### Image Too Large

```bash
# Check image size
docker images dms-backend

# Clean up
docker system prune -a
docker builder prune
```

Multi-stage build should keep image under 200MB.

## Performance Tips

1. **Use BuildKit** for faster builds:
   ```bash
   DOCKER_BUILDKIT=1 docker build -t dms-backend .
   ```

2. **Cache dependencies**:
   - Requirements are copied before code
   - Only rebuild when requirements.txt changes

3. **Limit log size**:
   ```yaml
   logging:
     driver: "json-file"
     options:
       max-size: "10m"
       max-file: "3"
   ```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Build Docker Image

on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build image
        run: |
          cd backend
          docker build -t dms-backend:${{ github.sha }} .
      - name: Test
        run: |
          docker run dms-backend:${{ github.sha }} pytest
```

## Registry Push

```bash
# Tag for registry
docker tag dms-backend:latest registry.example.com/dms-backend:latest

# Push to registry
docker push registry.example.com/dms-backend:latest

# Pull on production server
docker pull registry.example.com/dms-backend:latest
```

## Resources

- [Dockerfile Reference](https://docs.docker.com/engine/reference/builder/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [FastAPI in Docker](https://fastapi.tiangolo.com/deployment/docker/)
