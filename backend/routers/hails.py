"""
SmartTransport GH — Hails Router
=================================
Ride-hailing: passengers create hails, nearby drivers accept.
"""

from datetime import datetime
from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select

from auth import get_current_user, require_role
from database import get_session
from models import HailRequest, HailStatus, User, UserRole, Vehicle
from schemas import HailCreate, HailResponse

router = APIRouter(prefix="/hails", tags=["Hails"])


def _hail_to_response(hail: HailRequest, session: Session) -> dict:
    """Enrich hail with passenger/driver info."""
    passenger = session.get(User, hail.passenger_id)
    driver = session.get(User, hail.driver_id) if hail.driver_id else None
    driver_vehicle = None
    if driver:
        driver_vehicle = session.exec(
            select(Vehicle).where(Vehicle.driver_id == driver.id)
        ).first()

    return {
        "id": hail.id,
        "passenger_id": hail.passenger_id,
        "driver_id": hail.driver_id,
        "pickup_location": hail.pickup_location,
        "destination": hail.destination,
        "pickup_lat": hail.pickup_lat,
        "pickup_lng": hail.pickup_lng,
        "destination_lat": hail.destination_lat,
        "destination_lng": hail.destination_lng,
        "passengers_count": hail.passengers_count,
        "fare_estimate": hail.fare_estimate,
        "status": hail.status.value if hasattr(hail.status, 'value') else hail.status,
        "created_at": hail.created_at.isoformat() if hail.created_at else None,
        "accepted_at": hail.accepted_at.isoformat() if hail.accepted_at else None,
        "completed_at": hail.completed_at.isoformat() if hail.completed_at else None,
        "passenger_name": passenger.name if passenger else None,
        "passenger_phone": passenger.phone if passenger else None,
        "driver_name": driver.name if driver else None,
        "driver_phone": driver.phone if driver else None,
        "driver_plate": driver_vehicle.plate_number if driver_vehicle else None,
    }


# ============================================================================
# Passenger: Create a hail
# ============================================================================

@router.post("/", response_model=HailResponse, status_code=status.HTTP_201_CREATED)
async def create_hail(
    hail_data: HailCreate,
    session: Session = Depends(get_session),
    current_user: User = Depends(require_role(UserRole.PASSENGER))
):
    """Passenger requests a ride. Drivers will see and can accept."""
    # Cancel any existing searching hails for this passenger
    existing = session.exec(
        select(HailRequest).where(
            HailRequest.passenger_id == current_user.id,
            HailRequest.status == HailStatus.SEARCHING
        )
    ).all()
    for h in existing:
        h.status = HailStatus.CANCELLED
        session.add(h)

    new_hail = HailRequest(
        passenger_id=current_user.id,
        pickup_location=hail_data.pickup_location,
        destination=hail_data.destination,
        pickup_lat=hail_data.pickup_lat,
        pickup_lng=hail_data.pickup_lng,
        destination_lat=hail_data.destination_lat,
        destination_lng=hail_data.destination_lng,
        passengers_count=hail_data.passengers_count,
        status=HailStatus.SEARCHING,
    )
    session.add(new_hail)
    session.commit()
    session.refresh(new_hail)
    return _hail_to_response(new_hail, session)


# ============================================================================
# Passenger: Get my hails
# ============================================================================

@router.get("/me", response_model=List[HailResponse])
async def get_my_hails(
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user)
):
    """Get current user's hail history."""
    if current_user.role == UserRole.PASSENGER:
        hails = session.exec(
            select(HailRequest).where(HailRequest.passenger_id == current_user.id)
            .order_by(HailRequest.created_at.desc())
        ).all()
    elif current_user.role == UserRole.DRIVER:
        hails = session.exec(
            select(HailRequest).where(HailRequest.driver_id == current_user.id)
            .order_by(HailRequest.created_at.desc())
        ).all()
    else:
        hails = session.exec(
            select(HailRequest).order_by(HailRequest.created_at.desc())
        ).all()
    return [_hail_to_response(h, session) for h in hails]


# ============================================================================
# Passenger: Cancel a hail
# ============================================================================

