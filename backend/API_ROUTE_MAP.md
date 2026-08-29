# SmartTransport GH — API Route Map

## Overview
Complete API endpoint reference with HTTP methods and role-based access control.

---

## Authentication Endpoints

| Method | Endpoint | Description | Access |
|--------|----------|-------------|--------|
| POST | `/auth/register` | Register new user | Public |
| POST | `/auth/login` | Login and get JWT token | Public |
| GET | `/auth/me` | Get current user profile | Any authenticated user |

---

## User Endpoints

| Method | Endpoint | Description | Access |
|--------|----------|-------------|--------|
| GET | `/users/` | List all users | Admin |
| GET | `/users/{user_id}` | Get user by ID | Admin |
| PATCH | `/users/{user_id}` | Update user profile | Self or Admin |
| DELETE | `/users/{user_id}` | Deactivate user (soft delete) | Admin |

---

## Route Endpoints

| Method | Endpoint | Description | Access |
|--------|----------|-------------|--------|
| GET | `/routes/` | List all active routes | Any authenticated user |
| GET | `/routes/{route_id}` | Get route details | Any authenticated user |
| POST | `/routes/` | Create new route | Admin |
| PATCH | `/routes/{route_id}` | Update route details | Admin |
| DELETE | `/routes/{route_id}` | Deactivate route (soft delete) | Admin |

---

## Vehicle Endpoints

| Method | Endpoint | Description | Access |
|--------|----------|-------------|--------|
| GET | `/vehicles/` | List vehicles | Admin: all, Driver: own only |
| GET | `/vehicles/{vehicle_id}` | Get vehicle details | Admin or assigned Driver |
| POST | `/vehicles/` | Create new vehicle | Admin |
| PATCH | `/vehicles/{vehicle_id}` | Update vehicle details | Admin |
| DELETE | `/vehicles/{vehicle_id}` | Deactivate vehicle (soft delete) | Admin |

---

## Trip Endpoints

| Method | Endpoint | Description | Access |
|--------|----------|-------------|--------|
| GET | `/trips/` | List trips | Admin: all, Driver: own, Passenger: active |
| GET | `/trips/{trip_id}` | Get trip details | Any authenticated user |
| POST | `/trips/` | Create new trip | Admin or Driver (self only) |
| PATCH | `/trips/{trip_id}` | Update trip status | Admin or assigned Driver |
| GET | `/trips/{trip_id}/locations` | Get trip location history | Any authenticated user |
| WebSocket | `/trips/ws/{trip_id}` | Live location tracking | Driver (send), Passenger (receive) |

---

## Booking Endpoints

| Method | Endpoint | Description | Access |
|--------|----------|-------------|--------|
| GET | `/bookings/` | List bookings | Admin: all, Passenger: own |
| GET | `/bookings/{booking_id}` | Get booking details | Admin or owning Passenger |
| POST | `/bookings/` | Create new booking | Passenger only |
| PATCH | `/bookings/{booking_id}` | Update booking status | Passenger: cancel own, Admin/Driver: manage |
| DELETE | `/booking/{booking_id}` | Cancel booking (soft delete) | Passenger: own pending only |

---

## Health Endpoints

| Method | Endpoint | Description | Access |
|--------|----------|-------------|--------|
| GET | `/` | API info | Public |
| GET | `/health` | Health check | Public |

---

## WebSocket Protocol

### `/trips/ws/{trip_id}`

**Client sends (Driver):**
```json
{
  "lat": 5.0012,
  "lng": -1.2345
}
```

**Server broadcasts to all connected clients:**
```json
{
  "type": "location_update",
  "trip_id": 1,
  "lat": 5.0012,
  "lng": -1.2345,
  "timestamp": "2025-08-27T20:00:00Z"
}
```

---

## Data Models

### User
- `id`: int (PK)
- `name`: str
- `phone`: str (unique)
- `email`: str (optional, unique)
- `password_hash`: str
- `role`: enum (passenger/driver/admin)
- `is_active`: bool
- `created_at`: datetime

### Vehicle
- `id`: int (PK)
- `plate_number`: str (unique)
- `capacity`: int (default: 4)
- `driver_id`: int (FK → users.id, optional)
- `status`: enum (active/inactive/maintenance)
- `created_at`: datetime

### Route
- `id`: int (PK)
- `name`: str
- `start_point`: str
- `end_point`: str
- `fare`: float (GHS)
- `stops`: str (JSON list, optional)
- `is_active`: bool
- `created_at`: datetime

### Trip
- `id`: int (PK)
- `route_id`: int (FK → routes.id)
- `driver_id`: int (FK → users.id)
- `vehicle_id`: int (FK → vehicles.id)
- `status`: enum (scheduled/active/completed/cancelled)
- `started_at`: datetime (optional)
- `ended_at`: datetime (optional)
- `created_at`: datetime

### LocationPing
- `id`: int (PK)
- `trip_id`: int (FK → trips.id)
- `lat`: float
- `lng`: float
- `timestamp`: datetime

### Booking
- `id`: int (PK)
- `trip_id`: int (FK → trips.id)
- `passenger_id`: int (FK → users.id)
- `status`: enum (pending/confirmed/cancelled/completed)
- `requested_at`: datetime
- `updated_at`: datetime (optional)

---

## Role Permissions Summary

| Resource | Admin | Driver | Passenger |
|----------|-------|--------|-----------|
| Users | Full CRUD | Read self | Read/Update self |
| Routes | Full CRUD | Read | Read |
| Vehicles | Full CRUD | Read own | - |
| Trips | Full CRUD | CRUD own | Read active |
| Bookings | Full CRUD | Read/Update | CRUD own |
| WebSocket | - | Send location | Receive location |

---

## Swagger Documentation

Access auto-generated API docs at: `http://localhost:8000/docs`
