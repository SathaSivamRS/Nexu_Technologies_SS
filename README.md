# NEXU RouteRunner — Offline-First Delivery Mobile Application

**NEXU RouteRunner** is a mission-critical, offline-first mobile application built for last-mile delivery agents. It provides a robust workflow for route dispatching, real-time stop execution, time-window alert monitoring, and asynchronous synchronization with idempotent server protection.

The application is engineered strictly according to **Clean Architecture** principles and production-grade state management with Riverpod, completely separating domain business rules, offline persistence, and synchronization logic from the presentation layer.

---

## 1. Project Title and Overview

- **Application Name**: NEXU RouteRunner
- **Package Identifier**: `com.nexu.routerunner.nexu_routerunner`
- **Application Version**: `1.0.0+1`
- **Candidate / Developer**: Sathasivam R S
- **Company**: NEXU Technologies Private Limited
- **Assessment**: Application Developer Intern – Mobile Applications
- **Submission Date**: 11 November 2026

The application empowers delivery agents to execute their entire daily delivery shift in challenging real-world logistics environments (basements, elevators, remote dead-zones) where network connectivity is intermittent or unavailable. All route updates are persisted locally before transmission, actions are queued with deterministic FIFO sequence numbers, and synchronization resumes automatically with exponential backoff and duplicate protection.

---

## 2. Assessment Objective

The objective of this technical recruitment assessment is to design, implement, test, and document a fully functional Flutter mobile application demonstrating:
- Strict implementation of domain business rules (**R1–R6**).
- Reliable offline-first persistence and asynchronous synchronization (**S1–S7**).
- Clean Architecture with decoupled Presentation, Domain, Data, and Core layers.
- Robust state management with Riverpod and local persistence with Hive.
- Restart safety, in-flight network recovery, and idempotency guarantees.
- Comprehensive automated test coverage and release APK compilation.

---

## 3. Key Features

- **Authentication & Restart-Safe Session**:
  - Demo authentication with validation and persistent session restored from Hive across app restarts.
  - Graceful Sign Out clearing active session while preserving local delivery data.
- **Route Dispatching & Local Bootstrapping**:
  - One-time initial loading from `assets/data/route_stops.json` (14 realistic stops) into persistent Hive storage.
  - Deterministic sorting by delivery window start time ascending, Urgent priority promotion, and Stop ID tie-breaking.
  - Failed retry stops automatically placed at the end of the route.
- **Stop Workflow Execution (R1–R6)**:
  - Single active stop restriction (`Arrived`).
  - Recipient name verification and mandatory package count matching.
  - Five structured failure reasons with mandatory note validation for `Other`.
  - Automatic retry rescheduling on 1st failure and permanent locking (`Returned to hub`) on 2nd failure.
  - 60-second real-elapsed delivery Undo window calculated against stored timestamps.
  - Urgent delivery window protection against premature absence reporting.
- **Offline-First Synchronization Engine (S1–S7)**:
  - Optimistic UI updates with persist-before-send reliability.
  - Live status indicators: Synced (Green), Pending (Grey), Retrying (Orange), and Needs Attention (Red).
  - Deterministic retry policy with 2s, 4s, and 8s exponential delays and escalation to `Needs attention`.
  - Per-stop FIFO ordering pipeline preventing race conditions or out-of-order state transitions.
  - Persistent UUID v4 request idempotency preventing double-execution on retransmissions.
  - Simulated Offline Mode toggle and controllable failure-rate slider (0% to 100%).
- **Interactive Demo Clock & Time-Window Alerts**:
  - Centralized, injectable `ClockService` with date/time pickers and quick adjustment shortcuts.
  - Real-time stop alert badges: **Normal** (> 15 min), **At risk** ($\le 15$ min), and **Late** (> window end).
- **Consolidated 3-Tab Material 3 Navigation**:
  - **Route Tab**: Dispatch header, greeting, Demo Clock, Online/Offline badge, KPI counters, search bar, filter chips, and interactive stop cards with modal bottom sheets.
  - **Summary Tab**: Daily performance KPIs (Success Rate %, On-Time Rate %, stop breakdown) and live Unsynced Actions queue table with manual retry controls.
  - **Settings Tab**: Network configuration, failure-rate slider with presets, Demo Clock simulation, synchronization queue diagnostics, application info, and account management.

---

## 4. Business Workflow Rules (R1–R6)