@router.patch("/{hail_id}/cancel", response_model=HailResponse)
async def cancel_hail(
    hail_id: int,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user)
):
    """Cancel a hail request."""
    hail = session.get(HailRequest, hail_id)
    if not hail:
        raise HTTPException(status_code=404, detail="Hail not found")

    # Only passenger who owns it or driver assigned can cancel
    if current_user.id != hail.passenger_id and current_user.id != hail.driver_id:
        raise HTTPException(status_code=403, detail="Not your hail")

    if hail.status in (HailStatus.COMPLETED, HailStatus.CANCELLED):
        raise HTTPException(status_code=400, detail="Hail already finished")

    hail.status = HailStatus.CANCELLED
    session.add(hail)
    session.commit()
    session.refresh(hail)
    return _hail_to_response(hail, session)


# ============================================================================
# Driver: Get searching hails (available rides nearby)
# ============================================================================

@router.get("/available", response_model=List[HailResponse])
async def get_available_hails(
    session: Session = Depends(get_session),
    current_user: User = Depends(require_role(UserRole.DRIVER))
):
    """Get hails that are searching for a driver."""
    hails = session.exec(
        select(HailRequest).where(HailRequest.status == HailStatus.SEARCHING)
        .order_by(HailRequest.created_at.desc())
    ).all()
    return [_hail_to_response(h, session) for h in hails]


# ============================================================================
# Driver: Accept a hail
# ============================================================================

@router.patch("/{hail_id}/accept", response_model=HailResponse)
async def accept_hail(
    hail_id: int,
    session: Session = Depends(get_session),
    current_user: User = Depends(require_role(UserRole.DRIVER))
):
    """Driver accepts a passenger's hail request."""
    hail = session.get(HailRequest, hail_id)
    if not hail:
        raise HTTPException(status_code=404, detail="Hail not found")

    if hail.status != HailStatus.SEARCHING:
        raise HTTPException(status_code=400, detail="Hail is no longer available")

    # Check driver is online and has a vehicle
    vehicle = session.exec(
        select(Vehicle).where(Vehicle.driver_id == current_user.id)
    ).first()
    if not vehicle:
        raise HTTPException(status_code=400, detail="You need a vehicle to accept hails")

    if not current_user.is_online:
        raise HTTPException(status_code=400, detail="Go online to accept hails")

    hail.driver_id = current_user.id
    hail.status = HailStatus.ACCEPTED
    hail.accepted_at = datetime.utcnow()
    hail.fare_estimate = 10.0  # TODO: calculate based on distance
    session.add(hail)
    session.commit()
    session.refresh(hail)
    return _hail_to_response(hail, session)


# ============================================================================
# Driver: Mark trip in progress
# ============================================================================

@router.patch("/{hail_id}/start", response_model=HailResponse)
async def start_hail_trip(
    hail_id: int,
    session: Session = Depends(get_session),
    current_user: User = Depends(require_role(UserRole.DRIVER))
):
    """Driver starts the trip."""
    hail = session.get(HailRequest, hail_id)
    if not hail:
        raise HTTPException(status_code=404, detail="Hail not found")
    if hail.driver_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not your hail")
    if hail.status != HailStatus.ACCEPTED:
        raise HTTPException(status_code=400, detail="Hail is not in accepted state")

    hail.status = HailStatus.IN_PROGRESS
    session.add(hail)
    session.commit()
    session.refresh(hail)
    return _hail_to_response(hail, session)


# ============================================================================
# Driver: Complete trip
# ============================================================================

@router.patch("/{hail_id}/complete", response_model=HailResponse)
async def complete_hail_trip(
    hail_id: int,
    session: Session = Depends(get_session),
    current_user: User = Depends(require_role(UserRole.DRIVER))
):
    """Driver completes the trip."""
    hail = session.get(HailRequest, hail_id)
    if not hail:
        raise HTTPException(status_code=404, detail="Hail not found")
    if hail.driver_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not your hail")

    hail.status = HailStatus.COMPLETED
    hail.completed_at = datetime.utcnow()
    session.add(hail)
    session.commit()
    session.refresh(hail)
    return _hail_to_response(hail, session)
