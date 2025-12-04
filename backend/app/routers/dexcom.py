"""
Dexcom API endpoints
Exposes all 6 Dexcom API endpoints to the Flutter frontend
"""
from fastapi import APIRouter, Depends, HTTPException, Query, Request
from datetime import datetime
from typing import Optional
from app.services.dexcom_api import DexcomAPIClient, DexcomAPIError, RateLimitError
from app.models.dexcom import (
    EGVResponse,
    CalibrationResponse,
    DataRangeResponse,
    DeviceResponse,
    EventResponse,
    AlertResponse,
)
from app.config import Settings, get_settings

router = APIRouter(prefix="/dexcom", tags=["dexcom"])


def get_dexcom_client(settings: Settings = Depends(get_settings)) -> DexcomAPIClient:
    """Dependency to get Dexcom API client"""
    return DexcomAPIClient(settings)


async def get_access_token(request: Request) -> str:
    """
    Extract and validate access token from request
    TODO: Implement proper token storage and retrieval from database
    For now, expects token in Authorization header
    """
    auth_header = request.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing or invalid authorization header")

    # Extract the Dexcom access token
    # In production, this should be retrieved from encrypted database storage
    token = auth_header.replace("Bearer ", "")
    return token


@router.get("/auth/url")
async def get_authorization_url(
    state: Optional[str] = Query(None, description="CSRF protection state parameter"),
    client: DexcomAPIClient = Depends(get_dexcom_client),
) -> dict:
    """
    Get the OAuth authorization URL for user to grant access

    Returns:
        Dictionary containing the authorization URL
    """
    url = client.get_authorization_url(state)
    return {"authorization_url": url}


@router.post("/auth/token")
async def exchange_code(
    code: str = Query(..., description="Authorization code from OAuth callback"),
    client: DexcomAPIClient = Depends(get_dexcom_client),
):
    """
    Exchange authorization code for access token and refresh token

    Args:
        code: Authorization code from Dexcom OAuth callback

    Returns:
        OAuth tokens (access_token and refresh_token)

    Note:
        The refresh_token should be stored encrypted in the database
        and associated with the user's account
    """
    try:
        token = await client.exchange_code_for_token(code)
        # TODO: Store encrypted refresh_token in database
        return token
    except DexcomAPIError as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)
    finally:
        await client.close()


@router.post("/auth/refresh")
async def refresh_token(
    refresh_token: str = Query(..., description="Refresh token"),
    client: DexcomAPIClient = Depends(get_dexcom_client),
):
    """
    Refresh the access token using refresh token

    Args:
        refresh_token: The refresh token (normally retrieved from encrypted database)

    Returns:
        New OAuth tokens
    """
    try:
        token = await client.refresh_access_token(refresh_token)
        # TODO: Update encrypted refresh_token in database
        return token
    except DexcomAPIError as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)
    finally:
        await client.close()


@router.get("/egvs", response_model=EGVResponse)
async def get_egvs(
    start_date: datetime = Query(..., description="Start date (UTC, inclusive)"),
    end_date: datetime = Query(..., description="End date (UTC, exclusive)"),
    access_token: str = Depends(get_access_token),
    client: DexcomAPIClient = Depends(get_dexcom_client),
):
    """
    Get Estimated Glucose Values (EGVs)

    Returns glucose readings for the specified time range.
    Maximum time range is 30 days.

    Args:
        start_date: Start time in ISO 8601 format (UTC, inclusive)
        end_date: End time in ISO 8601 format (UTC, exclusive)

    Returns:
        EGVResponse containing glucose readings

    Note:
        - Data has 1-hour delay in US, 3-hour delay outside US
        - Values are in mg/dL, trend rates in mg/dL/min
        - G7 sandbox data available with "SandboxUser7"
    """
    try:
        egvs = await client.get_egvs(access_token, start_date, end_date)
        return egvs
    except RateLimitError as e:
        raise HTTPException(status_code=429, detail=str(e))
    except DexcomAPIError as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        await client.close()


