"""
Pydantic models for Dexcom API data
Based on Dexcom API v3 specification
"""
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from enum import Enum


class DexcomEnvironment(str, Enum):
    """Dexcom API environments"""
    SANDBOX = "sandbox"
    US = "us"
    EU = "eu"
    JP = "jp"


class TrendType(str, Enum):
    """Glucose trend types"""
    NONE = "none"
    DOUBLE_UP = "doubleUp"
    SINGLE_UP = "singleUp"
    FORTY_FIVE_UP = "fortyFiveUp"
    FLAT = "flat"
    FORTY_FIVE_DOWN = "fortyFiveDown"
    SINGLE_DOWN = "singleDown"
    DOUBLE_DOWN = "doubleDown"
    NOT_COMPUTABLE = "notComputable"
    RATE_OUT_OF_RANGE = "rateOutOfRange"


class TransmitterGeneration(str, Enum):
    """Transmitter generations"""
    G6 = "g6"
    G7 = "g7"
    UNKNOWN = "unknown"


class Unit(BaseModel):
    """Unit of measurement"""
    value: str = Field(..., description="Unit value (e.g., 'mg/dL', 'mg/dL/min')")


class EGV(BaseModel):
    """Estimated Glucose Value"""
    recordId: str = Field(..., description="Unique record identifier")
    systemTime: datetime = Field(..., description="UTC time according to device")
    displayTime: datetime = Field(..., description="Time displayed on device to user")
    value: Optional[int] = Field(None, description="Glucose value in mg/dL")
    unit: str = Field(default="mg/dL", description="Unit of measurement")
    rateUnit: str = Field(default="mg/dL/min", description="Rate unit")
    trend: Optional[TrendType] = Field(None, description="Glucose trend")
    trendRate: Optional[float] = Field(None, description="Trend rate")
    transmitterGeneration: Optional[TransmitterGeneration] = Field(None, description="Transmitter generation")
    transmitterId: Optional[str] = Field(None, description="Transmitter ID")
    displayDevice: Optional[str] = Field(None, description="Display device")


class EGVResponse(BaseModel):
    """Response from /egvs endpoint"""
    recordType: str = Field(..., description="Type of record")
    recordVersion: str = Field(..., description="Version of record format")
    userId: str = Field(..., description="User ID")
    records: List[EGV] = Field(default_factory=list, description="List of EGV records")


class Calibration(BaseModel):
    """Calibration entry"""
    recordId: str = Field(..., description="Unique record identifier")
    systemTime: datetime = Field(..., description="UTC time according to device")
    displayTime: datetime = Field(..., description="Time displayed on device")
    value: int = Field(..., description="Calibration value in mg/dL")
    unit: str = Field(default="mg/dL", description="Unit of measurement")
    transmitterGeneration: Optional[TransmitterGeneration] = Field(None, description="Transmitter generation")
    transmitterId: Optional[str] = Field(None, description="Transmitter ID")
    displayDevice: Optional[str] = Field(None, description="Display device")


class CalibrationResponse(BaseModel):
    """Response from /calibrations endpoint"""
    recordType: str
    recordVersion: str
    userId: str
    records: List[Calibration] = Field(default_factory=list)


class DataRange(BaseModel):
    """Data range information"""
    systemTime: datetime = Field(..., description="UTC time according to device")
    displayTime: datetime = Field(..., description="Time displayed on device")


class DataRangeResponse(BaseModel):
    """Response from /dataRange endpoint"""
    recordType: str
    recordVersion: str
    userId: str
    calibrations: DataRange
    egvs: DataRange
    events: DataRange


class Device(BaseModel):
    """Device information"""
    transmitterGeneration: Optional[TransmitterGeneration] = Field(None, description="Transmitter generation")
    transmitterId: Optional[str] = Field(None, description="Transmitter ID")
    displayDevice: str = Field(..., description="Display device name")
    lastUploadDate: datetime = Field(..., description="Last upload timestamp")
    alertScheduleList: Optional[List[dict]] = Field(None, description="Alert schedules")


class DeviceResponse(BaseModel):
    """Response from /devices endpoint"""
    recordType: str
    recordVersion: str
    userId: str
    records: List[Device] = Field(default_factory=list)


class EventType(str, Enum):
    """User event types"""
    INSULIN = "insulin"
    CARBS = "carbs"
    EXERCISE = "exercise"
    HEALTH = "health"
    NOTES = "notes"


class EventSubType(str, Enum):
    """Event subtypes"""
    FAST_ACTING = "fastActing"
    LONG_ACTING = "longActing"
    ILLNESS = "illness"
    STRESS = "stress"
    HIGH_SYMPTOMS = "highSymptoms"
    LOW_SYMPTOMS = "lowSymptoms"
    CYCLE = "cycle"
    ALCOHOL = "alcohol"
    LIGHT = "light"
    MEDIUM = "medium"
    HEAVY = "heavy"


class Event(BaseModel):
    """User-entered event"""
    recordId: str = Field(..., description="Unique record identifier")
    systemTime: datetime = Field(..., description="UTC time according to device")
    displayTime: datetime = Field(..., description="Time displayed on device")
    eventType: EventType = Field(..., description="Type of event")
    eventSubType: Optional[EventSubType] = Field(None, description="Event subtype")
    value: Optional[float] = Field(None, description="Event value")
    unit: Optional[str] = Field(None, description="Unit of measurement")
    transmitterGeneration: Optional[TransmitterGeneration] = Field(None, description="Transmitter generation")
    transmitterId: Optional[str] = Field(None, description="Transmitter ID")
    displayDevice: Optional[str] = Field(None, description="Display device")


class EventResponse(BaseModel):
    """Response from /events endpoint"""
    recordType: str
    recordVersion: str
    userId: str
    records: List[Event] = Field(default_factory=list)


class Alert(BaseModel):
    """Alert information"""
    recordId: str = Field(..., description="Unique record identifier")
    systemTime: datetime = Field(..., description="UTC time according to device")
    displayTime: datetime = Field(..., description="Time displayed on device")
    alertName: str = Field(..., description="Name of the alert")
    alertState: str = Field(..., description="State of the alert")
    displayDevice: Optional[str] = Field(None, description="Display device")


class AlertResponse(BaseModel):
    """Response from /alerts endpoint"""
    recordType: str
    recordVersion: str
    userId: str
    records: List[Alert] = Field(default_factory=list)


class OAuthToken(BaseModel):
    """OAuth token response"""
    access_token: str
    token_type: str
    expires_in: int
    refresh_token: str


class DexcomError(BaseModel):
    """Dexcom API error response"""
    error: str
    error_description: Optional[str] = None
