"""
Dexcom Data Scraper Task
Background job for periodically scraping Dexcom data and storing to Firestore
"""
import asyncio
import logging
from datetime import datetime, timedelta
from typing import Optional
from app.services.dexcom_api import DexcomAPIClient
from app.services.firestore_service import FirestoreService
from app.services.token_storage import TokenStorageService
from app.config import get_settings
from sqlalchemy.orm import Session
from app.database import SessionLocal

logger = logging.getLogger(__name__)


class DexcomScraper:
    """
    Handles scraping glucose data from Dexcom API and storing to Firestore.
    Implements error handling, rate limiting, and retry logic.
    """

    def __init__(self):
        self.settings = get_settings()
        self.firestore_service = FirestoreService()
        self.db = SessionLocal()

    async def scrape_user_data(self, user_id: str) -> bool:
        """
        Scrape and store glucose data for a single user

        Args:
            user_id: Firebase user ID

        Returns:
            True if successful, False otherwise
        """
        try:
            logger.info(f"Starting data scrape for user {user_id}")

            # Get token from database
            token_service = TokenStorageService(self.db)
            token_data = token_service.get_token(user_id)

            if not token_data:
                logger.warning(f"No Dexcom token found for user {user_id}")
                await self.firestore_service.update_sync_status(
                    user_id, "error", "No authentication token found"
                )
                return False

            # Initialize Dexcom client
            client = DexcomAPIClient(self.settings)

            try:
                # Fetch latest glucose readings (last 24 hours)
                egvs = await client.get_egvs(
                    access_token=token_data.access_token,
                    minutes=1440,  # 24 hours
                )

                # Store each reading in Firestore
                stored_count = 0
                for egv in egvs:
                    try:
                        await self.firestore_service.store_glucose_reading(user_id, egv)
                        stored_count += 1
                    except Exception as e:
                        logger.error(f"Failed to store reading for user {user_id}: {e}")
                        continue

                logger.info(f"Stored {stored_count} glucose readings for user {user_id}")

                # Fetch events (meals, insulin, etc.) if available
                await self._scrape_events(user_id, token_data.access_token, client)

                # Calculate and store daily statistics
                await self._calculate_daily_stats(user_id)

                # Update sync status
                await self.firestore_service.update_sync_status(user_id, "active")

                logger.info(f"Successfully completed scrape for user {user_id}")
                return True

            finally:
                await client.close()

        except Exception as e:
            logger.error(f"Error scraping data for user {user_id}: {e}")
            try:
                await self.firestore_service.update_sync_status(
                    user_id, "error", str(e)
                )
            except:
                pass
            return False

    async def _scrape_events(self, user_id: str, access_token: str, client: DexcomAPIClient):
        """
        Scrape events (meals, insulin, activity) from Dexcom API

        Args:
            user_id: Firebase user ID
            access_token: Dexcom access token
            client: Initialized Dexcom API client
        """
        try:
            # Fetch events from last 30 days
            events_response = await client.get_events(
                access_token=access_token,
                minutes=43200,  # 30 days
            )

            if not events_response:
                logger.info(f"No events found for user {user_id}")
                return

            stored_count = 0
            for event in events_response:
                try:
                    event_type = event.get("eventType", "unknown").lower()
                    await self.firestore_service.store_event(user_id, event_type, event)
                    stored_count += 1
                except Exception as e:
                    logger.error(f"Failed to store event for user {user_id}: {e}")
                    continue

            logger.info(f"Stored {stored_count} events for user {user_id}")

        except Exception as e:
            logger.error(f"Failed to scrape events for user {user_id}: {e}")

    async def _calculate_daily_stats(self, user_id: str):
        """
        Calculate and store daily statistics for a user

        Args:
            user_id: Firebase user ID
        """
        try:
            # Get today's readings
            readings = await self.firestore_service.get_glucose_readings(
                user_id, days=1, limit=500
            )

            if not readings:
                logger.debug(f"No readings for stats calculation for user {user_id}")
                return

            values = [r["value"] for r in readings if "value" in r and r["value"]]
            if not values:
                return

            # Calculate statistics
            average = sum(values) / len(values)
            min_value = min(values)
            max_value = max(values)

            # Calculate time in range (assuming 80-180 mg/dL is target range)
            target_min = self.settings.GLUCOSE_TARGET_MIN or 80
            target_max = self.settings.GLUCOSE_TARGET_MAX or 180

            in_range = sum(1 for v in values if target_min <= v <= target_max)
            time_in_range = (in_range / len(values)) * 100 if values else 0

            high_count = sum(1 for v in values if v > target_max)
            time_high = (high_count / len(values)) * 100 if values else 0

            low_count = sum(1 for v in values if v < target_min)
            time_low = (low_count / len(values)) * 100 if values else 0

            stats_data = {
                "date": datetime.utcnow().date().isoformat(),
                "average": round(average, 1),
                "min": min_value,
                "max": max_value,
                "timeInRange": round(time_in_range, 1),
                "timeHigh": round(time_high, 1),
                "timeLow": round(time_low, 1),
                "readingCount": len(values),
            }

            await self.firestore_service.store_daily_stats(user_id, stats_data)
            logger.info(f"Stored daily stats for user {user_id}")

        except Exception as e:
            logger.error(f"Failed to calculate daily stats for user {user_id}: {e}")

    async def scrape_all_users(self) -> dict:
        """
        Scrape data for all users with active Dexcom connections

        Returns:
            Dictionary with scrape results
        """
        try:
            logger.info("Starting full data scrape for all users")

            # Get all users with Dexcom tokens from Firestore
            firestore_db = self.firestore_service.db
            dexcom_tokens = firestore_db.collection("dexcom_tokens").stream()

            results = {"total": 0, "successful": 0, "failed": 0, "users": []}

            for doc in dexcom_tokens:
                user_id = doc.id
                results["total"] += 1

                success = await self.scrape_user_data(user_id)
                if success:
                    results["successful"] += 1
                    results["users"].append({"user_id": user_id, "status": "success"})
                else:
                    results["failed"] += 1
                    results["users"].append({"user_id": user_id, "status": "failed"})

                # Add a small delay to avoid overwhelming the Dexcom API
                await asyncio.sleep(1)

            logger.info(
                f"Completed full scrape: {results['successful']}/{results['total']} successful"
            )
            return results

        except Exception as e:
            logger.error(f"Error in full scrape: {e}")
            return {"error": str(e)}

    def close(self):
        """Close database connection"""
        self.db.close()


# Background task runner
async def run_scraper_job(interval_seconds: int = 300):
    """
    Run the Dexcom scraper periodically

    Args:
        interval_seconds: Interval between scrapes (default: 5 minutes)
    """
    scraper = DexcomScraper()

    while True:
        try:
            await scraper.scrape_all_users()
        except Exception as e:
            logger.error(f"Scraper job error: {e}")
        finally:
            # Wait before next scrape
            await asyncio.sleep(interval_seconds)


async def run_user_scraper_job(user_id: str, interval_seconds: int = 300):
    """
    Run the Dexcom scraper for a specific user periodically

    Args:
        user_id: Firebase user ID
        interval_seconds: Interval between scrapes (default: 5 minutes)
    """
    scraper = DexcomScraper()

    while True:
        try:
            await scraper.scrape_user_data(user_id)
        except Exception as e:
            logger.error(f"Scraper job error for user {user_id}: {e}")
        finally:
            # Wait before next scrape
            await asyncio.sleep(interval_seconds)
