"""
SmartTransport GH — Database Seed Script
==========================================
Populates the database with realistic Ghanaian transport data.
Run: cd backend && py -3.12 seed.py
"""

import sys
from datetime import datetime, timedelta, timezone
from sqlmodel import SQLModel, Session, select

from database import engine, create_db_and_tables
from models import (
    User, Vehicle, Route, Trip, Booking, LocationPing,
    UserRole, VehicleStatus, TripStatus, BookingStatus,
)
from auth import get_password_hash


def seed():
    create_db_and_tables()

    with Session(engine) as session:
        # Check if already seeded
        existing_users = session.exec(select(User)).all()
        if len(existing_users) > 2:
            print("Database already seeded. Skipping.")
            return

        print("[*] Seeding database...")

        # ── Admin ──────────────────────────────────────────────
        admin = User(
            name="Admin User",
            phone="0240000001",
            email="admin@smarttransport.gh",
            password_hash=get_password_hash("admin123"),
            role=UserRole.ADMIN,
        )
        session.add(admin)

        # ── Drivers ────────────────────────────────────────────
        drivers_data = [
            ("Kwame Asante", "0241111111", "kwame@driver.gh"),
            ("Ama Mensah", "0242222222", "ama@driver.gh"),
            ("Kofi Boateng", "0243333333", "kofi@driver.gh"),
            ("Abena Osei", "0244444444", "abena@driver.gh"),
            ("Yaw Mensah", "0245555555", "yaw@driver.gh"),
            ("Kojo Frimpong", "0246666666", "kojo@driver.gh"),
        ]
        drivers = []
        for name, phone, email in drivers_data:
            d = User(
                name=name,
                phone=phone,
                email=email,
                password_hash=get_password_hash("driver123"),
                role=UserRole.DRIVER,
            )
            session.add(d)
            drivers.append(d)

        # ── Passengers ─────────────────────────────────────────
        passengers_data = [
            ("Nana Agyeman", "0551111111", "nana@passenger.gh"),
            ("Efua Asare", "0552222222", "efua@passenger.gh"),
            ("Kwesi Mensah", "0553333333", "kwesi@passenger.gh"),
            ("Ama Darko", "0554444444", "ama.p@passenger.gh"),
            ("Kofi Amoako", "0555555555", "kofi.p@passenger.gh"),
            ("Adwoa Boakye", "0556666666", "adwoa@passenger.gh"),
            ("Yaw Boateng", "0557777777", "yaw.p@passenger.gh"),
            ("Abena Osei", "0558888888", "abena.p@passenger.gh"),
        ]
        passengers = []
        for name, phone, email in passengers_data:
            p = User(
                name=name,
                phone=phone,
                email=email,
                password_hash=get_password_hash("pass1234"),
                role=UserRole.PASSENGER,
            )
            session.add(p)
            passengers.append(p)

        session.flush()  # get IDs

        # ── Routes ─────────────────────────────────────────────
        routes_data = [
            {
                "name": "Takoradi - Effia Nkwanta",
                "start_point": "Takoradi Station",
                "end_point": "Effia Nkwanta",
                "fare": 5.00,
                "stops": "Market Circle,Sekondi Junction,Junction Road",
            },
            {
                "name": "Market Circle - TTU",
                "start_point": "Market Circle",
                "end_point": "Takoradi Technical University",
                "fare": 3.00,
                "stops": "Harbour Road,Beach Road,Kaneshie First Light",
            },
            {
                "name": "Takoradi - Shama",
                "start_point": "Takoradi Station",
                "end_point": "Shama",
                "fare": 8.00,
                "stops": "Abuesi,Bridge,Saltpond Road",
            },
            {
                "name": "Effia Nkwanta - Airport",
                "start_point": "Effia Nkwanta",
                "end_point": "Takoradi Airport",
                "fare": 12.00,
                "stops": "Kojokrom,Anaji,Airport Junction",
            },
            {
                "name": "Market Circle - Adiembra",
                "start_point": "Market Circle",
                "end_point": "Adiembra",
                "fare": 4.00,
                "stops": "Sekondi Road,Whindy Junction",
            },
            {
                "name": "Takoradi - Cape Coast (Express)",
                "start_point": "Takoradi Station",
                "end_point": "Cape Coast Station",
                "fare": 45.00,
                "stops": "Elmina,Senya Breku",
            },
            {
                "name": "Accra - Kumasi (VIP)",
                "start_point": "Circle VIP Terminal, Accra",
                "end_point": "Kejetia Terminal, Kumasi",
                "fare": 150.00,
                "stops": "Nsawam,Nkawkaw,Techiman",
            },
            {
                "name": "Accra - Takoradi (STC)",
                "start_point": "Tudu Station, Accra",
                "end_point": "Takoradi Station",
                "fare": 80.00,
                "stops": "Winneba,Mankessim,Sekondi",
            },
            {
                "name": "Kumasi - Tamale (Overnight)",
                "start_point": "Kejetia Terminal, Kumasi",
                "end_point": "Central Bus Station, Tamale",
                "fare": 200.00,
                "stops": "Ejisu,New Juaben,Bawku",
            },
            {
                "name": "Takoradi - Butre",
                "start_point": "Takoradi Station",
                "end_point": "Butre",
                "fare": 10.00,
                "stops": "Axim,Akwidaa,Lower Discord",
            },
        ]
        routes = []
        for rd in routes_data:
            r = Route(**rd)
            session.add(r)
            routes.append(r)

        session.flush()

        # ── Vehicles ───────────────────────────────────────────
        vehicles_data = [
            ("GR-1234-22", 14, drivers[0].id, VehicleStatus.ACTIVE),
            ("GR-5678-21", 14, drivers[1].id, VehicleStatus.ACTIVE),
            ("GR-9012-23", 7,  drivers[2].id, VehicleStatus.ACTIVE),
            ("GR-3456-20", 14, drivers[3].id, VehicleStatus.ACTIVE),
            ("GR-7890-22", 4,  drivers[4].id, VehicleStatus.ACTIVE),
            ("GR-2468-23", 14, drivers[5].id, VehicleStatus.MAINTENANCE),
        ]
        vehicles = []
        for plate, cap, driver_id, status in vehicles_data:
            v = Vehicle(
                plate_number=plate,
                capacity=cap,
                driver_id=driver_id,
                status=status,
            )
            session.add(v)
            vehicles.append(v)

        session.flush()

        # ── Trips ──────────────────────────────────────────────
        now = datetime.now(timezone.utc)
        trips_data = [
            # Active trips
            (routes[0], drivers[0], vehicles[0], TripStatus.ACTIVE, now - timedelta(hours=1), None),
            (routes[1], drivers[1], vehicles[1], TripStatus.ACTIVE, now - timedelta(minutes=30), None),
            (routes[6], drivers[0], vehicles[0], TripStatus.ACTIVE, now - timedelta(hours=3), None),
            # Scheduled trips
            (routes[2], drivers[2], vehicles[2], TripStatus.SCHEDULED, None, None),
            (routes[3], drivers[3], vehicles[3], TripStatus.SCHEDULED, None, None),
            (routes[4], drivers[4], vehicles[4], TripStatus.SCHEDULED, None, None),
            (routes[7], drivers[1], vehicles[1], TripStatus.SCHEDULED, None, None),
            # Completed trips
            (routes[0], drivers[0], vehicles[0], TripStatus.COMPLETED, now - timedelta(days=1, hours=2), now - timedelta(days=1, hours=1)),
            (routes[1], drivers[1], vehicles[1], TripStatus.COMPLETED, now - timedelta(days=1, hours=5), now - timedelta(days=1, hours=4)),
            (routes[5], drivers[2], vehicles[2], TripStatus.COMPLETED, now - timedelta(days=2, hours=3), now - timedelta(days=2)),
            (routes[6], drivers[3], vehicles[3], TripStatus.COMPLETED, now - timedelta(days=3, hours=6), now - timedelta(days=3, hours=1)),
            (routes[0], drivers[4], vehicles[4], TripStatus.COMPLETED, now - timedelta(days=4, hours=1), now - timedelta(days=4)),
            (routes[8], drivers[0], vehicles[0], TripStatus.COMPLETED, now - timedelta(days=5, hours=8), now - timedelta(days=5)),
            # Cancelled
            (routes[9], drivers[2], vehicles[2], TripStatus.CANCELLED, None, None),
        ]
        trips = []
        for route, driver, vehicle, status, started, ended in trips_data:
            t = Trip(
                route_id=route.id,
                driver_id=driver.id,
                vehicle_id=vehicle.id,
                status=status,
                started_at=started,
                ended_at=ended,
            )
            session.add(t)
            trips.append(t)

        session.flush()

        # ── Bookings ───────────────────────────────────────────
        active_trips = [t for t in trips if t.status == TripStatus.ACTIVE]
        completed_trips = [t for t in trips if t.status == TripStatus.COMPLETED]

        bookings = []
        for trip in active_trips:
            for p in passengers[:3]:
                b = Booking(
                    trip_id=trip.id,
                    passenger_id=p.id,
                    status=BookingStatus.CONFIRMED,
                )
                session.add(b)
                bookings.append(b)

        for trip in completed_trips[:5]:
            b = Booking(
                trip_id=trip.id,
                passenger_id=passengers[0].id,
                status=BookingStatus.COMPLETED,
            )
            session.add(b)
            bookings.append(b)

        # Some pending bookings
        for trip in [t for t in trips if t.status == TripStatus.SCHEDULED][:3]:
            b = Booking(
                trip_id=trip.id,
                passenger_id=passengers[1].id,
                status=BookingStatus.PENDING,
            )
            session.add(b)
            bookings.append(b)

        # ── Location Pings (for active trips) ──────────────────
        for trip in active_trips:
            base_lat = 4.8989
            base_lng = -1.7600
            for i in range(5):
                ping = LocationPing(
                    trip_id=trip.id,
                    lat=base_lat + (i * 0.002),
                    lng=base_lng + (i * 0.003),
                    timestamp=trip.started_at + timedelta(minutes=i * 2) if trip.started_at else now,
                )
                session.add(ping)

        session.commit()

        # ── Summary ────────────────────────────────────────────
        print(f"  [OK] Admin:      1 (phone: 0240000001, pw: admin123)")
        print(f"  [OK] Drivers:    {len(drivers)} (phone: 024xxxxxxx, pw: driver123)")
        print(f"  [OK] Passengers: {len(passengers)} (phone: 055xxxxxxx, pw: pass1234)")
        print(f"  [OK] Routes:     {len(routes)}")
        print(f"  [OK] Vehicles:   {len(vehicles)}")
        print(f"  [OK] Trips:      {len(trips)} (3 active, 4 scheduled, 5 completed, 1 cancelled)")
        print(f"  [OK] Bookings:   {len(bookings)}")
        print(f"  [OK] Location pings: {5 * len(active_trips)}")
        print()
        print("[SEEDED] Database seeded successfully!")


if __name__ == "__main__":
    seed()
