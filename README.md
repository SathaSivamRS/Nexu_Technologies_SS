# NEXU RouteRunner — Mobile Delivery Agent Application

NEXU RouteRunner is a mission-critical Flutter mobile application designed for last-mile delivery agents. It provides a robust, offline-first workflow for route dispatching, real-time stop execution, time-window alert monitoring, and asynchronous synchronization with idempotent server protection.

Built according to strict Clean Architecture principles, the application decouples business rules, local persistence, and network synchronization entirely from the presentation layer.

---

## 1. Key Features

- **Authentication & Persistent Session**: Demo credentials (`Asha` / `1234`), 4-digit PIN validation, and restart-safe Hive session persistence.
- **Route Dispatch & Sorting**: Initial route loaded from `assets/data/route_stops.json` (14 realistic stops). Deterministic route ordering based on window start ascending, Urgent priority promotion, and Stop ID tie-breaking.
- **Stop Workflow (R1–R6)**:
  - **R1 (Single Active Stop)**: Only one stop can be in `Arrived` status at a time, enforced strictly in the domain layer.
  - **R2 (Delivered Validation)**: Recipient name mandatory ($\ge 2$ characters), package count matching confirmation.
  - **R3 (Failure Reporting)**: 5 failure reasons with mandatory $\ge 10$-character note for `Other`.
  - **R4 (Retry & Escalation)**: 1st failure moves the stop to the route end for retry; 2nd failure transitions to `Returned to hub` (final locked status).
  - **R5 (60-Second Real-Elapsed Undo)**: Visible real-time countdown; recalculates elapsed time accurately even across app restarts.
  - **R6 (Urgent Stop Protection)**: Rejects `Customer absent` before window start time, checked against the Demo Clock.
- **Demo Clock & Time Alerts**: Simulated clock with custom date/time pickers and quick adjustment shortcuts. Real-time alert classification:
  - **Normal**: $> 15$ minutes remain before window end.
  - **At risk**: $\le 15$ minutes remain before window end.
  - **Late**: Past window end time (Delivered and Returned stops are excluded).
- **Offline-First Synchronization (S1–S7)**:
  - **S1 (Optimistic UI)**: Local mutation and queue persistence happen before any network attempt; instant UI feedback.
  - **S2 (Sync Status)**: Synced (Green), Pending (Grey), Retrying (Orange), Needs Attention (Red) with per-stop status aggregation.
  - **S3 (Exponential Backoff)**: Retries scheduled at 2s, 4s, and 8s intervals; moves to `Needs attention` after 3 retries; manual retry option.
  - **S4 (Per-Stop FIFO Ordering)**: Actions for the same stop execute strictly in sequence number order; retrying head action blocks subsequent actions for that stop without affecting unrelated stops.
  - **S5 (Duplicate Protection / Idempotency)**: Persistent UUID request IDs ensure duplicate requests return original success without double execution.
  - **S6 (Offline Mode)**: Toggle in Settings simulates complete network disconnection; queues actions and auto-resumes processing upon reconnection.
  - **S7 (Restart Safety)**: Queued unacknowledged actions survive app kills and resume synchronization on launch.
- **Daily Performance Summary**: Interactive KPIs for Success Rate %, On-Time Rate %, breakdown of delivered/failed/returned stops, and actionable unsynced queue list with manual retry.

---

## 2. Technology Stack & Versions

- **Flutter**: 3.41.6 (Channel stable)
- **Dart**: 3.11.4
- **State Management**: `flutter_riverpod: ^2.5.1`
- **Local Persistence**: `hive: ^2.2.3`, `hive_flutter: ^1.1.0`
- **Unique Request IDs**: `uuid: ^4.6.0`
- **Date/Time Formatting**: `intl: ^0.19.0`
- **Design System**: Material 3 with Logistics Color Palette (Deep Navy `#0F172A`, Blue `#2563EB`, Success Green `#10B981`, Warning Orange `#F59E0B`, Error Red `#EF4444`, Neutral `#F8FAFC`).

---

## 3. Project Architecture

```
lib/
  main.dart                               # Hive initialization & App bootstrap
  app/
    app.dart                              # Root MaterialApp & auth-state routing
    home_navigation_shell.dart            # BottomNavigationBar shell (4 tabs)
    theme.dart                            # Material 3 Logistics Theme
  core/
    constants/app_constants.dart          # Configuration constants & box names
    enums/                                # Status, priority, failure, sync enums
    errors/failures.dart                  # Domain exceptions (Workflow, Validation)
    providers/core_providers.dart         # Hive boxes & ClockService providers
    services/clock_service.dart           # Centralized injectable Demo Clock
    utils/date_time_formatter.dart        # Window & time formatting helpers
  features/
    authentication/                       # Auth session data, domain & UI
    route_management/                     # Stops repository, sorter & alert evaluator
    stop_workflow/                        # WorkflowService (R1-R6) & sheets
    synchronization/                      # MockServer, SyncEngine, RetryPolicy, Queue
    settings/                             # Settings & diagnostics screen
    summary/                              # Daily Summary KPIs & unsynced queue UI
    about/                                # Developer & assessment metadata
assets/
  data/route_stops.json                   # Initial route data (14 realistic stops)
test/
  unit/                                   # 16 automated unit tests
```

