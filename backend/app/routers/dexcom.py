"""
Dexcom API endpoints
Exposes all 6 Dexcom API endpoints to the Flutter frontend
"""
from fastapi import APIRouter, Depends, HTTPException, Query, Request
from fastapi.responses import RedirectResponse
from datetime import datetime
from typing import Optional
from sqlalchemy.orm import Session
from app.services.dexcom_api import DexcomAPIClient, DexcomAPIError, RateLimitError
from app.services.token_storage import TokenStorageService
from app.database import get_db
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


async def get_user_id(request: Request) -> int:
    """
    Get user ID from request.

    TODO: Replace with Firebase authentication once implemented.
    For now, uses a header 'X-User-ID' for testing purposes.

    In production, this should:
    1. Validate Firebase JWT token from Authorization header
    2. Extract Firebase UID from token
    3. Look up user in database by Firebase UID
    4. Return user ID
    """
    # Temporary implementation for testing
    user_id_header = request.headers.get("X-User-ID")
    if user_id_header:
        try:
            return int(user_id_header)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid X-User-ID header")

    # For now, return a default test user ID
    # In production, this should raise 401 Unauthorized
    return 1  # Default test user


async def get_token_storage(db: Session = Depends(get_db)) -> TokenStorageService:
    """Dependency to get token storage service"""
    return TokenStorageService(db)


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


@router.get("/auth/callback")
async def oauth_callback(
    code: Optional[str] = Query(None, description="Authorization code from Dexcom"),
    state: Optional[str] = Query(None, description="CSRF protection state parameter"),
    error: Optional[str] = Query(None, description="Error from Dexcom"),
    request: Request = None,
    client: DexcomAPIClient = Depends(get_dexcom_client),
    token_storage: TokenStorageService = Depends(get_token_storage),
    user_id: int = Depends(get_user_id),
    settings: Settings = Depends(get_settings),
):
    """
    OAuth callback endpoint - handles the redirect from Dexcom after user authorization.

    This endpoint:
    1. Receives the authorization code from Dexcom
    2. Exchanges it for access and refresh tokens
    3. Encrypts and stores the tokens in the database
    4. Redirects the user to the frontend application

    Query Parameters:
        code: Authorization code (if successful)
        state: CSRF protection state (should match the one sent in authorization URL)
        error: Error code (if user denied access or error occurred)

    Returns:
        Redirects to frontend with success/error status
    """
    # Check for errors
    if error:
        # User denied access or error occurred
        error_message = "access_denied" if error == "access_denied" else "authorization_failed"
        # Redirect to frontend with error
        # TODO: Configure frontend URL in settings
        frontend_url = "http://localhost:3000"
        return RedirectResponse(url=f"{frontend_url}/auth/callback?error={error_message}")

    # Check if code is present
    if not code:
        raise HTTPException(status_code=400, detail="Missing authorization code")

    # TODO: Validate state parameter for CSRF protection
    # In production, compare state with the one stored in user's session

    try:
        # Exchange authorization code for tokens
        oauth_token = await client.exchange_code_for_token(code)

        # Get or create user
        user = token_storage.get_or_create_user()

        # Store encrypted tokens in database
        token_storage.store_tokens(
            user_id=user.id, oauth_token=oauth_token, state=state, scope="offline_access"
        )

        # Redirect to frontend with success
        # TODO: Configure frontend URL in settings
        frontend_url = "http://localhost:3000"
        return RedirectResponse(url=f"{frontend_url}/auth/callback?success=true&user_id={user.id}")

    except DexcomAPIError as e:
        # Log the error
        print(f"Dexcom API error during callback: {e.message}")
        # Redirect to frontend with error
        frontend_url = "http://localhost:3000"
        return RedirectResponse(url=f"{frontend_url}/auth/callback?error=token_exchange_failed")
    except Exception as e:
        # Log the error
        print(f"Unexpected error during callback: {str(e)}")
        # Redirect to frontend with error
        frontend_url = "http://localhost:3000"
        return RedirectResponse(url=f"{frontend_url}/auth/callback?error=server_error")
    finally:
        await client.close()


@router.post("/auth/token")
async def exchange_code(
    code: str = Query(..., description="Authorization code from OAuth callback"),
    state: Optional[str] = Query(None, description="CSRF state parameter"),
    client: DexcomAPIClient = Depends(get_dexcom_client),
    token_storage: TokenStorageService = Depends(get_token_storage),
    user_id: int = Depends(get_user_id),
):
    """
    Exchange authorization code for access token and refresh token.

    This endpoint can be used as an alternative to the callback endpoint
    for applications that want to handle the OAuth flow programmatically.

    Args:
        code: Authorization code from Dexcom OAuth callback
        state: Optional CSRF state parameter

    Returns:
        Success message and user info (tokens are stored securely)

    Note:
        Tokens are encrypted and stored in the database.
        This endpoint returns confirmation but not the actual tokens.
    """
    try:
        # Exchange code for tokens
        oauth_token = await client.exchange_code_for_token(code)

        # Get or create user
        user = token_storage.get_or_create_user()

        # Store encrypted tokens
        token_record = token_storage.store_tokens(
            user_id=user.id, oauth_token=oauth_token, state=state, scope="offline_access"
        )

        return {
            "message": "Authorization successful",
            "user_id": user.id,
            "token_expires_at": token_record.expires_at.isoformat(),
        }
    except DexcomAPIError as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)
    finally:
        await client.close()


