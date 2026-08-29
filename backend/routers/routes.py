"""
SmartTransport GH — Routes Router
===================================
Transport route management endpoints: CRUD operations.
"""

from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select

from auth import get_current_user, require_admin, require_any_role
from database import get_session
from models import Route, User
from schemas import RouteCreate, RouteUpdate, RouteResponse

router = APIRouter(prefix="/routes", tags=["Routes"])


# ============================================================================
# List Routes (All authenticated users)
# ============================================================================

@router.get("/", response_model=List[RouteResponse])
async def list_routes(
    session: Session = Depends(get_session),
    current_user: User = Depends(require_any_role)
):
    """List all active routes. Available to all authenticated users."""
    routes = session.exec(select(Route).where(Route.is_active == True)).all()
    return routes


# ============================================================================
# Get Route by ID
# ============================================================================

@router.get("/{route_id}", response_model=RouteResponse)
async def get_route(
    route_id: int,
    session: Session = Depends(get_session),
    current_user: User = Depends(require_any_role)
):
    """Get route details by ID."""
    route = session.get(Route, route_id)
    if not route:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Route not found"
        )
    return route


# ============================================================================
# Create Route (Admin only)
# ============================================================================

@router.post("/", response_model=RouteResponse, status_code=status.HTTP_201_CREATED)
async def create_route(
    route_data: RouteCreate,
    session: Session = Depends(get_session),
    current_user: User = Depends(require_admin)
):
    """Create a new transport route. Admin only."""
    new_route = Route(**route_data.model_dump())
    session.add(new_route)
    session.commit()
    session.refresh(new_route)
    return new_route


# ============================================================================
# Update Route (Admin only)
# ============================================================================

@router.patch("/{route_id}", response_model=RouteResponse)
async def update_route(
    route_id: int,
    update_data: RouteUpdate,
    session: Session = Depends(get_session),
    current_user: User = Depends(require_admin)
):
    """Update route details. Admin only."""
    route = session.get(Route, route_id)
    if not route:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Route not found"
        )

    # Apply updates
    update_dict = update_data.model_dump(exclude_unset=True)
    for key, value in update_dict.items():
        setattr(route, key, value)

    session.add(route)
    session.commit()
    session.refresh(route)
    return route


# ============================================================================
# Delete Route (Admin only - soft delete)
# ============================================================================

@router.delete("/{route_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_route(
    route_id: int,
    session: Session = Depends(get_session),
    current_user: User = Depends(require_admin)
):
    """Deactivate route (soft delete). Admin only."""
    route = session.get(Route, route_id)
    if not route:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Route not found"
        )

    # Soft delete by deactivating
    route.is_active = False
    session.add(route)
    session.commit()