### Layer Responsibilities
1. **Presentation Layer**: Flutter widgets and screens listening to Riverpod providers. Contains **zero** business logic or direct persistence code.
2. **Domain Layer**: Pure Dart entities and services (`WorkflowService`, `RouteSorter`, `TimeAlertEvaluator`, `RetryPolicy`, `RequestProcessor`, `SyncEngine`). Handles validations, state transitions, and sequencing.
3. **Data Layer**: Repositories and datasources (`RouteRepositoryImpl`, `RouteLocalDataSourceImpl`, `SyncQueueStorageImpl`, `MockServer`). Handles serialization, Hive storage, and simulated server latency.
4. **Core Layer**: Cross-cutting utilities, error types, constants, and the `ClockService`.

---

## 4. Setup and Installation

### Prerequisites
- Flutter SDK 3.x or higher installed and added to `PATH`.
- Dart SDK 3.x or higher.
- Java JDK 17+ and Android SDK for Android builds.

### Step-by-Step Installation
```bash
# 1. Clone or open repository
cd Nexu_SS

# 2. Fetch dependencies
flutter pub get

# 3. Analyze code for static issues
flutter analyze

# 4. Run automated test suite
flutter test

# 5. Run application
flutter run
```

---

## 5. Building the Release APK

To compile the standalone production release APK:

```bash
flutter build apk --release
```

The compiled release APK is generated at:
```
build/app/outputs/flutter-apk/app-release.apk
```
*(Exact size: ~50.4 MB, built with tree-shaken icons and optimized release AOT).*

---

## 6. How to Test Every Feature in the App

1. **Sign In**:
   - Tap **"Use Demo Credentials"** (or type `Asha` and PIN `1234`).
   - Tap **Sign In**. Session will persist across app restarts.
2. **Stop Workflow (R1, R2, R3, R4, R5, R6)**:
   - On the Route dashboard, tap **"Mark Arrived"** on `STOP-001`. It turns into the active stop.
   - Try tapping **"Mark Arrived"** on `STOP-002`: the app will prevent it and explain that `STOP-001` is already active (R1).
   - Tap **"Complete"** on `STOP-001`: confirmation sheet appears requiring recipient name ($\ge 2$ characters) and matching package count (R2).
   - Once completed, observe the **60-second real-time countdown** banner. Tap **"Undo"** within 60s to revert it back to Arrived (R5).
   - Tap **"Failed"** on a stop: select one of the 5 reasons. If selecting `Other`, you must provide a note of at least 10 characters (R3).
   - On 1st failure, the stop moves to the end of the route as a retry (R4). On 2nd failure, it transitions to `Returned to hub` and locks permanently (R4).
   - Open Settings, set the Demo Clock to `08:45 AM`, go to Urgent stop `STOP-002` (window 09:00–10:00), arrive and try to report `Customer absent`: the app will strictly block it (R6).
3. **Offline Sync & Mock Server (S1–S7)**:
   - Open Settings, toggle **Offline Mode** ON.
   - Return to the route and perform deliveries or arrivals: UI updates immediately (S1).
   - Look at the top bar or Summary screen: actions queue up as pending offline operations.
   - Turn **Offline Mode** OFF: queued actions automatically resume and sync in order without manual intervention (S6).
   - In Settings, slide the **Simulated Failure Rate** to 100% to test exponential backoff (2s, 4s, 8s) and escalation to `Needs attention` (S3).
4. **Summary & Performance KPIs**:
   - Navigate to the **Summary** tab to inspect Success Rate %, On-Time Rate %, breakdown counts, and the unsynced queue table with manual retry buttons.
5. **About Screen**:
   - Navigate to the **About** tab to verify developer details (`Sathasivam R S`), company (`NEXU Technologies Private Limited`), role, and submission date (`11 November 2026`).

---

## 7. Automated Test Suite

Run the full suite using:
```bash
flutter test
```

### Covered Test Cases (16 Tests)
- `test/unit/workflow_test.dart`:
  - Test 1 (R1): Only one active stop permitted at a time.
  - Test 2 (R2): Delivered validation (name $\ge 2$ chars, package count equal and not exceeding).
  - Test 3 (R4): Failed stop moved to route end; second failure transitions to `Returned to hub`.
  - Test 4 (R6): Urgent stop rejects `Customer absent` before window start time.
  - Test R5: 60-second delivery undo eligibility, restoration, and post-60s locking.
  - Test R3: "Other" failure reason mandates $\ge 10$-character note.
- `test/unit/sync_engine_test.dart`:
  - Test 5 (S3): Retry delays of 2, 4, 8 seconds and transition to `Needs attention`.
  - Test 6 (S4): Per-stop actions never processed out of order; head action blocks later actions.
  - Test 7 (S5): Duplicate request IDs applied only once (idempotency).
  - Test 8 (S7): Queued actions survive app restart and resume synchronization.
  - Test S6: Offline mode blocks sync, retains queue, and auto-syncs on reconnect.
- `test/unit/time_alert_and_sorting_test.dart`:
  - RouteSorter ordering (window start asc, Urgent before Normal, deterministic ID).
  - RouteSorter retries moved to end.
  - TimeAlertEvaluator (Normal $> 15$m, At risk $\le 15$m, Late $> \text{windowEnd}$).
  - Delivered and Returned stops excluded from Late alert.
- `test/widget_test.dart`:
  - Smoke test for route sorting.

---

## 8. Known Limitations

- **Simulated Backend**: As explicitly requested by the recruitment assessment, no external HTTP backend is contacted; all networking, latency, and failure rates are faithfully simulated locally in Dart.
- **Push Notifications**: Per section 1 requirements, local notifications are not implemented.