@router.post("/auth/refresh")
async def refresh_token(
    client: DexcomAPIClient = Depends(get_dexcom_client),
    token_storage: TokenStorageService = Depends(get_token_storage),
    user_id: int = Depends(get_user_id),
):
    """
    Refresh the access token using the stored refresh token.

    This endpoint automatically retrieves the user's refresh token from
    the database, refreshes it, and stores the new tokens.

    Returns:
        Success message and new token expiration time

    Note:
        This is handled automatically by the token storage service
        when making API calls, so manual refresh is rarely needed.
    """
    try:
        # Get the stored refresh token
        refresh_token_str = token_storage.get_refresh_token(user_id)

        # Refresh the access token
        new_oauth_token = await client.refresh_access_token(refresh_token_str)

        # Store the new tokens
        token_record = token_storage.store_tokens(user_id=user_id, oauth_token=new_oauth_token)

        return {
            "message": "Token refreshed successfully",
            "expires_at": token_record.expires_at.isoformat(),
        }
    except DexcomAPIError as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)
    finally:
        await client.close()


@router.get("/auth/status")
async def get_auth_status(
    token_storage: TokenStorageService = Depends(get_token_storage),
    user_id: int = Depends(get_user_id),
):
    """
    Get the current authentication status for the user.

    Returns information about the user's Dexcom authorization,
    including token expiration status.

    Returns:
        Token status information (without sensitive data)
    """
    token_info = token_storage.get_token_info(user_id)

    if not token_info:
        return {
            "authorized": False,
            "message": "User has not authorized Dexcom access",
        }

    return {
        "authorized": True,
        "expires_at": token_info["expires_at"],
        "is_expired": token_info["is_expired"],
        "is_expiring_soon": token_info["is_expiring_soon"],
        "scope": token_info["scope"],
    }


@router.post("/auth/revoke")
async def revoke_authorization(
    token_storage: TokenStorageService = Depends(get_token_storage),
    user_id: int = Depends(get_user_id),
):
    """
    Revoke the user's Dexcom authorization.

    This marks the user's tokens as revoked in the database.
    The user will need to re-authorize to access Dexcom data again.

    Returns:
        Success message
    """
    token_storage.revoke_tokens(user_id)
    return {"message": "Authorization revoked successfully"}


@router.get("/egvs", response_model=EGVResponse)
async def get_egvs(
    start_date: datetime = Query(..., description="Start date (UTC, inclusive)"),
    end_date: datetime = Query(..., description="End date (UTC, exclusive)"),
    client: DexcomAPIClient = Depends(get_dexcom_client),
    token_storage: TokenStorageService = Depends(get_token_storage),
    user_id: int = Depends(get_user_id),
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
        - Access token is automatically retrieved and refreshed if needed
    """
    try:
        # Get valid access token (auto-refreshes if needed)
        access_token, _ = token_storage.get_valid_token(user_id)

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
    client: DexcomAPIClient = Depends(get_dexcom_client),
    token_storage: TokenStorageService = Depends(get_token_storage),
    user_id: int = Depends(get_user_id),
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
        # Get valid access token (auto-refreshes if needed)
        access_token, _ = token_storage.get_valid_token(user_id)

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
    client: DexcomAPIClient = Depends(get_dexcom_client),
    token_storage: TokenStorageService = Depends(get_token_storage),
    user_id: int = Depends(get_user_id),
):
    """
    Get available data range for user

    Returns the earliest and latest timestamps for which data is available.

    Returns:
        DataRangeResponse containing data range information
    """
    try:
        # Get valid access token (auto-refreshes if needed)
        access_token, _ = token_storage.get_valid_token(user_id)

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
    client: DexcomAPIClient = Depends(get_dexcom_client),
    token_storage: TokenStorageService = Depends(get_token_storage),
    user_id: int = Depends(get_user_id),
):
    """
    Get device information

    Returns information about Dexcom devices associated with the user.
    Supports G6, G7, Dexcom ONE, and Dexcom ONE+ devices.

    Returns:
        DeviceResponse containing device details
    """
    try:
        # Get valid access token (auto-refreshes if needed)
        access_token, _ = token_storage.get_valid_token(user_id)

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
    client: DexcomAPIClient = Depends(get_dexcom_client),
    token_storage: TokenStorageService = Depends(get_token_storage),
    user_id: int = Depends(get_user_id),
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
        # Get valid access token (auto-refreshes if needed)
        access_token, _ = token_storage.get_valid_token(user_id)

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
    client: DexcomAPIClient = Depends(get_dexcom_client),
    token_storage: TokenStorageService = Depends(get_token_storage),
    user_id: int = Depends(get_user_id),
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
        # Get valid access token (auto-refreshes if needed)
        access_token, _ = token_storage.get_valid_token(user_id)

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
