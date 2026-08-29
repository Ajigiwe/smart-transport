"""
SmartTransport GH — Main Application
======================================
FastAPI application entry point.
"""

from contextlib import asynccontextmanager

from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlmodel import Session, select

from database import create_db_and_tables, get_session
from models import User, Vehicle, Route, Trip, Booking, TripStatus, UserRole
from routers import auth, users, routes, vehicles, trips, bookings


# ============================================================================
# Application Lifespan
# ============================================================================

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Create database tables on startup."""
    create_db_and_tables()
    yield


# ============================================================================
# Create FastAPI App
# ============================================================================

app = FastAPI(
    title="SmartTransport GH",
    description="Public Transport Management System API",
    version="1.0.0",
    lifespan=lifespan
)

# ============================================================================
# CORS Middleware
# ============================================================================

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify exact origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================================================
# Include Routers
# ============================================================================

app.include_router(auth.router)
app.include_router(users.router)
app.include_router(routes.router)
app.include_router(vehicles.router)
app.include_router(trips.router)
app.include_router(bookings.router)


# ============================================================================
# Health Check
# ============================================================================

@app.get("/", tags=["Health"])
async def root():
    return {
        "message": "SmartTransport GH API",
        "docs": "/docs",
        "version": "1.0.0"
    }


@app.get("/health", tags=["Health"])
async def health_check():
    return {"status": "healthy"}


# ============================================================================
# Dashboard Stats
# ============================================================================

@app.get("/dashboard/stats", tags=["Dashboard"])
async def get_dashboard_stats(session: Session = Depends(get_session)):
    """Get dashboard statistics for admin overview."""
    active_trips = len(session.exec(
        select(Trip).where(Trip.status == TripStatus.ACTIVE)
    ).all())
    total_drivers = len(session.exec(
        select(User).where(User.role == UserRole.DRIVER)
    ).all())
    total_routes = len(session.exec(
        select(Route).where(Route.is_active == True)
    ).all())
    total_passengers = len(session.exec(
        select(User).where(User.role == UserRole.PASSENGER)
    ).all())
    total_vehicles = len(session.exec(select(Vehicle)).all())

    return {
        "active_trips": active_trips,
        "total_drivers": total_drivers,
        "total_routes": total_routes,
        "total_passengers": total_passengers,
        "total_vehicles": total_vehicles,
    }


# ============================================================================
# Run Server
# ============================================================================

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )
