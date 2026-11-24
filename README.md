# 🌙 iMoon — Period Tracker

Local-first menstrual cycle tracker. Data stays on your device.

## Stack
- **Flutter** (iOS + Android + Web)
- **Drift** (SQLite, local)
- **Riverpod** (state)

## Setup

### 1. Install Flutter
```
# Put Flutter SDK on E: to save C: space
# Download: https://docs.flutter.dev/get-started/install
# Set env: FLUTTER_ROOT=E:\flutter
```

### 2. Get dependencies
```bash
flutter pub get
```

### 3. Generate Drift code (required before first run)
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. Run
```bash
flutter run                 # connected device or emulator
flutter run -d chrome       # web
```

## Project structure
```
lib/
  main.dart               Entry point
  app.dart                MaterialApp + bottom navigation shell
  theme.dart              iMoon dark theme, colours, phase helpers
  data/
    database.dart         Drift schema (Cycles, DailyLogs, AppSettings)
    database.g.dart       Generated — do not edit
  logic/
    cycle_calculator.dart Prediction algorithm, phase detection, day types
  providers/
    providers.dart        Riverpod providers + CycleActions
  screens/
    home/                 Today view: moon dial, phase, quick actions
    calendar/             Month calendar with colour-coded days
    log/                  Daily log bottom sheet (flow, mood, symptoms)
    insights/             Charts and cycle history
    settings/             Notifications, data management
  widgets/
    moon_dial.dart        Circular cycle progress dial
    flow_selector.dart    Flow intensity picker
    tag_chip_group.dart   Multi-select mood/symptom chips
```

## Phase roadmap
- [x] Phase 1 — Core solo app (cycle logging, predictions, calendar, log)
- [ ] Phase 2 — Notifications, onboarding, export
- [ ] Phase 3 — Couple/group sync via optional backend
