"""
SmartTransport GH — Database Configuration
=============================================
SQLAlchemy database setup with session management.
"""

from typing import Generator

from sqlmodel import SQLModel, Session, create_engine

# ============================================================================
# Database URL Configuration
# ============================================================================

# SQLite for development
DATABASE_URL = "sqlite:///./smarttransport.db"

# For PostgreSQL in production, uncomment:
# DATABASE_URL = "postgresql://user:password@localhost:5432/smarttransport"

# ============================================================================
# Engine Setup
# ============================================================================

connect_args = {}
if DATABASE_URL.startswith("sqlite"):
    connect_args["check_same_thread"] = False

engine = create_engine(
    DATABASE_URL,
    connect_args=connect_args,
    echo=False  # Set to True for SQL logging in development
)


# ============================================================================
# Database Initialization
# ============================================================================

def create_db_and_tables():
    """Create all database tables from SQLModel metadata."""
    SQLModel.metadata.create_all(engine)


# ============================================================================
# Session Dependency
# ============================================================================

def get_session() -> Generator[Session, None, None]:
    """FastAPI dependency for database sessions."""
    with Session(engine) as session:
        yield session