All business rules are encapsulated in pure domain services ([`WorkflowService`](lib/features/stop_workflow/domain/services/workflow_service.dart)) and cannot be bypassed by the UI:

| Rule | Title | Domain Implementation & Behavior |
|---|---|---|
| **R1** | **Single Active Stop** | Only one stop can be in `Arrived` status at any time. When marking a stop as Arrived, `WorkflowService.markArrived()` inspects the repository. If any other stop is currently active, a `WorkflowFailure` is thrown identifying the blocking stop. Delivered and Returned stops cannot be marked Arrived. |
| **R2** | **Delivered Validation** | Marking a stop `Delivered` requires that the stop is currently `Arrived`. The recipient name is mandatory ($\ge 2$ characters after trimming). The confirmed package count must exactly equal the expected package count. Delivery timestamp and recipient details are recorded in the audit trail. |
| **R3** | **Failure Reason & Note** | Marking a stop `Failed` requires that the stop is currently `Arrived`. The agent must select one of 5 reasons: *Customer absent*, *Wrong address*, *Refused*, *Access problem*, or *Other*. If *Other* is selected, a descriptive note of at least 10 characters is mandatory. |
| **R4** | **Retry & Escalation** | Stops track attempt counts (`failureCount`). On the **1st failure**, the stop transitions to `Failed`, is flagged as a retry (`isRetry = true`), and is assigned a custom order placing it at the end of the route. On the **2nd failure**, the stop transitions to `Returned to hub`, locking it permanently against further delivery attempts. |
| **R5** | **60-Second Real-Elapsed Undo** | Delivered stops can be undone within 60 seconds. Eligibility is calculated as $60 - (\text{now} - \text{deliveryTimestamp}).\text{inSeconds}$ using the stored timestamp, surviving app restarts and navigation. Undoing restores the stop to `Arrived`, restores its natural route ordering, appends an audit record, and enqueues an `undoDelivered` sync action. After 60 seconds, undo is locked permanently. |
| **R6** | **Urgent Stop Protection** | Stops marked with `Urgent` priority cannot be reported as *Customer absent* before their delivery window start time, evaluated against the live Demo Clock. If an agent attempts this prematurely, `WorkflowService.markFailed()` throws a `ValidationFailure`. Other failure reasons (e.g., Wrong address) remain permissible. |

---

## 5. Offline Synchronization Rules (S1–S7)

The synchronization engine ([`SyncEngine`](lib/features/synchronization/domain/services/sync_engine.dart), [`RequestProcessor`](lib/features/synchronization/domain/services/request_processor.dart), [`RetryPolicy`](lib/features/synchronization/domain/services/retry_policy.dart), [`MockServer`](lib/features/synchronization/data/mock_server.dart)) guarantees data consistency in disconnected and unreliable network conditions:

| Rule | Title | Technical Implementation |
|---|---|---|
| **S1** | **Optimistic UI & Persist-Before-Send** | User actions update local Hive stop records and enqueue a `SyncAction` to the local persistent queue **before** any network transmission begins. UI state updates immediately without waiting for server responses. |
| **S2** | **Sync Status Badges** | Each stop evaluates its sync state across its queued actions: **Synced** (Green - queue empty), **Pending** (Grey - waiting initial dispatch), **Retrying** (Orange - scheduled backoff active), and **Needs attention** (Red - retries exhausted). |
| **S3** | **Exponential Backoff & Escalation** | Failed requests follow an exponential schedule: 1st retry after **2 seconds**, 2nd retry after **4 seconds**, 3rd retry after **8 seconds**. After the 3rd retry failure (4 total attempts), the action transitions to `SyncStatus.needsAttention`. Agents can trigger a **Manual Retry** to reset the retry count and re-attempt synchronization. |
| **S4** | **Per-Stop FIFO Ordering** | Actions are grouped by `stopId` and sorted strictly by `sequenceNumber` ascending. If an earlier action for a stop is retrying or in `needsAttention`, all subsequent actions for that stop are held back to prevent out-of-order execution (e.g., preventing Delivered before Arrived). Unrelated stops synchronize independently without blocking each other. |
| **S5** | **UUID-Based Idempotency** | Every `SyncAction` is assigned a unique UUID v4 upon creation. The mock server maintains a persistent set of processed request IDs in Hive. If a duplicate request arrives (e.g., due to an in-flight timeout or app restart), the server acknowledges with `success: true` and `wasDuplicate: true` without duplicating side effects. |
| **S6** | **Offline Mode Simulation** | An Offline Mode toggle in Settings immediately simulates total network disconnection. All outgoing requests fail fast and remain safely in the local queue. Disabling Offline Mode automatically wakes the sync engine to process eligible queued actions in sequence. |
| **S7** | **Restart Safety & Recovery** | Queued actions reside in Hive (`nexu_sync_queue_box`) and survive application termination, device reboots, and crashes. Upon restart, the engine restores the queue and resumes execution. Actions are deleted from the local queue **only after** verified server acknowledgement. |

