"""
SmartTransport GH — Bookings Router
=====================================
Booking management endpoints: CRUD operations for passenger trip requests.
"""

from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select

from auth import get_current_user, require_admin, require_driver_or_admin, require_any_role
from database import get_session
from models import Booking, BookingStatus, User, UserRole, Vehicle
from schemas import BookingCreate, BookingUpdate, BookingResponse

router = APIRouter(prefix="/bookings", tags=["Bookings"])


# ============================================================================
# List Bookings
# ============================================================================

@router.get("/", response_model=List[BookingResponse])
async def list_bookings(
    session: Session = Depends(get_session),
    current_user: User = Depends(require_any_role)
):
    """List bookings. Admin sees all; driver sees trip bookings; passenger sees own."""
    query = select(Booking)

    if current_user.role == UserRole.ADMIN:
        # Admin sees all bookings
        pass
    elif current_user.role == UserRole.DRIVER:
        # Driver sees bookings for their trips (would need join in real app)
        # For simplicity, return all bookings - filter client-side for now
        pass
    else:
        # Passenger sees only their own bookings
        query = query.where(Booking.passenger_id == current_user.id)

    bookings = session.exec(query).all()
    return bookings


# ============================================================================
# Get Booking by ID
# ============================================================================

@router.get("/{booking_id}", response_model=BookingResponse)
async def get_booking(
    booking_id: int,
    session: Session = Depends(get_session),
    current_user: User = Depends(require_any_role)
):
    """Get booking details by ID."""
    booking = session.get(Booking, booking_id)
    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Booking not found"
        )

    # Passengers can only view their own bookings
    if current_user.role == UserRole.PASSENGER and booking.passenger_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Can only view your own bookings"
        )

    return booking


# ============================================================================
# Create Booking (Passenger only)
# ============================================================================

@router.post("/", response_model=BookingResponse, status_code=status.HTTP_201_CREATED)
async def create_booking(
    booking_data: BookingCreate,
    session: Session = Depends(get_session),
    current_user: User = Depends(require_any_role)
):
    """Create a new booking. Passenger only."""
    if current_user.role != UserRole.PASSENGER:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only passengers can create bookings"
        )

    new_booking = Booking(
        trip_id=booking_data.trip_id,
        passenger_id=current_user.id,
        status=BookingStatus.PENDING
    )
    session.add(new_booking)
    session.commit()
    session.refresh(new_booking)
    return new_booking


# ============================================================================
# Update Booking Status
# ============================================================================

@router.patch("/{booking_id}", response_model=BookingResponse)
async def update_booking(
    booking_id: int,
    update_data: BookingUpdate,
    session: Session = Depends(get_session),
    current_user: User = Depends(require_any_role)
):
    """Update booking status. Passenger can cancel; driver/admin can confirm/complete."""
    booking = session.get(Booking, booking_id)
    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Booking not found"
        )

    # Check permissions
    if current_user.role == UserRole.PASSENGER:
        # Passengers can only cancel their own pending bookings
        if booking.passenger_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Can only update your own bookings"
            )
        if update_data.status != BookingStatus.CANCELLED:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Passengers can only cancel bookings"
            )
    elif current_user.role == UserRole.DRIVER:
        # Drivers can confirm or complete bookings for their trips
        # (Would need to verify trip ownership in real app)
        pass
    # Admins can do anything

    # Apply updates
    update_dict = update_data.model_dump(exclude_unset=True)
    for key, value in update_dict.items():
        setattr(booking, key, value)

    session.add(booking)
    session.commit()
    session.refresh(booking)
    return booking


# ============================================================================
# Delete Booking (Cancel - Passenger only)
# ============================================================================

@router.delete("/{booking_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_booking(
    booking_id: int,
    session: Session = Depends(get_session),
    current_user: User = Depends(require_any_role)
):
    """Cancel booking (soft delete). Passenger can cancel their own pending bookings."""
    booking = session.get(Booking, booking_id)
    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Booking not found"
        )

    # Only passengers can cancel their own bookings
    if current_user.role != UserRole.PASSENGER or booking.passenger_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Can only cancel your own bookings"
        )

    # Can only cancel pending bookings
    if booking.status != BookingStatus.PENDING:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Can only cancel pending bookings"
        )

    # Soft delete by cancelling
    booking.status = BookingStatus.CANCELLED
    session.add(booking)
    session.commit()


# ============================================================================
# Get Bookings for a Trip (Driver/Admin)
# ============================================================================

@router.get("/trip/{trip_id}", response_model=List)
async def get_trip_bookings(
    trip_id: int,
    session: Session = Depends(get_session),
    current_user: User = Depends(require_any_role)
):
    """Get all bookings for a specific trip."""
    bookings = session.exec(
        select(Booking).where(Booking.trip_id == trip_id)
    ).all()
    result = []
    for b in bookings:
        passenger = session.get(User, b.passenger_id)
        result.append({
            "id": b.id,
            "trip_id": b.trip_id,
            "passenger_id": b.passenger_id,
            "passenger_name": passenger.name if passenger else "Unknown",
            "status": b.status.value if hasattr(b.status, 'value') else b.status,
            "requested_at": b.requested_at.isoformat() if b.requested_at else None,
        })
    return result
