"""
SmartTransport GH — Auth Router
================================
Authentication endpoints: register and login.
"""

from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select

from auth import (
    create_access_token,
    get_password_hash,
    verify_password,
    get_current_user
)
from database import get_session
from models import User, UserRole
from schemas import UserRegister, UserLogin, Token, UserResponse

router = APIRouter(prefix="/auth", tags=["Authentication"])


# ============================================================================
# Register
# ============================================================================

@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register(user_data: UserRegister, session: Session = Depends(get_session)):
    """Register a new user (passenger, driver, or admin)."""
    # Check if phone already exists
    existing_user = session.exec(
        select(User).where(User.phone == user_data.phone)
    ).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Phone number already registered"
        )

    # Check if email already exists (if provided)
    if user_data.email:
        existing_email = session.exec(
            select(User).where(User.email == user_data.email)
        ).first()
        if existing_email:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered"
            )

    # Create user
    new_user = User(
        name=user_data.name,
        phone=user_data.phone,
        email=user_data.email,
        password_hash=get_password_hash(user_data.password),
        role=user_data.role,
        created_at=datetime.utcnow(),
    )
    session.add(new_user)
    session.commit()
    session.refresh(new_user)
    return new_user


# ============================================================================
# Login
# ============================================================================

@router.post("/login", response_model=Token)
async def login(credentials: UserLogin, session: Session = Depends(get_session)):
    """Login and receive JWT token."""
    # Find user by phone
    user = session.exec(
        select(User).where(User.phone == credentials.phone)
    ).first()

    if not user or not verify_password(credentials.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid phone number or password",
            headers={"WWW-Authenticate": "Bearer"}
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User account is deactivated"
        )

    # Create access token
    access_token = create_access_token(
        data={"sub": str(user.id), "role": user.role.value}
    )

    return Token(
        access_token=access_token,
        role=user.role,
        user_id=user.id
    )


# ============================================================================
# Current User
# ============================================================================

@router.get("/me", response_model=UserResponse)
async def get_me(current_user: User = Depends(get_current_user)):
    """Get current authenticated user profile."""
    return current_user
