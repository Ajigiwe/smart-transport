# SmartTransport GH — Build Prompt & Design Document

## How to use this file
This is written as a master prompt you can feed to an AI coding tool (Claude Code, Cursor, etc.) one phase at a time. Paste the "Project Context" once at the start of a session, then paste each phase in order. Do not skip phases — each one assumes the previous is working.

---

## Project Context (paste this first, every session)

```
I am building SmartTransport GH, a final year project for a BSc in Information
Technology (Software Engineering focus) at Takoradi Technical University, Ghana.

This is a public transport management system with THREE role-based mobile
front ends (Passenger, Driver, Admin) sharing ONE backend API.

Non-negotiable requirements from my supervisor:
1. Full CRUD functionality (not just read-only demos)
2. A native-feeling, polished mobile UI (not a bare web app wrapped in a browser)
3. Proper authentication with role-based access (passenger / driver / admin)
4. A clear, demoable end-to-end flow I can defend live in front of a panel

Tech stack:
- Backend: Python, FastAPI, SQLModel (SQLAlchemy), SQLite for dev / PostgreSQL
  for deployment, JWT auth (python-jose + passlib), WebSockets for live
  location updates
- Frontend: Flutter, one codebase with three build flavors/entry points
  (passenger, driver, admin) sharing models, theme, and API client code
- Maps: flutter_map + OpenStreetMap tiles (avoid Google Maps billing)
- Deployment: Render or Railway for the API, APKs built locally for demo

Design taste: clean, minimal, no gradients, no glassmorphism, no default
Material purple. Think Linear / Stripe / Notion — flat colors, generous
spacing, clear typography, subtle shadows only where needed.

Work with me one phase at a time. After each phase, stop and tell me exactly
how to test what was built before we move to the next phase.
```

---

## Phase 0 — Project Skeleton & Planning
**Goal:** Repo structure and data model agreed before any code.

