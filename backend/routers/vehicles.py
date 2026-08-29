"""
SmartTransport GH — Vehicles Router
=====================================
Vehicle management endpoints: CRUD operations.
"""

from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select

from auth import get_current_user, require_admin, require_driver_or_admin, require_any_role
from database import get_session
from models import Vehicle, User, UserRole
from schemas import VehicleCreate, VehicleUpdate, VehicleResponse

router = APIRouter(prefix="/vehicles", tags=["Vehicles"])


# ============================================================================
# Get Current Driver's Vehicle
# ============================================================================

@router.get("/driver/me", response_model=VehicleResponse)
async def get_my_vehicle(
    session: Session = Depends(get_session),
    current_user: User = Depends(require_any_role)
):
    """Get the current driver's assigned vehicle."""
    if current_user.role != UserRole.DRIVER and current_user.role != UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only drivers can access their vehicle"
        )
    vehicle = session.exec(
        select(Vehicle).where(Vehicle.driver_id == current_user.id)
    ).first()
    if not vehicle:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No vehicle assigned to you"
        )
    return vehicle


# ============================================================================
# List Vehicles (Admin: all, Driver: own)
# ============================================================================

@router.get("/", response_model=List[VehicleResponse])
async def list_vehicles(
    session: Session = Depends(get_session),
    current_user: User = Depends(require_driver_or_admin)
):
    """List vehicles. Admin sees all; driver sees only assigned vehicle."""
    if current_user.role == UserRole.ADMIN:
        vehicles = session.exec(select(Vehicle)).all()
    else:
        # Driver sees only their assigned vehicle
        vehicles = session.exec(
            select(Vehicle).where(Vehicle.driver_id == current_user.id)
        ).all()
    return vehicles


# ============================================================================
# Get Vehicle by ID
# ============================================================================

@router.get("/{vehicle_id}", response_model=VehicleResponse)
async def get_vehicle(
    vehicle_id: int,
    session: Session = Depends(get_session),
    current_user: User = Depends(require_driver_or_admin)
):
    """Get vehicle details by ID."""
    vehicle = session.get(Vehicle, vehicle_id)
    if not vehicle:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Vehicle not found"
        )

    # Drivers can only view their assigned vehicle
    if current_user.role == UserRole.DRIVER and vehicle.driver_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Can only view your assigned vehicle"
        )

    return vehicle


# ============================================================================
# Create Vehicle (Admin only)
# ============================================================================

@router.post("/", response_model=VehicleResponse, status_code=status.HTTP_201_CREATED)
async def create_vehicle(
    vehicle_data: VehicleCreate,
    session: Session = Depends(get_session),
    current_user: User = Depends(require_admin)
):
    """Create a new vehicle. Admin only."""
    new_vehicle = Vehicle(**vehicle_data.model_dump())
    session.add(new_vehicle)
    session.commit()
    session.refresh(new_vehicle)
    return new_vehicle


# ============================================================================
# Update Vehicle (Admin only)
# ============================================================================

@router.patch("/{vehicle_id}", response_model=VehicleResponse)
async def update_vehicle(
    vehicle_id: int,
    update_data: VehicleUpdate,
    session: Session = Depends(get_session),
    current_user: User = Depends(require_admin)
):
    """Update vehicle details. Admin only."""
    vehicle = session.get(Vehicle, vehicle_id)
    if not vehicle:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Vehicle not found"
        )

    # Apply updates
    update_dict = update_data.model_dump(exclude_unset=True)
    for key, value in update_dict.items():
        setattr(vehicle, key, value)

    session.add(vehicle)
    session.commit()
    session.refresh(vehicle)
    return vehicle


# ============================================================================
# Delete Vehicle (Admin only - soft delete)
# ============================================================================

@router.delete("/{vehicle_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_vehicle(
    vehicle_id: int,
    session: Session = Depends(get_session),
    current_user: User = Depends(require_admin)
):
    """Deactivate vehicle (soft delete). Admin only."""
    vehicle = session.get(Vehicle, vehicle_id)
    if not vehicle:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Vehicle not found"
        )

    # Soft delete by setting status to inactive
    vehicle.status = "inactive"
    session.add(vehicle)
    session.commit()
