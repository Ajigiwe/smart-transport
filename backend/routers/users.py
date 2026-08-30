"""
SmartTransport GH — Users Router
==================================
User management endpoints: CRUD operations.
"""

from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select

from auth import get_current_user, require_admin, require_role
from database import get_session
from models import User, UserRole
from schemas import UserResponse, UserUpdate

router = APIRouter(prefix="/users", tags=["Users"])


# ============================================================================
# List Users (Admin only)
# ============================================================================

@router.get("/", response_model=List[UserResponse])
async def list_users(
    role: Optional[UserRole] = None,
    session: Session = Depends(get_session),
    current_user: User = Depends(require_admin)
):
    """List all users. Admin only."""
    query = select(User)
    if role:
        query = query.where(User.role == role)
    users = session.exec(query).all()
    return users


# ============================================================================
# Get User by ID
# ============================================================================

@router.get("/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: int,
    session: Session = Depends(get_session),
    current_user: User = Depends(require_admin)
):
    """Get user by ID. Admin only."""
    user = session.get(User, user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    return user


# ============================================================================
# Update User (Self or Admin)
# ============================================================================

@router.patch("/{user_id}", response_model=UserResponse)
async def update_user(
    user_id: int,
    update_data: UserUpdate,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user)
):
    """Update user profile. Users can update their own profile; admins can update any."""
    # Check permissions
    if current_user.role != UserRole.ADMIN and current_user.id != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Can only update your own profile"
        )

    user = session.get(User, user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    # Only admins can change active status
    update_dict = update_data.model_dump(exclude_unset=True)
    if "is_active" in update_dict and current_user.role != UserRole.ADMIN:
        del update_dict["is_active"]

    # Apply updates
    for key, value in update_dict.items():
        setattr(user, key, value)

    session.add(user)
    session.commit()
    session.refresh(user)
    return user


# ============================================================================
# Delete User (Admin only - soft delete)
# ============================================================================

@router.delete("/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user(
    user_id: int,
    session: Session = Depends(get_session),
    current_user: User = Depends(require_admin)
):
    """Deactivate user (soft delete). Admin only."""
    user = session.get(User, user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    # Soft delete by deactivating
    user.is_active = False
    session.add(user)
    session.commit()


# ============================================================================
# Driver Online Status
# ============================================================================

@router.patch("/me/online", response_model=UserResponse)
async def set_online_status(
    body: dict,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user)
):
    """Set driver online status."""
    if current_user.role != UserRole.DRIVER:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only drivers can toggle online status"
        )
    current_user.is_online = body.get("is_online", not current_user.is_online)
    session.add(current_user)
    session.commit()
    session.refresh(current_user)
    return current_user
