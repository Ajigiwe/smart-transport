# SmartTransport GH - Flutter App

A Flutter mobile application for SmartTransport GH public transport management system.

## Project Structure

```
app/
├── lib/
│   ├── main_passenger.dart      # Passenger app entry point
│   ├── main_driver.dart         # Driver app entry point
│   ├── main_admin.dart          # Admin app entry point
│   ├── shared/
│   │   ├── models/              # Data models
│   │   ├── services/            # API client, auth, storage
│   │   ├── theme/               # Colors, typography, spacing
│   │   ├── widgets/             # Reusable UI components
│   │   └── screens/             # Shared screens (login, register, dashboard)
│   ├── passenger/
│   │   └── screens/             # Passenger-specific screens
│   ├── driver/
│   │   └── screens/             # Driver-specific screens
│   └── admin/
│       └── screens/             # Admin-specific screens
└── assets/
    ├── images/                  # App images
    └── icons/                   # App icons
```

## Getting Started

### Prerequisites

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Backend API running on localhost:8000

### Installation

1. Install dependencies:
   ```bash
   cd app
   flutter pub get
   ```

2. Run the app:
   ```bash
   # Passenger app
   flutter run -t lib/main_passenger.dart
   
   # Driver app
   flutter run -t lib/main_driver.dart
   
   # Admin app
   flutter run -t lib/main_admin.dart
   ```

### Building APKs

```bash
# Passenger APK
flutter build apk -t lib/main_passenger.dart --release

# Driver APK
flutter build apk -t lib/main_driver.dart --release

# Admin APK
flutter build apk -t lib/main_admin.dart --release
```

## Design System

### Colors

- Primary: `#1A1A2E` (Dark navy)
- Accent: `#00D4AA` (Teal green)
- Passenger: `#4ECDC4` (Cyan)
- Driver: `#FFB800` (Amber)
- Admin: `#9B59B6` (Purple)

### Typography

- Font: Inter (Google Fonts)
- Clean, minimal styling
- Consistent spacing scale (4px base)

### Design Principles

- Flat colors, no gradients
- Generous whitespace
- Subtle shadows only where needed
- No default Material purple
- Inspired by Linear / Stripe / Notion

## Features

### Shared

- JWT authentication with secure token storage
- Role-based access control
- Shared API client with Dio
- Consistent design system
- Reusable UI components

### Passenger

- Browse available routes
- Request and book trips
- Track live driver location on map
- View trip history
- Manage profile

### Driver

- Online/offline status toggle
- View and accept trip requests
- Broadcast live location
- Start/end trips
- View earnings and history

### Admin

- Dashboard with statistics
- Manage routes (CRUD)
- Manage vehicles (CRUD)
- Manage users (CRUD)
- Live tracking map with all vehicles

## Tech Stack

- **State Management:** Riverpod
- **HTTP Client:** Dio
- **Secure Storage:** flutter_secure_storage
- **Maps:** flutter_map + OpenStreetMap
- **UI:** Material Design 3 (customized)

## API Integration

The app connects to the SmartTransport GH backend API:

- Base URL: `http://localhost:8000`
- Authentication: JWT Bearer tokens
- WebSocket: Live location tracking

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

## Deployment

### Android

1. Build release APK:
   ```bash
   flutter build apk --release
   ```

2. APK location:
   ```
   build/app/outputs/flutter-apk/app-release.apk
   ```

### iOS

1. Build for iOS:
   ```bash
   flutter build ios --release
   ```

2. Archive in Xcode for App Store submission

## Troubleshooting

### Common Issues

1. **API Connection Error**
   - Ensure backend is running on localhost:8000
   - Check CORS settings on backend
   - Verify network permissions in AndroidManifest.xml

2. **Map Not Loading**
   - Check internet connection
   - Verify OpenStreetMap tile URL is accessible

3. **Token Issues**
   - Clear app data and login again
   - Check backend JWT configuration

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is part of a BSc final year project at Takoradi Technical University.
