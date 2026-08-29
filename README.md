# SmartTransport GH 🚌

A public transport management system for Ghana, built with **FastAPI** (backend) and **Flutter** (cross-platform app).

## Features

- **Multi-role support**: Admin, Driver, Passenger
- **Route management** with fare pricing in GHS
- **Live GPS tracking** with WebSocket updates
- **Trip booking** and management
- **Vehicle fleet management**
- **User management** with role-based access

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend | Python, FastAPI, SQLModel, SQLAlchemy |
| Database | SQLite (dev) / PostgreSQL (prod) |
| Auth | JWT with bcrypt password hashing |
| Frontend | Flutter (Web, Android, iOS, Desktop) |
| State | Riverpod |
| HTTP | Dio |

## Quick Start

### Backend

```bash
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
python -c "from database import create_db_and_tables; create_db_and_tables()"
python seed.py
uvicorn main:app --reload --port 8000
```

API docs: http://localhost:8000/docs

### Flutter App

```bash
cd app
flutter pub get
flutter run
```

For web: `flutter run -d chrome --web-port=3000`

## Deploy to Render

1. Push this repo to GitHub
2. Go to [render.com](https://render.com) → New → Blueprint
3. Select your repo — Render auto-detects `render.yaml`
4. Deploy! Your API will be at `https://smarttransport-api.onrender.com`

## Build Flutter Web for Deploy

```bash
cd app
flutter build web --release --dart-define=API_URL=https://smarttransport-api.onrender.com
```

Upload `build/web` to Netlify, Vercel, or any static host.

## Demo Credentials

| Role | Phone | Password |
|------|-------|----------|
| Admin | 0240000001 | admin123 |
| Driver | 0241111111 | driver123 |
| Passenger | 0551111111 | pass1234 |

## Project Structure

```
├── backend/
│   ├── main.py          # FastAPI app entry
│   ├── database.py      # SQLAlchemy/SQLModel setup
│   ├── models.py        # Data models
│   ├── schemas.py       # Pydantic schemas
│   ├── auth.py          # JWT authentication
│   ├── seed.py          # Database seeder
│   └── routers/         # API endpoints
├── app/
│   └── lib/
│       ├── admin/       # Admin dashboard screens
│       ├── driver/      # Driver dashboard screens
│       ├── passenger/   # Passenger dashboard screens
│       └── shared/      # Shared widgets, theme, services
└── render.yaml          # Render.com deployment config
```

## License

Built for educational purposes.
