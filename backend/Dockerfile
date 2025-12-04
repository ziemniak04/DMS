# Multi-stage Dockerfile for DMS Backend API
# Stage 1: Builder
FROM python:3.11-slim as builder

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir --user -r requirements.txt

# Stage 2: Runtime
FROM python:3.11-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Create non-root user
RUN useradd -m -u 1000 dms && \
    mkdir -p /app && \
    chown -R dms:dms /app

# Set working directory
WORKDIR /app

# Copy Python dependencies from builder to dms user's home
COPY --from=builder --chown=dms:dms /root/.local /home/dms/.local

# Update PATH for dms user
ENV PATH=/home/dms/.local/bin:$PATH

# Copy application code
COPY --chown=dms:dms app/ ./app/

# Switch to non-root user
USER dms

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

# Run the application
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
