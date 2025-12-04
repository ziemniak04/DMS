# Database Setup and Migration Guide

This guide explains how to set up the database and manage migrations for the DMS Backend.

## Prerequisites

- PostgreSQL installed locally or access to a PostgreSQL instance (Supabase, etc.)
- Python dependencies installed (`pip install -r requirements.txt`)
- `.env` file configured with `DATABASE_URL`

## Database Schema

The application uses two main tables:

### Users Table
Stores user information and links to Firebase authentication.

```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    firebase_uid VARCHAR(128) UNIQUE,
    email VARCHAR(255) UNIQUE,
    dexcom_user_id VARCHAR(255) UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE
);
```

### Dexcom Tokens Table
Stores encrypted OAuth tokens for Dexcom API access.

```sql
CREATE TABLE dexcom_tokens (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    access_token_encrypted TEXT NOT NULL,
    refresh_token_encrypted TEXT NOT NULL,
    token_type VARCHAR(50) DEFAULT 'Bearer',
    expires_in INTEGER NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    state VARCHAR(255),
    scope VARCHAR(255) DEFAULT 'offline_access',
    is_revoked BOOLEAN DEFAULT FALSE,
    revoked_at TIMESTAMP WITH TIME ZONE
);
```

## Initial Setup

### 1. Configure Database URL

Add your PostgreSQL connection string to `.env`:

```bash
# Local PostgreSQL
DATABASE_URL="postgresql://postgres:password@localhost:5432/dms_db"

# Or Supabase
DATABASE_URL="postgresql://postgres:password@db.xxxxx.supabase.co:5432/postgres"

# Or Docker
DATABASE_URL="postgresql://postgres:password@db:5432/dms_db"
```

### 2. Configure Encryption Key

Generate and add an encryption key for storing Dexcom tokens:

```bash
python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

Add the generated key to `.env`:

```bash
ENCRYPTION_KEY="your_generated_key_here"
```

### 3. Create Database (if using local PostgreSQL)

```bash
# Connect to PostgreSQL
psql -U postgres

# Create database
CREATE DATABASE dms_db;

# Grant permissions (if needed)
GRANT ALL PRIVILEGES ON DATABASE dms_db TO postgres;

# Exit
\q
```

## Database Initialization

The application automatically creates tables on startup using SQLAlchemy's `Base.metadata.create_all()`.

To manually initialize the database:

```python
from app.database import init_db
init_db()
```

## Database Migrations with Alembic

For production environments, use Alembic for managing database schema changes.

### Initialize Alembic (Already Done)

The Alembic configuration is already set up. If you need to reinitialize:

```bash
alembic init alembic
```

### Create Initial Migration

Generate a migration from the current models:

```bash
cd /home/vanguard/dev/PWr/dms/DMS/backend
alembic revision --autogenerate -m "Initial migration with users and tokens"
```

### Apply Migrations

```bash
# Upgrade to latest version
alembic upgrade head

# Downgrade one version
alembic downgrade -1

# View migration history
alembic history

# View current version
alembic current
```

### Create New Migrations

When you modify models, create a new migration:

```bash
alembic revision --autogenerate -m "Add new column to users table"
alembic upgrade head
```

## Common Database Operations

### Reset Database

⚠️ **Warning:** This will delete all data!

```bash
# Drop all tables
alembic downgrade base

# Recreate tables
alembic upgrade head
```

### Backup Database

```bash
# Backup entire database
pg_dump -U postgres -d dms_db > backup.sql

# Backup specific tables
pg_dump -U postgres -d dms_db -t users -t dexcom_tokens > backup_tables.sql
```

### Restore Database

```bash
psql -U postgres -d dms_db < backup.sql
```

## Token Encryption

All Dexcom OAuth tokens are encrypted before storage using Fernet symmetric encryption:

- **Access tokens** are encrypted for security
- **Refresh tokens** are encrypted (single-use, rotated on refresh)
- Encryption key must be kept secure and backed up
- **Never commit the encryption key to version control**

### Key Rotation

If you need to rotate the encryption key:

1. Generate a new key
2. Decrypt all tokens with old key
3. Re-encrypt with new key
4. Update `ENCRYPTION_KEY` in environment

⚠️ **Important:** Losing the encryption key means losing access to all stored tokens. Users will need to re-authorize.

## Testing Database Connection

```python
from app.database import SessionLocal

# Test connection
db = SessionLocal()
try:
    db.execute("SELECT 1")
    print("Database connection successful!")
finally:
    db.close()
```

## Troubleshooting

### Connection Issues

```bash
# Check PostgreSQL is running
sudo systemctl status postgresql

# Test connection
psql -U postgres -d dms_db -c "SELECT 1"
```

### Migration Conflicts

```bash
# View migration history
alembic history

# Stamp database to specific version
alembic stamp head
```

### Clear Alembic Cache

```bash
# Remove alembic version table
psql -U postgres -d dms_db -c "DROP TABLE alembic_version"

# Recreate with current state
alembic stamp head
```

## Production Considerations

1. **Use connection pooling** (already configured in `database.py`)
2. **Enable SSL** for database connections
3. **Regular backups** with automated schedule
4. **Monitor connection pool** usage
5. **Use read replicas** for scaling
6. **Implement proper indexes** on frequently queried columns
7. **Rotate encryption keys** periodically
8. **Use managed database service** (Supabase, RDS, etc.) for high availability

## Security Best Practices

- ✅ Never commit `.env` file
- ✅ Use strong database passwords
- ✅ Enable SSL for database connections
- ✅ Restrict database access by IP
- ✅ Backup encryption keys securely
- ✅ Use separate databases for development/staging/production
- ✅ Monitor failed login attempts
- ✅ Regular security audits

## Additional Resources

- [SQLAlchemy Documentation](https://docs.sqlalchemy.org/)
- [Alembic Documentation](https://alembic.sqlalchemy.org/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Supabase Documentation](https://supabase.com/docs)
