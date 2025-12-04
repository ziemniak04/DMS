"""
Health check endpoint
"""
from fastapi import APIRouter
from datetime import datetime

router = APIRouter(tags=["health"])


@router.get("/health")
async def health_check():
    """
    Health check endpoint

    Returns:
        Status and timestamp
    """
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "service": "DMS Backend API",
    }


@router.get("/")
async def root():
    """
    Root endpoint

    Returns:
        Welcome message and API information
    """
    return {
        "message": "DMS Backend API",
        "version": "1.0.0",
        "docs": "/docs",
        "health": "/health",
    }