- Propose a monorepo layout: `/backend` (FastAPI) and `/app` (Flutter, with `lib/passenger`, `lib/driver`, `lib/admin`, `lib/shared`)
- Draft the core data model as SQLModel classes (don't write full logic yet, just fields + relationships):
  - `User` (id, name, phone, email, password_hash, role: passenger/driver/admin, created_at)
  - `Vehicle` (id, plate_number, capacity, driver_id FK, status)
  - `Route` (id, name, start_point, end_point, fare, stops as list)
  - `Trip` (id, route_id FK, driver_id FK, vehicle_id FK, status: scheduled/active/completed/cancelled, started_at, ended_at)
  - `LocationPing` (id, trip_id FK, lat, lng, timestamp) — for live tracking history
  - `Booking`/`TripRequest` (id, trip_id FK, passenger_id FK, status, requested_at)
- Confirm the API route map (list every endpoint with method + path + which role can call it) before writing code.

**Test:** I should end this phase with a written ERD/route map I approve, no runnable code yet.

---

## Phase 1 — Backend Auth & Core CRUD
**Goal:** A working FastAPI backend with registration, login, and full CRUD on Users, Routes, and Vehicles.

- Set up FastAPI project structure (`main.py`, `models.py`, `schemas.py`, `auth.py`, `routers/`)
- Implement JWT auth: `/auth/register`, `/auth/login` (returns access token + role), password hashing with passlib/bcrypt
- Add role-based dependency injection (`get_current_user`, `require_role("admin")`, etc.) to protect routes
- Full CRUD endpoints for:
  - `/users` (admin only for list/delete, self-service for update)
  - `/routes` (admin creates/updates/deletes, everyone can list)
  - `/vehicles` (admin CRUD, driver can view own)
- Auto-generated Swagger docs at `/docs` — this is my live demo tool for the panel, make sure every endpoint is properly tagged and described

**Test:** I should be able to open `/docs`, register an admin user, log in, get a token, and CRUD a route and a vehicle entirely from Swagger.

---

## Phase 2 — Trips, Bookings & WebSocket Live Tracking
**Goal:** The "wow factor" real-time feature that ties the three apps together.

- CRUD endpoints for `Trip` (admin/driver create, driver updates status, passenger lists active trips)
- CRUD endpoints for `Booking`/`TripRequest` (passenger creates, driver/admin views, status updates)
- WebSocket endpoint `/ws/trip/{trip_id}` — driver app sends `{lat, lng}` periodically, all connected passenger clients subscribed to that trip receive broadcasts
- Store each ping in `LocationPing` so there's a history to show in the admin dashboard (proves persistence, not just live magic)
- Basic rate limiting/validation so location spam doesn't break the WebSocket

**Test:** I should be able to open two WebSocket test clients (e.g. in Postman or a simple script), send a location from one, and see it arrive on the other in under a second.

---

## Phase 3 — Flutter Shared Foundation
**Goal:** One Flutter app skeleton with shared theme, API client, and auth flow — before building role-specific screens.

- Set up Flutter project with three entry points (`main_passenger.dart`, `main_driver.dart`, `main_admin.dart`) sharing `lib/shared/`
- Build the design system first: color palette, typography scale, spacing constants, reusable button/input/card widgets — flat, minimal, no default Material look
- Build a shared `ApiClient` (Dio or http package) with token storage (flutter_secure_storage) and automatic auth header injection
- Build shared login/register screens that route to the correct dashboard based on the role returned by the backend
- Set up `flutter_map` with OpenStreetMap and confirm a map renders with a marker

**Test:** I should be able to run all three flavors, log in with the same credentials scheme, and land on an empty "dashboard" screen matching my role, with a map that renders.

---

## Phase 4 — Passenger App Screens
**Goal:** Full passenger flow: browse routes, request a trip, track it live, view history.

- Route list screen (pulled from `/routes`, searchable)
- Active trip screen: shows the driver's live position on the map via WebSocket, ETA if simple to estimate, trip status
- "Request trip" flow: pick a route → confirm → creates a `Booking`
- Trip history screen (past bookings, CRUD: passenger can cancel a pending booking = delete/update)
- Profile screen: view/edit own user info (CRUD: update)

**Test:** Full flow — log in as passenger, browse routes, request a trip, watch a simulated driver location update live on the map, cancel a booking, edit profile.

---

## Phase 5 — Driver App Screens
**Goal:** Driver can manage availability, accept trips, and broadcast location.

- Online/offline toggle (updates `Vehicle`/driver status — CRUD: update)
- Assigned/available trips list, accept a trip (CRUD: update `Trip` status)
- Active trip screen: big "start/end trip" controls, background-ish location broadcast to the WebSocket while active
- Trip completion screen — marks trip completed, shows summary

**Test:** Log in as driver, go online, accept a trip, start it (location starts broadcasting), and confirm it's visible from the passenger app in Phase 4. End the trip.

---

## Phase 6 — Admin App Screens
**Goal:** Full CRUD control panel + oversight dashboard — this is where you visibly satisfy the "CRUD requirement" for the panel.

- Dashboard home: counts (active trips, total drivers, total routes) — simple stat cards
- Routes management: full CRUD table/list UI (create, edit, delete route)
- Vehicles management: full CRUD
- Drivers/Users management: list, view, deactivate (soft delete)
- Live trips view: list of all currently active trips with a map showing all live vehicle positions at once (this reuses your WebSocket work — biggest visual payoff for the defense)
- Trip history/logs screen for auditability

**Test:** Log in as admin, create a route and vehicle, deactivate a user, and — during an active trip from Phases 4/5 — see it appear live on the admin's multi-vehicle map.

---

## Phase 7 — Polish, Seed Data & Defense Rehearsal
**Goal:** Make it look and feel finished, and prep the live demo narrative.

- Add loading states, empty states, and error toasts across all three apps
- Seed script (`seed.py`) that populates realistic Ghanaian route data (e.g. Takoradi–Effia-Nkwanta, Market Circle–TTU) so the demo isn't empty
- App icons + splash screens per flavor so the three APKs look distinct on a phone
- Write out the exact click-by-click defense script:
  1. Admin creates a route + vehicle + assigns driver
  2. Driver logs in, goes online, accepts and starts the trip
  3. Passenger logs in, sees the route, requests it, watches driver move live on the map
  4. Admin dashboard shows the trip live, then completed, in the logs
- Package: exported Postman collection or the `/docs` link, 3 APKs, and a 1-page architecture diagram for the report

**Test:** Full run-through of the defense script end-to-end, timed, at least twice, on real devices (not just emulators) before the actual defense day.

---

## Notes for whoever is running the AI coding tool
- Don't let the AI jump ahead to later phases even if it offers to — confirm each phase works first.
- Keep the WebSocket logic simple; it's the single most impressive and most fragile part of the demo, so avoid over-engineering it.
- If time gets tight, Phases 0–4 (backend + passenger app) are the minimum defensible product; Driver and Admin can be thinner if needed, but all three logins must exist and do at least one real CRUD action each.
