"""
SmartTransport GH — SQLModel Data Models
=========================================
Core data models for the public transport management system.
"""

from datetime import datetime
from enum import Enum
from typing import List, Optional

from sqlalchemy import func
from sqlmodel import SQLModel, Field, Relationship


# ============================================================================
# Enums
# ============================================================================

class UserRole(str, Enum):
    PASSENGER = "passenger"
    DRIVER = "driver"
    ADMIN = "admin"


class VehicleStatus(str, Enum):
    ACTIVE = "active"
    INACTIVE = "inactive"
    MAINTENANCE = "maintenance"


class TripStatus(str, Enum):
    SCHEDULED = "scheduled"
    ACTIVE = "active"
    COMPLETED = "completed"
    CANCELLED = "cancelled"


class BookingStatus(str, Enum):
    PENDING = "pending"
    CONFIRMED = "confirmed"
    CANCELLED = "cancelled"
    COMPLETED = "completed"


# ============================================================================
# User Model
# ============================================================================

class User(SQLModel, table=True):
    """User model supporting three roles: passenger, driver, admin."""
    __tablename__ = "users"

    id: Optional[int] = Field(default=None, primary_key=True)
    name: str = Field(max_length=100, index=True)
    phone: str = Field(max_length=20, unique=True, index=True)
    email: Optional[str] = Field(default=None, max_length=100, unique=True, index=True)
    password_hash: str = Field(max_length=255)
    role: UserRole = Field(default=UserRole.PASSENGER)
    is_active: bool = Field(default=True)
    is_online: bool = Field(default=False)
    created_at: Optional[datetime] = Field(default=None, sa_column_kwargs={"server_default": func.now()})

    # Relationships
    vehicles: List["Vehicle"] = Relationship(back_populates="driver")
    bookings: List["Booking"] = Relationship(back_populates="passenger")
    trips_as_driver: List["Trip"] = Relationship(
        back_populates="driver",
        sa_relationship_kwargs={"foreign_keys": "[Trip.driver_id]"}
    )


# ============================================================================
# Vehicle Model
# ============================================================================

class Vehicle(SQLModel, table=True):
    """Vehicle registered by admin and assigned to a driver."""
    __tablename__ = "vehicles"

    id: Optional[int] = Field(default=None, primary_key=True)
    plate_number: str = Field(max_length=20, unique=True, index=True)
    capacity: int = Field(default=4)  # Number of passengers
    driver_id: Optional[int] = Field(default=None, foreign_key="users.id", index=True)
    status: VehicleStatus = Field(default=VehicleStatus.ACTIVE)
    created_at: Optional[datetime] = Field(default=None, sa_column_kwargs={"server_default": func.now()})

    # Relationships
    driver: Optional[User] = Relationship(back_populates="vehicles")
    trips: List["Trip"] = Relationship(back_populates="vehicle")


# ============================================================================
# Route Model
# ============================================================================

class Route(SQLModel, table=True):
    """Transport route with start/end points and fare."""
    __tablename__ = "routes"

    id: Optional[int] = Field(default=None, primary_key=True)
    name: str = Field(max_length=100, index=True)
    start_point: str = Field(max_length=100)
    end_point: str = Field(max_length=100)
    fare: float = Field(default=0.0)  # In GHS (Ghana Cedis)
    stops: Optional[str] = Field(default=None)  # JSON list of stops as string
    is_active: bool = Field(default=True)
    created_at: Optional[datetime] = Field(default=None, sa_column_kwargs={"server_default": func.now()})

    # Relationships
    trips: List["Trip"] = Relationship(back_populates="route")


# ============================================================================
# Trip Model
# ============================================================================

class Trip(SQLModel, table=True):
    """A scheduled or active trip on a route."""
    __tablename__ = "trips"

    id: Optional[int] = Field(default=None, primary_key=True)
    route_id: int = Field(foreign_key="routes.id", index=True)
    driver_id: int = Field(foreign_key="users.id", index=True)
    vehicle_id: int = Field(foreign_key="vehicles.id", index=True)
    status: TripStatus = Field(default=TripStatus.SCHEDULED)
    started_at: Optional[datetime] = Field(default=None)
    ended_at: Optional[datetime] = Field(default=None)
    created_at: Optional[datetime] = Field(default=None, sa_column_kwargs={"server_default": func.now()})

    # Relationships
    route: Route = Relationship(back_populates="trips")
    driver: User = Relationship(
        back_populates="trips_as_driver",
        sa_relationship_kwargs={"foreign_keys": "[Trip.driver_id]"}
    )
    vehicle: Vehicle = Relationship(back_populates="trips")
    location_pings: List["LocationPing"] = Relationship(back_populates="trip")
    bookings: List["Booking"] = Relationship(back_populates="trip")


# ============================================================================
# LocationPing Model
# ============================================================================

class LocationPing(SQLModel, table=True):
    """GPS location ping from a driver during an active trip."""
    __tablename__ = "location_pings"

    id: Optional[int] = Field(default=None, primary_key=True)
    trip_id: int = Field(foreign_key="trips.id", index=True)
    lat: float = Field()
    lng: float = Field()
    timestamp: Optional[datetime] = Field(default=None, sa_column_kwargs={"server_default": func.now()}, index=True)

    # Relationships
    trip: Trip = Relationship(back_populates="location_pings")


# ============================================================================
# Booking Model
# ============================================================================

class Booking(SQLModel, table=True):
    """Passenger booking/request for a trip."""
    __tablename__ = "bookings"

    id: Optional[int] = Field(default=None, primary_key=True)
    trip_id: int = Field(foreign_key="trips.id", index=True)
    passenger_id: int = Field(foreign_key="users.id", index=True)
    status: BookingStatus = Field(default=BookingStatus.PENDING)
    requested_at: Optional[datetime] = Field(default=None, sa_column_kwargs={"server_default": func.now()})
    updated_at: Optional[datetime] = Field(default=None)

    # Relationships
    trip: Trip = Relationship(back_populates="bookings")
    passenger: User = Relationship(back_populates="bookings")
