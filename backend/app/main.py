"""
Main FastAPI application for DMS Backend
"""
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from contextlib import asynccontextmanager
import logging

from app.config import get_settings
from app.routers import health, dexcom
from app.services.dexcom_api import DexcomAPIError, RateLimitError
from app.database import init_db

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Lifespan context manager for startup and shutdown events
    """
    # Startup
    settings = get_settings()
    logger.info(f"Starting {settings.APP_NAME} v{settings.APP_VERSION}")
    logger.info(f"Dexcom environment: {settings.DEXCOM_ENVIRONMENT}")
    logger.info(f"Dexcom base URL: {settings.get_dexcom_base_url()}")

    # Initialize database tables
    if settings.DATABASE_URL:
        try:
            logger.info("Initializing database...")
            init_db()
            logger.info("Database initialized successfully")
        except Exception as e:
            logger.error(f"Failed to initialize database: {e}")
            logger.warning("Application will continue without database functionality")
    else:
        logger.warning("DATABASE_URL not configured. Database functionality disabled.")

    yield

    # Shutdown
    logger.info("Shutting down DMS Backend API")


# Create FastAPI app
app = FastAPI(
    title="DMS Backend API",
    description="Backend for Diabetes Management System with Dexcom API integration",
    version="1.0.0",
    lifespan=lifespan,
)

# Get settings
settings = get_settings()

# Configure CORS
# For testing: allow all origins. In production, use settings.CORS_ORIGINS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins for testing
    allow_credentials=False,  # Must be False when using wildcard origins
    allow_methods=["*"],
    allow_headers=["*"],
)


# Exception handlers
@app.exception_handler(DexcomAPIError)
async def dexcom_api_error_handler(request: Request, exc: DexcomAPIError):
    """Handle Dexcom API errors"""
    logger.error(f"Dexcom API error: {exc.message} (status: {exc.status_code})")
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": "Dexcom API Error",
            "message": exc.message,
            "details": exc.details,
        },
    )


@app.exception_handler(RateLimitError)
async def rate_limit_error_handler(request: Request, exc: RateLimitError):
    """Handle rate limit errors"""
    logger.warning("Rate limit exceeded")
    return JSONResponse(
        status_code=429,
        content={
            "error": "Rate Limit Exceeded",
            "message": "Too many requests. Maximum 60,000 requests per hour allowed.",
        },
    )


# Include routers
app.include_router(health.router)
app.include_router(dexcom.router)


# Request logging middleware
@app.middleware("http")
async def log_requests(request: Request, call_next):
    """Log all incoming requests"""
    logger.info(f"{request.method} {request.url.path}")
    response = await call_next(request)
    logger.info(f"Response status: {response.status_code}")
    return response


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info",
    )