---

## 6. Technology Stack

- **Framework**: Flutter 3.41.6 (Channel stable)
- **Programming Language**: Dart 3.11.4
- **State Management**: `flutter_riverpod: ^2.5.1` (Compile-safe, modular dependency injection)
- **Local Persistence**: `hive: ^2.2.3`, `hive_flutter: ^1.1.0` (High-performance NoSQL storage)
- **Unique Request Identifiers**: `uuid: ^4.4.0` (UUID v4 generation)
- **Date & Time Formatting**: `intl: ^0.19.0`
- **UI Design System**: Material 3 Logistics Theme (Navy `#0F172A`, Blue `#2563EB`, Green `#10B981`, Amber `#D97706`, Red `#EF4444`)
- **Target Platform**: Android (Min SDK 21, Target SDK 34)

---

## 7. Architecture and Folder Structure

The project follows strict **Clean Architecture** conventions:

```
lib/
  main.dart                               # Hive initialization & application bootstrap
  app/
    app.dart                              # Root MaterialApp & auth-state routing
    home_navigation_shell.dart            # Material 3 NavigationBar (3 primary tabs)
    theme.dart                            # Material 3 Logistics design system
  core/
    constants/app_constants.dart          # Configuration constants, storage keys & limits
    enums/                                # Priority, WorkflowStatus, SyncStatus, FailureReason
    errors/failures.dart                  # Domain exceptions (WorkflowFailure, ValidationFailure)
    providers/core_providers.dart         # Hive boxes & ClockService dependency providers
    services/clock_service.dart           # Centralized injectable Demo Clock service
    utils/date_time_formatter.dart        # Window parsing and time formatting utilities
  features/
    authentication/                       # Auth session, credentials validation & SignInScreen
    route_management/                     # Stops repository, sorter & DashboardScreen (Route Tab)
    stop_workflow/                        # WorkflowService (R1-R6) & bottom sheets (Detail, Delivery, Failure)
    synchronization/                      # MockServer, SyncEngine, RetryPolicy, QueueStorage
    summary/                              # DailySummaryScreen (KPIs & Unsynced Queue - Summary Tab)
    settings/                             # SettingsScreen (Network, Clock, Diagnostics - Settings Tab)
assets/
  data/route_stops.json                   # Initial route dataset (14 realistic stops)
test/
  unit/
    workflow_test.dart                    # R1, R2, R3, R4, R5, R6 unit tests
    sync_engine_test.dart                 # S3, S4, S5, S6, S7 sync engine tests
    time_alert_and_sorting_test.dart      # RouteSorter & TimeAlertEvaluator tests
    failure_rate_slider_test.dart         # Controlled slider, presets, dynamic failure rate tests
    test_fakes.dart                       # In-memory FakeHiveBox, FakeRouteRepository, FakeSyncQueue
  widget_test.dart                        # Smoke test for route sorting logic
```

---

## 8. Installation and Setup Instructions

### Prerequisites
- **Flutter SDK**: Version 3.24.x or 3.41.x installed and configured in your system `PATH`.
- **Dart SDK**: Version 3.5.x or 3.11.x.
- **Java Development Kit (JDK)**: JDK 17+ configured for Android builds.
- **Android SDK**: Platform SDK 34 with Android Build-Tools.

### Setup (PowerShell on Windows)

1. Open PowerShell and navigate to the project directory:
   ```powershell
   cd c:\Users\Selvamani\Desktop\Nexu_SS
   ```

2. Fetch all package dependencies:
   ```powershell
   flutter pub get
   ```

3. Run static code analysis to verify zero issues:
   ```powershell
   flutter analyze
   ```

---

## 9. Running the Application

To run the application on a connected Android device, emulator, or Windows desktop:

```powershell
# List available devices and emulators
flutter devices

# Run on the active device/emulator
flutter run
```

---

## 10. Running Automated Tests

