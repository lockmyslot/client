# Lock My Slot — Flutter Client

Cross-platform mobile and web client for the Lock My Slot resource booking platform, built with Flutter, Riverpod, and Material 3 with Dynamic Color.

---

## Features

- **Auth**: Token persistence, username/password login, and registration.
- **Groups**: Create groups, join existing groups via 6-character invite codes, and manage members.
- **Resources**: Browse resources, view capacities, and inspect booking rules.
- **Booking Matrix & Slot Picker**: Visual time slot selection, real-time availability checks, quota tracking, and booking cancellation.
- **Maintenance Tasks**: View resource maintenance schedules, track task statuses, and assign tasks.
- **Deep Linking**: Seamless deep-link routing with authentication guards and post-login redirection.
- **Offline Caching**: Cached view of user bookings and group data when offline.

---

## Prerequisites

- **Flutter SDK**: 3.24.x or higher
- **Dart SDK**: 3.5.x or higher
- **Android Studio / Xcode** (for mobile development)

---

## Setup & Running

```bash
# 1. Install dependencies
flutter pub get

# 2. Generate Riverpod and JSON serialization code
dart run build_runner build --delete-conflicting-outputs

# 3. Run the application
flutter run
```

To run on a specific platform:
```bash
flutter run -d chrome     # Web
flutter run -d android    # Android device / emulator
flutter run -d ios        # iOS simulator
flutter run -d linux      # Linux desktop
```

---

## Testing

```bash
# Run unit and widget tests
flutter test
```

---

## Architecture

- **State Management**: `flutter_riverpod` with code-generated notifiers.
- **Navigation**: `go_router` with declarative redirect guards.
- **Theme**: Adaptive Material 3 design supporting system light/dark mode and `dynamic_color`.
- **API Client**: HTTP wrapper interfacing with the NestJS backend at `/api/v1`.

For more details on domain logic and system capabilities, see:
[Functional Specification](docs/FUNCTIONAL_SPECIFICATION.md)
