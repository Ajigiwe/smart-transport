"""
SmartTransport GH — Trips Router
==================================
Trip management endpoints with WebSocket for live location tracking.
"""

import json
from datetime import datetime
from typing import List, Optional, Set

from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect, status
from sqlmodel import Session, select

from auth import get_current_user, require_admin, require_driver_or_admin, require_any_role
from database import get_session
from models import Trip, TripStatus, LocationPing, User, UserRole
from schemas import TripCreate, TripUpdate, TripResponse, LocationPingResponse

router = APIRouter(prefix="/trips", tags=["Trips"])


# ============================================================================
# WebSocket Connection Manager
# ============================================================================

class ConnectionManager:
    """Manages WebSocket connections for live trip tracking."""

    def __init__(self):
        # trip_id -> set of WebSocket connections
        self.active_connections: dict[int, Set[WebSocket]] = {}

    async def connect(self, websocket: WebSocket, trip_id: int):
        await websocket.accept()
        if trip_id not in self.active_connections:
            self.active_connections[trip_id] = set()
        self.active_connections[trip_id].add(websocket)

    def disconnect(self, websocket: WebSocket, trip_id: int):
        if trip_id in self.active_connections:
            self.active_connections[trip_id].discard(websocket)
            if not self.active_connections[trip_id]:
                del self.active_connections[trip_id]

    async def broadcast(self, trip_id: int, message: dict):
        if trip_id in self.active_connections:
            for connection in self.active_connections[trip_id]:
                try:
                    await connection.send_json(message)
                except:
                    pass


manager = ConnectionManager()


# ============================================================================
# List Trips
# ============================================================================

@router.get("/", response_model=List[TripResponse])
async def list_trips(
    status_filter: Optional[TripStatus] = None,
    route_id: Optional[int] = None,
    session: Session = Depends(get_session),
    current_user: User = Depends(require_any_role)
):
    """List trips. Admin sees all; driver sees own; passenger sees active."""
    query = select(Trip)

    if current_user.role == UserRole.ADMIN:
        pass
    elif current_user.role == UserRole.DRIVER:
        query = query.where(Trip.driver_id == current_user.id)
    else:
        query = query.where(Trip.status == TripStatus.ACTIVE)

    if status_filter:
        query = query.where(Trip.status == status_filter)
    if route_id:
        query = query.where(Trip.route_id == route_id)

    trips = session.exec(query).all()
    return trips


# ============================================================================
# Get Trip by ID
# ============================================================================

@router.get("/{trip_id}", response_model=TripResponse)
async def get_trip(
    trip_id: int,
    session: Session = Depends(get_session),
    current_user: User = Depends(require_any_role)
):
    """Get trip details by ID."""
    trip = session.get(Trip, trip_id)
    if not trip:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Trip not found"
        )
    return trip


# ============================================================================
# Create Trip (Admin or Driver)
# ============================================================================

@router.post("/", response_model=TripResponse, status_code=status.HTTP_201_CREATED)
async def create_trip(
    trip_data: TripCreate,
    session: Session = Depends(get_session),
    current_user: User = Depends(require_driver_or_admin)
):
    """Create a new trip. Admin or driver can create."""
    # Drivers can only create trips for themselves
    if current_user.role == UserRole.DRIVER and trip_data.driver_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Drivers can only create trips for themselves"
        )

    new_trip = Trip(**trip_data.model_dump())
    session.add(new_trip)
    session.commit()
    session.refresh(new_trip)
    return new_trip


# ============================================================================
# Update Trip Status (Driver or Admin)
# ============================================================================

@router.patch("/{trip_id}", response_model=TripResponse)
async def update_trip(
    trip_id: int,
    update_data: TripUpdate,
    session: Session = Depends(get_session),
    current_user: User = Depends(require_driver_or_admin)
):
    """Update trip status. Driver or admin."""
    trip = session.get(Trip, trip_id)
    if not trip:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Trip not found"
        )

    # Drivers can only update their own trips
    if current_user.role == UserRole.DRIVER and trip.driver_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Can only update your own trips"
        )

    # Apply updates
    update_dict = update_data.model_dump(exclude_unset=True)

    # Auto-set timestamps based on status
    if "status" in update_dict:
        if update_dict["status"] == TripStatus.ACTIVE:
            trip.started_at = datetime.utcnow()
        elif update_dict["status"] in [TripStatus.COMPLETED, TripStatus.CANCELLED]:
            trip.ended_at = datetime.utcnow()

    for key, value in update_dict.items():
        setattr(trip, key, value)

    session.add(trip)
    session.commit()
    session.refresh(trip)
    return trip


# ============================================================================
# WebSocket Endpoint for Live Tracking
# ============================================================================

@router.websocket("/ws/{trip_id}")
async def websocket_endpoint(
    websocket: WebSocket,
    trip_id: int,
    session: Session = Depends(get_session)
):
    """WebSocket endpoint for live location tracking.
    Drivers send location updates; passengers receive them.
    """
    await manager.connect(websocket, trip_id)
    try:
        while True:
            # Receive location data from driver
            data = await websocket.receive_text()
            location_data = json.loads(data)

            # Store location ping in database
            ping = LocationPing(
                trip_id=trip_id,
                lat=location_data["lat"],
                lng=location_data["lng"]
            )
            session.add(ping)
            session.commit()

            # Broadcast to all connected clients for this trip
            await manager.broadcast(trip_id, {
                "type": "location_update",
                "trip_id": trip_id,
                "lat": location_data["lat"],
                "lng": location_data["lng"],
                "timestamp": ping.timestamp.isoformat()
            })
    except WebSocketDisconnect:
        manager.disconnect(websocket, trip_id)


# ============================================================================
# Get Trip Location History
# ============================================================================

@router.get("/{trip_id}/locations", response_model=List[LocationPingResponse])
async def get_trip_locations(
    trip_id: int,
    session: Session = Depends(get_session),
    current_user: User = Depends(require_any_role)
):
    """Get location history for a trip."""
    trip = session.get(Trip, trip_id)
    if not trip:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Trip not found"
        )

    locations = session.exec(
        select(LocationPing)
        .where(LocationPing.trip_id == trip_id)
        .order_by(LocationPing.timestamp)
    ).all()
    return locations


# ============================================================================
# Get Trip with Related Details
# ============================================================================

@router.get("/{trip_id}/details")
async def get_trip_details(
    trip_id: int,
    session: Session = Depends(get_session),
    current_user: User = Depends(require_any_role)
):
    """Get trip with joined route, driver, and vehicle details."""
    trip = session.get(Trip, trip_id)
    if not trip:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Trip not found"
        )

    from models import Route as RouteModel, Vehicle as VehicleModel
    route = session.get(RouteModel, trip.route_id)
    driver = session.get(User, trip.driver_id)
    vehicle = session.get(VehicleModel, trip.vehicle_id)

    return {
        "trip": TripResponse.model_validate(trip),
        "route": {
            "id": route.id,
            "name": route.name,
            "start_point": route.start_point,
            "end_point": route.end_point,
            "fare": route.fare,
            "stops": route.stops,
        } if route else None,
        "driver": {
            "id": driver.id,
            "name": driver.name,
            "phone": driver.phone,
        } if driver else None,
        "vehicle": {
            "id": vehicle.id,
            "plate_number": vehicle.plate_number,
            "capacity": vehicle.capacity,
        } if vehicle else None,
    }
