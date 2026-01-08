"""
Data Sync Endpoints
FastAPI endpoints for syncing Dexcom data with Firestore
"""
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks, Query, Request
from datetime import datetime, timedelta
from typing import Optional, List
from sqlalchemy.orm import Session
import logging

from app.database import get_db
from app.config import get_settings
from app.services.dexcom_scraper import DexcomScraper
from app.services.firestore_service import FirestoreService
from app.services.job_scheduler import scheduler
from app.services.token_storage import TokenStorageService

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/sync", tags=["sync"])


async def get_user_id(request: Request) -> str:
    """
    Get user ID from Firebase token or header

    TODO: Implement proper Firebase JWT validation
    Currently uses header-based authentication for testing
    """
    user_id = request.headers.get("X-User-ID")
    if not user_id:
        raise HTTPException(status_code=401, detail="Unauthorized - User ID required")
    return user_id


# ==================== Sync Endpoints ====================


@router.post("/manual")
async def manual_sync(
    background_tasks: BackgroundTasks,
    user_id: str = Depends(get_user_id),
    db: Session = Depends(get_db),
):
    """
    Manually trigger a data sync for the current user

    This endpoint:
    1. Validates that the user has an active Dexcom connection
    2. Scrapes data from Dexcom API
    3. Stores it in Firestore
    4. Runs in the background

    Returns:
        Status message and sync ID
    """
    try:
        # Verify user has Dexcom token
        token_service = TokenStorageService(db)
        token_data = token_service.get_token(user_id)

        if not token_data:
            raise HTTPException(
                status_code=400, detail="No Dexcom connection found. Please authenticate first."
            )

        # Queue background sync
        scraper = DexcomScraper()
        background_tasks.add_task(scraper.scrape_user_data, user_id)

        return {
            "status": "sync_started",
            "user_id": user_id,
            "message": "Data sync initiated. Check back in a few moments for results.",
            "timestamp": datetime.utcnow().isoformat(),
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error starting manual sync for user {user_id}: {e}")
        raise HTTPException(status_code=500, detail=f"Sync failed: {str(e)}")


@router.post("/auto-enable")
async def enable_auto_sync(
    interval_minutes: int = Query(5, ge=1, le=120),
    user_id: str = Depends(get_user_id),
    db: Session = Depends(get_db),
):
    """
    Enable automatic periodic syncing for a user

    Args:
        interval_minutes: Minutes between syncs (1-120, default 5)
        user_id: Firebase user ID

    Returns:
        Job information
    """
    try:
        # Verify user has Dexcom token
        token_service = TokenStorageService(db)
        token_data = token_service.get_token(user_id)

        if not token_data:
            raise HTTPException(
                status_code=400, detail="No Dexcom connection found. Please authenticate first."
            )

        # Create scraper job for this user
        scraper = DexcomScraper()

        async def user_scrape_task():
            await scraper.scrape_user_data(user_id)

        job_id = scheduler.add_user_scraper_job(user_id, user_scrape_task, interval_minutes)

        # Make sure scheduler is running
        scheduler.start()

        return {
            "status": "auto_sync_enabled",
            "user_id": user_id,
            "job_id": job_id,
            "interval_minutes": interval_minutes,
            "message": f"Auto sync enabled every {interval_minutes} minutes",
            "timestamp": datetime.utcnow().isoformat(),
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error enabling auto sync for user {user_id}: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to enable auto sync: {str(e)}")


@router.post("/auto-disable")
async def disable_auto_sync(
    user_id: str = Depends(get_user_id),
):
    """
    Disable automatic periodic syncing for a user

    Args:
        user_id: Firebase user ID

    Returns:
        Status message
    """
    try:
        success = scheduler.remove_user_scraper_job(user_id)

        if success:
            return {
                "status": "auto_sync_disabled",
                "user_id": user_id,
                "message": "Auto sync disabled",
                "timestamp": datetime.utcnow().isoformat(),
            }
        else:
            raise HTTPException(status_code=404, detail="No active sync job found for user")

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error disabling auto sync for user {user_id}: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to disable auto sync: {str(e)}")


@router.get("/status")
async def get_sync_status(
    user_id: str = Depends(get_user_id),
):
    """
    Get sync status for a user

    Returns:
        Sync status, last sync time, and connection info
    """
    try:
        firestore_service = FirestoreService()
        metadata = await firestore_service.get_dexcom_token_metadata(user_id)

        if not metadata:
            return {
                "status": "not_connected",
                "user_id": user_id,
                "message": "No Dexcom connection",
            }

        # Check if user has an active sync job
        jobs = scheduler.get_all_jobs()
        active_job = None
        for job in jobs:
            if user_id in job.id:
                active_job = {
                    "job_id": job.id,
                    "next_run": job.next_run_time.isoformat() if job.next_run_time else None,
                }
                break

        return {
            "status": metadata.get("syncStatus", "unknown"),
            "user_id": user_id,
            "lastSyncTime": metadata.get("lastSyncTime"),
            "statusMessage": metadata.get("statusMessage"),
            "activeSyncJob": active_job,
            "timestamp": datetime.utcnow().isoformat(),
        }

    except Exception as e:
        logger.error(f"Error getting sync status for user {user_id}: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get sync status: {str(e)}")


# ==================== Data Retrieval Endpoints ====================


@router.get("/readings")
async def get_glucose_readings(
    days: int = Query(7, ge=1, le=90),
    limit: int = Query(100, ge=1, le=1000),
    user_id: str = Depends(get_user_id),
):
    """
    Get glucose readings for a user

    Args:
        days: Number of days to retrieve (1-90, default 7)
        limit: Maximum readings to return (1-1000, default 100)

    Returns:
        List of glucose readings
    """
    try:
        firestore_service = FirestoreService()
        readings = await firestore_service.get_glucose_readings(user_id, days, limit)

        return {
            "user_id": user_id,
            "count": len(readings),
            "readings": readings,
            "timestamp": datetime.utcnow().isoformat(),
        }

    except Exception as e:
        logger.error(f"Error getting readings for user {user_id}: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get readings: {str(e)}")


@router.get("/latest-reading")
async def get_latest_reading(
    user_id: str = Depends(get_user_id),
):
    """
    Get the latest glucose reading for a user

    Returns:
        Latest glucose reading or null if none exist
    """
    try:
        firestore_service = FirestoreService()
        reading = await firestore_service.get_latest_glucose(user_id)

        return {
            "user_id": user_id,
            "reading": reading,
            "timestamp": datetime.utcnow().isoformat(),
        }

    except Exception as e:
        logger.error(f"Error getting latest reading for user {user_id}: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get reading: {str(e)}")


@router.get("/events")
async def get_events(
    days: int = Query(7, ge=1, le=90),
    event_type: Optional[str] = Query(None, description="Filter by event type"),
    user_id: str = Depends(get_user_id),
):
    """
    Get events for a user

    Args:
        days: Number of days to retrieve
        event_type: Optional filter by event type (meal, insulin, activity, note)

    Returns:
        List of events
    """
    try:
        firestore_service = FirestoreService()
        events = await firestore_service.get_events(user_id, days, event_type)

        return {
            "user_id": user_id,
            "count": len(events),
            "eventType": event_type,
            "events": events,
            "timestamp": datetime.utcnow().isoformat(),
        }

    except Exception as e:
        logger.error(f"Error getting events for user {user_id}: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get events: {str(e)}")


@router.get("/daily-stats")
async def get_daily_stats(
    year: int = Query(None),
    month: int = Query(None),
    user_id: str = Depends(get_user_id),
):
    """
    Get daily statistics for a user

    Args:
        year: Year (optional, defaults to current)
        month: Month (optional, defaults to current)

    Returns:
        Daily statistics
    """
    try:
        if not year:
            year = datetime.utcnow().year
        if not month:
            month = datetime.utcnow().month

        firestore_service = FirestoreService()
        stats = await firestore_service.get_monthly_stats(user_id, year, month)

        return {
            "user_id": user_id,
            "year": year,
            "month": month,
            "count": len(stats),
            "stats": stats,
            "timestamp": datetime.utcnow().isoformat(),
        }

    except Exception as e:
        logger.error(f"Error getting daily stats for user {user_id}: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get stats: {str(e)}")


# ==================== Admin Endpoints ====================


@router.post("/admin/sync-all")
async def admin_sync_all(
    background_tasks: BackgroundTasks,
    settings: Settings = Depends(get_settings),
):
    """
    Admin endpoint to manually trigger sync for all users

    Requires proper authorization (not implemented yet)

    Returns:
        Job information
    """
    try:
        # TODO: Add proper authorization check (admin role)

        scraper = DexcomScraper()
        background_tasks.add_task(scraper.scrape_all_users)

        return {
            "status": "bulk_sync_started",
            "message": "Syncing data for all users",
            "timestamp": datetime.utcnow().isoformat(),
        }

    except Exception as e:
        logger.error(f"Error starting bulk sync: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to start bulk sync: {str(e)}")


@router.get("/admin/jobs")
async def get_scheduled_jobs(
    settings: Settings = Depends(get_settings),
):
    """
    Admin endpoint to view all scheduled jobs

    Requires proper authorization (not implemented yet)

    Returns:
        List of scheduled jobs
    """
    try:
        # TODO: Add proper authorization check (admin role)

        jobs_info = scheduler.list_jobs()

        return {
            "jobs": jobs_info["jobs"],
            "total": jobs_info["total"],
            "timestamp": datetime.utcnow().isoformat(),
        }

    except Exception as e:
        logger.error(f"Error getting scheduled jobs: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get jobs: {str(e)}")
