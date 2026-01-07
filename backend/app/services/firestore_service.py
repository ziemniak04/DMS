"""
Firestore Service
Handles all interactions with Firestore for storing glucose data and events
"""
import firebase_admin
from firebase_admin import credentials, firestore
from typing import Optional, List, Dict, Any
from datetime import datetime, timedelta
from app.config import get_settings
import logging

logger = logging.getLogger(__name__)


class FirestoreService:
    """
    Service for interacting with Firestore database.
    Stores glucose readings, events, and user metadata.
    """

    _instance = None
    _db = None

    def __new__(cls):
        """Singleton pattern to ensure one Firestore connection"""
        if cls._instance is None:
            cls._instance = super(FirestoreService, cls).__new__(cls)
        return cls._instance

    @classmethod
    def initialize(cls, credentials_path: Optional[str] = None):
        """
        Initialize Firebase Admin SDK and Firestore connection

        Args:
            credentials_path: Path to Firebase service account JSON file
                             If None, will use GOOGLE_APPLICATION_CREDENTIALS env var
        """
        if cls._db is None:
            try:
                # Initialize Firebase Admin SDK
                if credentials_path:
                    cred = credentials.Certificate(credentials_path)
                    firebase_admin.initialize_app(cred)
                else:
                    # Uses GOOGLE_APPLICATION_CREDENTIALS environment variable
                    firebase_admin.initialize_app()

                cls._db = firestore.client()
                logger.info("Firestore initialized successfully")
            except Exception as e:
                logger.error(f"Failed to initialize Firestore: {e}")
                raise

    @property
    def db(self):
        """Get Firestore database instance"""
        if self._db is None:
            self.initialize()
        return self._db

    # ==================== Glucose Readings ====================

    async def store_glucose_reading(
        self, user_id: str, egv_data: Dict[str, Any]
    ) -> str:
        """
        Store a glucose reading in Firestore

        Args:
            user_id: Firebase user ID
            egv_data: EGV data from Dexcom API

        Returns:
            Document ID of the stored reading
        """
        try:
            reading_doc = {
                "userId": user_id,
                "value": egv_data.get("value"),
                "unit": egv_data.get("unit", "mg/dL"),
                "trend": egv_data.get("trend"),
                "trendRate": egv_data.get("trendRate"),
                "displayTime": egv_data.get("displayTime"),
                "systemTime": egv_data.get("systemTime"),
                "realtimeValue": egv_data.get("realtimeValue"),
                "realtimeTrend": egv_data.get("realtimeTrend"),
                "timestamp": datetime.utcnow(),
                "dexcomId": egv_data.get("id"),
            }

            # Store in subcollection: users/{userId}/readings/{timestamp}
            doc_ref = self.db.collection("users").document(user_id).collection(
                "readings"
            ).document()
            doc_ref.set(reading_doc)
            logger.info(f"Stored glucose reading for user {user_id}: {egv_data.get('value')}")
            return doc_ref.id

        except Exception as e:
            logger.error(f"Failed to store glucose reading: {e}")
            raise

    async def get_glucose_readings(
        self, user_id: str, days: int = 7, limit: int = 100
    ) -> List[Dict[str, Any]]:
        """
        Get glucose readings for a user

        Args:
            user_id: Firebase user ID
            days: Number of days to retrieve
            limit: Maximum number of readings

        Returns:
            List of glucose readings
        """
        try:
            start_date = datetime.utcnow() - timedelta(days=days)

            readings = (
                self.db.collection("users")
                .document(user_id)
                .collection("readings")
                .where("timestamp", ">=", start_date)
                .order_by("timestamp", direction=firestore.Query.DESCENDING)
                .limit(limit)
                .stream()
            )

            data = []
            for doc in readings:
                reading = doc.to_dict()
                reading["id"] = doc.id
                data.append(reading)

            return data
        except Exception as e:
            logger.error(f"Failed to get glucose readings: {e}")
            raise

    async def get_latest_glucose(self, user_id: str) -> Optional[Dict[str, Any]]:
        """
        Get the latest glucose reading for a user

        Args:
            user_id: Firebase user ID

        Returns:
            Latest glucose reading or None
        """
        try:
            readings = (
                self.db.collection("users")
                .document(user_id)
                .collection("readings")
                .order_by("timestamp", direction=firestore.Query.DESCENDING)
                .limit(1)
                .stream()
            )

            for doc in readings:
                reading = doc.to_dict()
                reading["id"] = doc.id
                return reading

            return None
        except Exception as e:
            logger.error(f"Failed to get latest glucose reading: {e}")
            raise

    # ==================== Events (Meals, Insulin, Activity) ====================

    async def store_event(
        self, user_id: str, event_type: str, event_data: Dict[str, Any]
    ) -> str:
        """
        Store a diabetes event (meal, insulin, activity, note)

        Args:
            user_id: Firebase user ID
            event_type: Type of event (meal, insulin, activity, note)
            event_data: Event details

        Returns:
            Document ID of the stored event
        """
        try:
            event_doc = {
                "userId": user_id,
                "type": event_type,
                "timestamp": event_data.get("timestamp", datetime.utcnow()),
                "createdAt": datetime.utcnow(),
                "data": event_data,
            }

            # Store in subcollection: users/{userId}/events/{timestamp}
            doc_ref = self.db.collection("users").document(user_id).collection(
                "events"
            ).document()
            doc_ref.set(event_doc)
            logger.info(f"Stored event for user {user_id}: {event_type}")
            return doc_ref.id

        except Exception as e:
            logger.error(f"Failed to store event: {e}")
            raise

    async def get_events(
        self, user_id: str, days: int = 7, event_type: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        Get events for a user

        Args:
            user_id: Firebase user ID
            days: Number of days to retrieve
            event_type: Filter by event type (optional)

        Returns:
            List of events
        """
        try:
            start_date = datetime.utcnow() - timedelta(days=days)

            query = (
                self.db.collection("users")
                .document(user_id)
                .collection("events")
                .where("timestamp", ">=", start_date)
            )

            if event_type:
                query = query.where("type", "==", event_type)

            events = query.order_by(
                "timestamp", direction=firestore.Query.DESCENDING
            ).stream()

            data = []
            for doc in events:
                event = doc.to_dict()
                event["id"] = doc.id
                data.append(event)

            return data
        except Exception as e:
            logger.error(f"Failed to get events: {e}")
            raise

    # ==================== Dexcom Integration Metadata ====================

    async def store_dexcom_token(self, user_id: str, token_data: Dict[str, Any]):
        """
        Store Dexcom OAuth token metadata

        Args:
            user_id: Firebase user ID
            token_data: Token information
        """
        try:
            token_doc = {
                "userId": user_id,
                "dexcomAccountId": token_data.get("accountId"),
                "lastSyncTime": datetime.utcnow(),
                "syncStatus": "active",
                "expiresAt": token_data.get("expiresAt"),
                "updatedAt": datetime.utcnow(),
            }

            self.db.collection("dexcom_tokens").document(user_id).set(token_doc)
            logger.info(f"Stored Dexcom token for user {user_id}")

        except Exception as e:
            logger.error(f"Failed to store Dexcom token: {e}")
            raise

    async def get_dexcom_token_metadata(self, user_id: str) -> Optional[Dict]:
        """Get Dexcom token metadata for a user"""
        try:
            doc = self.db.collection("dexcom_tokens").document(user_id).get()
            if doc.exists:
                return doc.to_dict()
            return None
        except Exception as e:
            logger.error(f"Failed to get Dexcom token metadata: {e}")
            raise

    async def update_sync_status(
        self, user_id: str, status: str, message: Optional[str] = None
    ):
        """
        Update the sync status for a user

        Args:
            user_id: Firebase user ID
            status: Sync status (active, paused, error)
            message: Optional status message
        """
        try:
            update_data = {
                "syncStatus": status,
                "lastStatusUpdate": datetime.utcnow(),
            }
            if message:
                update_data["statusMessage"] = message

            self.db.collection("dexcom_tokens").document(user_id).update(update_data)
            logger.info(f"Updated sync status for user {user_id}: {status}")

        except Exception as e:
            logger.error(f"Failed to update sync status: {e}")
            raise

    # ==================== Analytics and Statistics ====================

    async def store_daily_stats(self, user_id: str, stats_data: Dict[str, Any]):
        """
        Store daily statistics for a user (average, min, max, time in range, etc.)

        Args:
            user_id: Firebase user ID
            stats_data: Daily statistics
        """
        try:
            date_str = stats_data.get("date", datetime.utcnow().date().isoformat())

            stats_doc = {
                "userId": user_id,
                "date": date_str,
                "average": stats_data.get("average"),
                "min": stats_data.get("min"),
                "max": stats_data.get("max"),
                "timeInRange": stats_data.get("timeInRange"),  # percentage
                "timeHigh": stats_data.get("timeHigh"),  # percentage
                "timeLow": stats_data.get("timeLow"),  # percentage
                "readingCount": stats_data.get("readingCount"),
                "calculatedAt": datetime.utcnow(),
            }

            self.db.collection("users").document(user_id).collection("daily_stats").document(
                date_str
            ).set(stats_doc)
            logger.info(f"Stored daily stats for user {user_id} on {date_str}")

        except Exception as e:
            logger.error(f"Failed to store daily stats: {e}")
            raise

    async def get_monthly_stats(
        self, user_id: str, year: int, month: int
    ) -> List[Dict[str, Any]]:
        """Get daily stats for a month"""
        try:
            stats = (
                self.db.collection("users")
                .document(user_id)
                .collection("daily_stats")
                .stream()
            )

            data = []
            for doc in stats:
                stat = doc.to_dict()
                stat["id"] = doc.id
                data.append(stat)

            return data
        except Exception as e:
            logger.error(f"Failed to get monthly stats: {e}")
            raise
