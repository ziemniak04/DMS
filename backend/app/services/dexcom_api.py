"""
Dexcom API Service
Handles all interactions with the Dexcom API v3
"""
import httpx
from typing import Optional, Dict, Any
from datetime import datetime, timedelta
from app.config import Settings
from app.models.dexcom import (
    EGVResponse,
    CalibrationResponse,
    DataRangeResponse,
    DeviceResponse,
    EventResponse,
    AlertResponse,
    OAuthToken,
)


class DexcomAPIError(Exception):
    """Custom exception for Dexcom API errors"""

    def __init__(self, status_code: int, message: str, details: Optional[str] = None):
        self.status_code = status_code
        self.message = message
        self.details = details
        super().__init__(f"Dexcom API Error {status_code}: {message}")


class RateLimitError(DexcomAPIError):
    """Exception raised when rate limit is exceeded"""

    def __init__(self):
        super().__init__(429, "Rate limit exceeded. Max 60,000 requests per hour.")


class DexcomAPIClient:
    """
    Client for interacting with Dexcom API v3
    Supports all 6 endpoints: alerts, calibrations, dataRange, devices, egvs, events
    """

    def __init__(self, settings: Settings):
        self.settings = settings
        self.base_url = settings.get_dexcom_base_url()
        self.auth_base_url = settings.DEXCOM_AUTH_BASE_URL
        self.client_id = settings.DEXCOM_CLIENT_ID
        self.client_secret = settings.DEXCOM_CLIENT_SECRET
        self.redirect_uri = settings.DEXCOM_REDIRECT_URI

        # HTTP client with TLS 1.3 requirement
        self.http_client = httpx.AsyncClient(
            timeout=30.0,
            verify=True,
            http2=True,
        )

    async def close(self):
        """Close the HTTP client"""
        await self.http_client.aclose()

    def get_authorization_url(self, state: Optional[str] = None) -> str:
        """
        Generate the OAuth authorization URL

        Args:
            state: Optional state parameter for CSRF protection

        Returns:
            Authorization URL for user to grant access
        """
        params = {
            "client_id": self.client_id,
            "redirect_uri": self.redirect_uri,
            "response_type": "code",
            "scope": "offline_access",  # Required for refresh token
        }
        if state:
            params["state"] = state

        query_string = "&".join([f"{k}={v}" for k, v in params.items()])
        return f"{self.auth_base_url}{self.settings.DEXCOM_AUTHORIZE_ENDPOINT}?{query_string}"

    async def exchange_code_for_token(self, code: str) -> OAuthToken:
        """
        Exchange authorization code for access token and refresh token

        Args:
            code: Authorization code from OAuth callback

        Returns:
            OAuthToken containing access_token and refresh_token
        """
        url = f"{self.auth_base_url}{self.settings.DEXCOM_TOKEN_ENDPOINT}"
        data = {
            "client_id": self.client_id,
            "client_secret": self.client_secret,
            "code": code,
            "grant_type": "authorization_code",
            "redirect_uri": self.redirect_uri,
        }

        response = await self.http_client.post(url, data=data)

        if response.status_code != 200:
            raise DexcomAPIError(
                response.status_code,
                "Failed to exchange code for token",
                response.text,
            )

        return OAuthToken(**response.json())

    async def refresh_access_token(self, refresh_token: str) -> OAuthToken:
        """
        Refresh the access token using refresh token

        Args:
            refresh_token: The refresh token

        Returns:
            New OAuthToken with updated access_token
        """
        url = f"{self.auth_base_url}{self.settings.DEXCOM_TOKEN_ENDPOINT}"
        data = {
            "client_id": self.client_id,
            "client_secret": self.client_secret,
            "refresh_token": refresh_token,
            "grant_type": "refresh_token",
        }

        response = await self.http_client.post(url, data=data)

        if response.status_code != 200:
            raise DexcomAPIError(
                response.status_code,
                "Failed to refresh access token",
                response.text,
            )

        return OAuthToken(**response.json())

    async def _make_request(
        self,
        endpoint: str,
        access_token: str,
        params: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """
        Make an authenticated request to the Dexcom API

        Args:
            endpoint: API endpoint path (e.g., '/v3/users/self/egvs')
            access_token: OAuth access token
            params: Query parameters

        Returns:
            JSON response from API

        Raises:
            RateLimitError: If rate limit is exceeded
            DexcomAPIError: For other API errors
        """
        url = f"{self.base_url}{endpoint}"
        headers = {
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json",
        }

        response = await self.http_client.get(url, headers=headers, params=params)

        if response.status_code == 429:
            raise RateLimitError()
        elif response.status_code == 401:
            raise DexcomAPIError(401, "Unauthorized - token may be expired")
        elif response.status_code == 400:
            raise DexcomAPIError(400, "Bad Request", response.text)
        elif response.status_code == 404:
            raise DexcomAPIError(404, "Endpoint not found")
        elif response.status_code == 500:
            raise DexcomAPIError(500, "Internal Server Error")
        elif response.status_code != 200:
            raise DexcomAPIError(
                response.status_code,
                f"API request failed",
                response.text,
            )

        return response.json()

    def _validate_time_range(self, start_date: datetime, end_date: datetime):
        """
        Validate that time range is within 30 days

        Args:
            start_date: Start datetime
            end_date: End datetime

        Raises:
            ValueError: If time range exceeds 30 days
        """
        if (end_date - start_date) > timedelta(days=30):
            raise ValueError("Time range cannot exceed 30 days")

    async def get_egvs(
        self,
        access_token: str,
        start_date: datetime,
        end_date: datetime,
    ) -> EGVResponse:
        """
        Get Estimated Glucose Values (EGVs)

        Args:
            access_token: OAuth access token
            start_date: Start time (UTC, inclusive)
            end_date: End time (UTC, exclusive)

        Returns:
            EGVResponse containing glucose readings
        """
        self._validate_time_range(start_date, end_date)

        params = {
            "startDate": start_date.isoformat(),
            "endDate": end_date.isoformat(),
        }

        data = await self._make_request("/v3/users/self/egvs", access_token, params)
        return EGVResponse(**data)

    async def get_calibrations(
        self,
        access_token: str,
        start_date: datetime,
        end_date: datetime,
    ) -> CalibrationResponse:
        """
        Get calibration entries

        Args:
            access_token: OAuth access token
            start_date: Start time (UTC, inclusive)
            end_date: End time (UTC, exclusive)

        Returns:
            CalibrationResponse containing calibration data
        """
        self._validate_time_range(start_date, end_date)

        params = {
            "startDate": start_date.isoformat(),
            "endDate": end_date.isoformat(),
        }

        data = await self._make_request("/v3/users/self/calibrations", access_token, params)
        return CalibrationResponse(**data)

    async def get_data_range(self, access_token: str) -> DataRangeResponse:
        """
        Get available data range for user

        Args:
            access_token: OAuth access token

        Returns:
            DataRangeResponse containing earliest and latest data timestamps
        """
        data = await self._make_request("/v3/users/self/dataRange", access_token)
        return DataRangeResponse(**data)

    async def get_devices(self, access_token: str) -> DeviceResponse:
        """
        Get device information

        Args:
            access_token: OAuth access token

        Returns:
            DeviceResponse containing device details
        """
        data = await self._make_request("/v3/users/self/devices", access_token)
        return DeviceResponse(**data)

    async def get_events(
        self,
        access_token: str,
        start_date: datetime,
        end_date: datetime,
    ) -> EventResponse:
        """
        Get user-entered events (insulin, carbs, exercise, etc.)

        Args:
            access_token: OAuth access token
            start_date: Start time (UTC, inclusive)
            end_date: End time (UTC, exclusive)

        Returns:
            EventResponse containing user events
        """
        self._validate_time_range(start_date, end_date)

        params = {
            "startDate": start_date.isoformat(),
            "endDate": end_date.isoformat(),
        }

        data = await self._make_request("/v3/users/self/events", access_token, params)
        return EventResponse(**data)

    async def get_alerts(
        self,
        access_token: str,
        start_date: datetime,
        end_date: datetime,
    ) -> AlertResponse:
        """
        Get alerts

        Args:
            access_token: OAuth access token
            start_date: Start time (UTC, inclusive)
            end_date: End time (UTC, exclusive)

        Returns:
            AlertResponse containing alert data
        """
        self._validate_time_range(start_date, end_date)

        params = {
            "startDate": start_date.isoformat(),
            "endDate": end_date.isoformat(),
        }

        data = await self._make_request("/v3/users/self/alerts", access_token, params)
        return AlertResponse(**data)
