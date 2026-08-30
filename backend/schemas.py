"""
SmartTransport GH — Pydantic Schemas
======================================
Request/response schemas for API endpoints.
"""

from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, EmailStr

from models import UserRole, VehicleStatus, TripStatus, BookingStatus


# ============================================================================
# Auth Schemas
# ============================================================================

class UserRegister(BaseModel):
    name: str
    phone: str
    email: Optional[str] = None
    password: str
    role: UserRole = UserRole.PASSENGER


class UserLogin(BaseModel):
    phone: str
    password: str


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    role: UserRole
    user_id: int


class TokenData(BaseModel):
    user_id: Optional[int] = None
    role: Optional[UserRole] = None


# ============================================================================
# User Schemas
# ============================================================================

class UserBase(BaseModel):
    name: str
    phone: str
    email: Optional[str] = None
    role: UserRole = UserRole.PASSENGER


class UserCreate(UserBase):
    password: str


class UserUpdate(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    is_active: Optional[bool] = None


class UserResponse(UserBase):
    id: int
    is_active: bool
    is_online: bool = False
    created_at: datetime

    class Config:
        from_attributes = True


# ============================================================================
# Vehicle Schemas
# ============================================================================

class VehicleBase(BaseModel):
    plate_number: str
    capacity: int = 4
    status: VehicleStatus = VehicleStatus.ACTIVE


class VehicleCreate(VehicleBase):
    driver_id: Optional[int] = None


class VehicleUpdate(BaseModel):
    plate_number: Optional[str] = None
    capacity: Optional[int] = None
    driver_id: Optional[int] = None
    status: Optional[VehicleStatus] = None


class VehicleResponse(VehicleBase):
    id: int
    driver_id: Optional[int] = None
    created_at: datetime

    class Config:
        from_attributes = True


# ============================================================================
# Route Schemas
# ============================================================================

class RouteBase(BaseModel):
    name: str
    start_point: str
    end_point: str
    fare: float = 0.0
    stops: Optional[str] = None


class RouteCreate(RouteBase):
    pass


class RouteUpdate(BaseModel):
    name: Optional[str] = None
    start_point: Optional[str] = None
    end_point: Optional[str] = None
    fare: Optional[float] = None
    stops: Optional[str] = None
    is_active: Optional[bool] = None


class RouteResponse(RouteBase):
    id: int
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True


# ============================================================================
# Trip Schemas
# ============================================================================

class TripBase(BaseModel):
    route_id: int
    driver_id: int
    vehicle_id: int
    status: TripStatus = TripStatus.SCHEDULED


class TripCreate(TripBase):
    pass


class TripUpdate(BaseModel):
    status: Optional[TripStatus] = None
    started_at: Optional[datetime] = None
    ended_at: Optional[datetime] = None


class TripResponse(TripBase):
    id: int
    started_at: Optional[datetime] = None
    ended_at: Optional[datetime] = None
    created_at: datetime

    class Config:
        from_attributes = True


# ============================================================================
# LocationPing Schemas
# ============================================================================

class LocationPingBase(BaseModel):
    lat: float
    lng: float


class LocationPingCreate(LocationPingBase):
    trip_id: int


class LocationPingResponse(LocationPingBase):
    id: int
    trip_id: int
    timestamp: datetime

    class Config:
        from_attributes = True


# ============================================================================
# Booking Schemas
# ============================================================================

class BookingBase(BaseModel):
    trip_id: int
    passenger_id: int
    status: BookingStatus = BookingStatus.PENDING


class BookingCreate(BaseModel):
    trip_id: int


class BookingUpdate(BaseModel):
    status: Optional[BookingStatus] = None


class BookingResponse(BookingBase):
    id: int
    requested_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# ============================================================================
# Dashboard Stats Schema
# ============================================================================

class DashboardStats(BaseModel):
    active_trips: int = 0
    total_drivers: int = 0
    total_routes: int = 0
    total_passengers: int = 0
    total_vehicles: int = 0


# ============================================================================
# HailRequest Schemas
# ============================================================================

class HailCreate(BaseModel):
    pickup_location: str
    destination: str
    pickup_lat: Optional[float] = None
    pickup_lng: Optional[float] = None
    destination_lat: Optional[float] = None
    destination_lng: Optional[float] = None
    passengers_count: int = 1


class HailResponse(BaseModel):
    id: int
    passenger_id: int
    driver_id: Optional[int] = None
    pickup_location: str
    destination: str
    pickup_lat: Optional[float] = None
    pickup_lng: Optional[float] = None
    destination_lat: Optional[float] = None
    destination_lng: Optional[float] = None
    passengers_count: int
    fare_estimate: Optional[float] = None
    status: str
    created_at: Optional[datetime] = None
    accepted_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    passenger_name: Optional[str] = None
    passenger_phone: Optional[str] = None
    driver_name: Optional[str] = None
    driver_phone: Optional[str] = None
    driver_plate: Optional[str] = None

    class Config:
        from_attributes = True