@router.get("/calibrations", response_model=CalibrationResponse)
async def get_calibrations(
    start_date: datetime = Query(..., description="Start date (UTC, inclusive)"),
    end_date: datetime = Query(..., description="End date (UTC, exclusive)"),
    access_token: str = Depends(get_access_token),
    client: DexcomAPIClient = Depends(get_dexcom_client),
):
    """
    Get calibration entries

    Returns calibration data entered by the user.
    Maximum time range is 30 days.

    Args:
        start_date: Start time in ISO 8601 format (UTC, inclusive)
        end_date: End time in ISO 8601 format (UTC, exclusive)

    Returns:
        CalibrationResponse containing calibration data
    """
    try:
        calibrations = await client.get_calibrations(access_token, start_date, end_date)
        return calibrations
    except RateLimitError as e:
        raise HTTPException(status_code=429, detail=str(e))
    except DexcomAPIError as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        await client.close()


@router.get("/data-range", response_model=DataRangeResponse)
async def get_data_range(
    access_token: str = Depends(get_access_token),
    client: DexcomAPIClient = Depends(get_dexcom_client),
):
    """
    Get available data range for user

    Returns the earliest and latest timestamps for which data is available.

    Returns:
        DataRangeResponse containing data range information
    """
    try:
        data_range = await client.get_data_range(access_token)
        return data_range
    except RateLimitError as e:
        raise HTTPException(status_code=429, detail=str(e))
    except DexcomAPIError as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)
    finally:
        await client.close()


@router.get("/devices", response_model=DeviceResponse)
async def get_devices(
    access_token: str = Depends(get_access_token),
    client: DexcomAPIClient = Depends(get_dexcom_client),
):
    """
    Get device information

    Returns information about Dexcom devices associated with the user.
    Supports G6, G7, Dexcom ONE, and Dexcom ONE+ devices.

    Returns:
        DeviceResponse containing device details
    """
    try:
        devices = await client.get_devices(access_token)
        return devices
    except RateLimitError as e:
        raise HTTPException(status_code=429, detail=str(e))
    except DexcomAPIError as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)
    finally:
        await client.close()


@router.get("/events", response_model=EventResponse)
async def get_events(
    start_date: datetime = Query(..., description="Start date (UTC, inclusive)"),
    end_date: datetime = Query(..., description="End date (UTC, exclusive)"),
    access_token: str = Depends(get_access_token),
    client: DexcomAPIClient = Depends(get_dexcom_client),
):
    """
    Get user-entered events

    Returns events such as insulin, carbs, exercise, health notes, etc.
    Maximum time range is 30 days.

    Args:
        start_date: Start time in ISO 8601 format (UTC, inclusive)
        end_date: End time in ISO 8601 format (UTC, exclusive)

    Returns:
        EventResponse containing user events
    """
    try:
        events = await client.get_events(access_token, start_date, end_date)
        return events
    except RateLimitError as e:
        raise HTTPException(status_code=429, detail=str(e))
    except DexcomAPIError as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        await client.close()


@router.get("/alerts", response_model=AlertResponse)
async def get_alerts(
    start_date: datetime = Query(..., description="Start date (UTC, inclusive)"),
    end_date: datetime = Query(..., description="End date (UTC, exclusive)"),
    access_token: str = Depends(get_access_token),
    client: DexcomAPIClient = Depends(get_dexcom_client),
):
    """
    Get alerts

    Returns alert data from the Dexcom device.
    Maximum time range is 30 days.

    Args:
        start_date: Start time in ISO 8601 format (UTC, inclusive)
        end_date: End time in ISO 8601 format (UTC, exclusive)

    Returns:
        AlertResponse containing alert data
    """
    try:
        alerts = await client.get_alerts(access_token, start_date, end_date)
        return alerts
    except RateLimitError as e:
        raise HTTPException(status_code=429, detail=str(e))
    except DexcomAPIError as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        await client.close()