The repository contains **21 automated tests** covering all business rules (R1–R6), synchronization mechanics (S1–S7), route sorting, and UI slider controls.

Execute the entire test suite via:

```powershell
flutter test
```

### Verified Test Breakdown (21 Tests)
- `test/unit/workflow_test.dart`:
  - **R1**: Single active stop constraint.
  - **R2**: Delivered validation (recipient name $\ge 2$ chars, exact package match).
  - **R3**: Failure reason "Other" mandates $\ge 10$-character note.
  - **R4**: First failure moves stop to end for retry; second failure locks as `Returned to hub`.
  - **R5**: 60-second delivery undo eligibility and post-60s locking.
  - **R6**: Urgent stop rejection of "Customer absent" before delivery window start.
- `test/unit/sync_engine_test.dart`:
  - **S3**: Exponential backoff delays (2s, 4s, 8s) and escalation to `needsAttention`.
  - **S4**: Per-stop FIFO ordering (blocked head action holds back later actions).
  - **S5**: Duplicate request ID protection and idempotency acknowledgement.
  - **S6**: Offline mode blocking and automatic queue resumption.
  - **S7**: Queue persistence across application restart.
- `test/unit/time_alert_and_sorting_test.dart`:
  - RouteSorter ordering by window start ascending, Urgent priority promotion, and Stop ID tie-breaking.
  - RouteSorter retry stop placement at route end.
  - TimeAlertEvaluator classification (Normal, At risk, Late).
  - Exclusion of Delivered and Returned stops from Late alerts.
- `test/unit/failure_rate_slider_test.dart`:
  - Slider change from 30% to 0% updates Riverpod state, MockServer, and Hive.
  - Slider change from 30% to 100% updates Riverpod state, MockServer, and Hive.
  - Preset buttons (0% Pass, 30% Default, 100% Fail) update state and server.
  - Dynamic request failure evaluation: 100% failure rate forces 100% failure; 0% forces 100% success.
  - `SettingsScreen` UI widget test: Tapping preset buttons updates slider and label text immediately.
- `test/widget_test.dart`:
  - Smoke test validating deterministic route ordering.

---

## 11. Building the Release APK

To compile the standalone production release APK for Android:

```powershell
flutter build apk --release
```

### Build Artifact Details
- **APK Output Path**:
  ```text
  build/app/outputs/flutter-apk/app-release.apk
  ```
- **File Size**: ~50.4 MB
- **Package Identifier**: `com.nexu.routerunner.nexu_routerunner`
- **Version**: `1.0.0+1`
- **Minimum SDK**: `21` (Android 5.0 Lollipop)
- **Target SDK**: `34` (Android 14)
- **Signing**: Configured with debug signing for direct review installation (`flutter run --release` ready).

---

## 12. Demo Credentials & Authentication Instructions

The application implements demo authentication backed by local Hive persistence:

- **Agent Name**: `Asha`
- **4-Digit PIN**: `1234`

### Walkthrough
1. Launch the application to display the Sign In screen.
2. Tap the **"Use Demo Credentials"** button to auto-populate the fields, or manually enter `Asha` and `1234`.
3. Tap **Sign In**. The session is validated and stored in `nexu_auth_box`.
4. Subsequent app launches will automatically bypass the Sign In screen and restore the authenticated session.
5. To test session destruction, navigate to the **Settings** tab and tap **Sign Out** (with confirmation dialog).

---

## 13. Known Limitations

- **Simulated Backend**: As explicitly stipulated by assessment requirements, no external HTTP backend is contacted; network latency (1–3s), simulated disconnections, and failure rates are simulated locally in Dart.
- **Push Notifications**: Local system push notifications are excluded per assessment specifications.
- **Single Active Route**: The application supports a single active delivery route per shift (14 stops), matching the recruitment scenario.

---

## 14. Project Documentation References

Detailed technical documentation is maintained in the repository root:

- [`DECISIONS.md`](DECISIONS.md): Architectural decisions addressing requirements ambiguities (S3 retry counting, R5 undo state restoration, S4 inter-stop independence, KPI calculation denominators).
- [`FEATURE_COMPLETION.md`](FEATURE_COMPLETION.md): Complete feature-by-feature traceability matrix mapping all assessment requirements to their implementation files.
- [`TESTING_SUMMARY.md`](TESTING_SUMMARY.md): Comprehensive testing report detailing the 21 automated tests, execution results, and bugs resolved during development.
