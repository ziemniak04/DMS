"""
Background Job Scheduler
Manages scheduled tasks like periodic Dexcom data scraping
Uses APScheduler for scheduling
"""
import logging
from typing import Dict, Callable
from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.interval import IntervalTrigger
from datetime import datetime, timedelta
from app.config import get_settings

logger = logging.getLogger(__name__)


class JobScheduler:
    """
    Manages background jobs for the DMS application.
    Handles periodic Dexcom data scraping and maintenance tasks.
    """

    _instance = None
    _scheduler = None

    def __new__(cls):
        """Singleton pattern"""
        if cls._instance is None:
            cls._instance = super(JobScheduler, cls).__new__(cls)
        return cls._instance

    def __init__(self):
        if self._scheduler is None:
            self._scheduler = BackgroundScheduler()
            self.settings = get_settings()
            self.jobs: Dict[str, str] = {}  # job_id -> job_name mapping

    def start(self):
        """Start the scheduler"""
        if not self._scheduler.running:
            self._scheduler.start()
            logger.info("Job Scheduler started")

    def stop(self):
        """Stop the scheduler"""
        if self._scheduler.running:
            self._scheduler.shutdown()
            logger.info("Job Scheduler stopped")

    def add_dexcom_scraper_job(self, func: Callable, minutes: int = 5) -> str:
        """
        Add a periodic Dexcom data scraping job

        Args:
            func: The scraper function to execute
            minutes: Interval in minutes between executions

        Returns:
            Job ID
        """
        try:
            job = self._scheduler.add_job(
                func,
                trigger=IntervalTrigger(minutes=minutes),
                id=f"dexcom_scraper_{minutes}min",
                name="Dexcom Data Scraper",
                replace_existing=True,
            )
            job_id = job.id
            self.jobs[job_id] = "Dexcom Data Scraper"
            logger.info(f"Added Dexcom scraper job: {job_id} (every {minutes} minutes)")
            return job_id
        except Exception as e:
            logger.error(f"Failed to add Dexcom scraper job: {e}")
            raise

    def add_user_scraper_job(self, user_id: str, func: Callable, minutes: int = 5) -> str:
        """
        Add a periodic Dexcom scraping job for a specific user

        Args:
            user_id: Firebase user ID
            func: The scraper function to execute
            minutes: Interval in minutes between executions

        Returns:
            Job ID
        """
        try:
            job_id = f"dexcom_scraper_user_{user_id}"
            job = self._scheduler.add_job(
                func,
                trigger=IntervalTrigger(minutes=minutes),
                id=job_id,
                name=f"Dexcom Scraper - User {user_id}",
                replace_existing=True,
            )
            self.jobs[job.id] = f"Dexcom Scraper - User {user_id}"
            logger.info(f"Added user scraper job for {user_id}: {job.id}")
            return job.id
        except Exception as e:
            logger.error(f"Failed to add user scraper job: {e}")
            raise

    def remove_user_scraper_job(self, user_id: str) -> bool:
        """
        Remove the scraper job for a specific user

        Args:
            user_id: Firebase user ID

        Returns:
            True if successful
        """
        try:
            job_id = f"dexcom_scraper_user_{user_id}"
            self._scheduler.remove_job(job_id)
            if job_id in self.jobs:
                del self.jobs[job_id]
            logger.info(f"Removed scraper job for user {user_id}")
            return True
        except Exception as e:
            logger.error(f"Failed to remove user scraper job: {e}")
            return False

    def add_cleanup_job(self, func: Callable, hours: int = 24) -> str:
        """
        Add a periodic cleanup job

        Args:
            func: The cleanup function to execute
            hours: Interval in hours between executions

        Returns:
            Job ID
        """
        try:
            job = self._scheduler.add_job(
                func,
                trigger=IntervalTrigger(hours=hours),
                id="data_cleanup_job",
                name="Data Cleanup",
                replace_existing=True,
            )
            self.jobs[job.id] = "Data Cleanup"
            logger.info(f"Added cleanup job: {job.id}")
            return job.id
        except Exception as e:
            logger.error(f"Failed to add cleanup job: {e}")
            raise

    def get_job(self, job_id: str):
        """Get a job by ID"""
        return self._scheduler.get_job(job_id)

    def get_all_jobs(self):
        """Get all scheduled jobs"""
        return self._scheduler.get_jobs()

    def list_jobs(self) -> Dict:
        """List all scheduled jobs with details"""
        jobs_list = []
        for job in self._scheduler.get_jobs():
            next_run = job.next_run_time
            jobs_list.append({
                "id": job.id,
                "name": job.name,
                "next_run": next_run.isoformat() if next_run else None,
                "trigger": str(job.trigger),
            })
        return {"jobs": jobs_list, "total": len(jobs_list)}


# Global scheduler instance
scheduler = JobScheduler()
