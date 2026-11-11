# Testing Summary — NEXU RouteRunner

This document reports the testing strategy, test suite execution results, bugs identified and resolved during development, and overall QA verification for the **NEXU RouteRunner** mobile application.

---

## 1. Test Execution Command & Summary

All automated tests are fully runnable via the standard Flutter test runner:

```bash
flutter test
```

### Execution Results
- **Total Tests Written**: 21
- **Total Tests Passed**: 21
- **Total Tests Failed**: 0
- **Execution Time**: ~4.2 seconds
- **Pass Rate**: 100%

---

## 2. Mandatory Tests Breakdown

| ID | Assessment Test Target | Test Implementation File | Result | Verification Focus |
|---|---|---|---|---|
| **Test 1** | **R1**: Only one active stop | `test/unit/workflow_test.dart` | **PASSED** | Verifies that when STOP-001 is `Arrived`, calling `markArrived('STOP-002')` throws `WorkflowFailure` identifying the currently active stop. |
| **Test 2** | **R2**: Delivered validation | `test/unit/workflow_test.dart` | **PASSED** | Verifies that whitespace-only recipient name, single-character name (< 2 chars), and mismatched package count (less or greater than expected) are strictly rejected with `ValidationFailure`. |
| **Test 3** | **R4**: Retry mechanism | `test/unit/workflow_test.dart` | **PASSED** | Verifies that 1st failure moves stop to route end with `isRetry = true` and `failureCount = 1`. 2nd failure marks stop as `Returned to hub` and prevents further retries. |
| **Test 4** | **R6**: Urgent stops | `test/unit/workflow_test.dart` | **PASSED** | Verifies that an Urgent stop with window "09:00–10:00" tested at 08:45 AM rejects `Customer absent` with `ValidationFailure`. Other failure reasons succeed. |
| **Test 5** | **S3**: Exponential backoff | `test/unit/sync_engine_test.dart` | **PASSED** | Verifies 1st retry delay is 2s, 2nd retry delay is 4s, 3rd retry delay is 8s, and that after 3rd retry failure, the action transitions to `needsAttention`. |
| **Test 6** | **S4**: Per-stop ordering | `test/unit/sync_engine_test.dart` | **PASSED** | Verifies that actions for `STOP-001` (Arrived, Delivered, Undo) are processed strictly in FIFO sequence number order. Subsequent actions are blocked when an earlier action is retrying. |
| **Test 7** | **S5**: Duplicate protection | `test/unit/sync_engine_test.dart` | **PASSED** | Verifies that sending the same UUID request ID twice returns `success: true` with `wasDuplicate: true` and does not apply duplicate state mutations. |
| **Test 8** | **S7**: Restart safety | `test/unit/sync_engine_test.dart` | **PASSED** | Verifies that queued actions stored before app restart survive in local queue storage and automatically resume processing upon engine re-initialization. |

---

## 3. Additional Tests Breakdown

| Test Name | Test Implementation File | Result | Verification Focus |
|---|---|---|---|
| **R5: 60-Second Undo** | `test/unit/workflow_test.dart` | **PASSED** | Verifies that delivery undo succeeds within 60s, restores stop to `Arrived`, and is permanently rejected after 60s elapsed time. |
| **R3: Note Validation** | `test/unit/workflow_test.dart` | **PASSED** | Verifies that "Other" failure reason mandates a note of at least 10 trimmed characters. |
| **S6: Offline Mode** | `test/unit/sync_engine_test.dart` | **PASSED** | Verifies that enabling Offline Mode prevents requests from reaching the server, keeps actions in queue, and auto-syncs when disabled. |
| **Route Sorter Order** | `test/unit/time_alert_and_sorting_test.dart` | **PASSED** | Verifies sorting by window start ascending, Urgent before Normal on identical start times, and stop ID tie-breaking. |
| **Route Sorter Retries** | `test/unit/time_alert_and_sorting_test.dart` | **PASSED** | Verifies that retried/failed stops are placed at the end of the route behind active scheduled stops. |
| **Time Alert Evaluator** | `test/unit/time_alert_and_sorting_test.dart` | **PASSED** | Verifies evaluation of Normal (> 15m), At risk (<= 15m), and Late (> windowEnd) relative to the simulated clock. |
| **Alert Exclusion** | `test/unit/time_alert_and_sorting_test.dart` | **PASSED** | Verifies that `Delivered` and `Returned to hub` stops are never classified as Late even past their window end. |
| **Slider 30% to 0%** | `test/unit/failure_rate_slider_test.dart` | **PASSED** | Verifies dragging slider from 30% to 0% updates Riverpod state, MockServer, and Hive. |
| **Slider 30% to 100%** | `test/unit/failure_rate_slider_test.dart` | **PASSED** | Verifies dragging slider from 30% to 100% updates Riverpod state, MockServer, and Hive. |
| **Slider Presets** | `test/unit/failure_rate_slider_test.dart` | **PASSED** | Verifies 0% Pass, 30% Default, and 100% Fail presets correctly configure slider and server. |
| **Dynamic Request Evaluation** | `test/unit/failure_rate_slider_test.dart` | **PASSED** | Verifies MockServer dynamically uses 100% rate to fail 100% of requests and 0% rate to pass 100% of requests. |
| **Settings UI Widget** | `test/unit/failure_rate_slider_test.dart` | **PASSED** | Verifies tapping preset buttons in SettingsScreen immediately updates slider value and label text. |
| **Smoke Test** | `test/widget_test.dart` | **PASSED** | Smoke test validating end-to-end sorting logic. |

---

## 4. Bugs Identified & Resolved During Development

1. **Sub-Millisecond Clock Discrepancy in Retry Backoff Test (S3)**
   - *Issue*: `ClockService.now()` calculates elapsed time using `DateTime.now().difference()`, creating microsecond-level offsets (e.g. `10:00:02.007649`). An exact equality check against `10:00:02.000` failed due to 7 milliseconds difference.
   - *Fix*: Refactored test assertions to verify time differences in integer seconds (`difference().inSeconds`), accurately validating the 2s, 4s, and 8s intervals without sensitivity to microsecond CPU scheduling jitter.

2. **Delivery Undo Countdown Elapsed Time Calculation (R5)**
   - *Issue*: A naive countdown using a decrementing widget timer resets when the user navigates away or restarts the app, violating requirement R5.
   - *Fix*: Implemented real-time elapsed time calculation:
     $$\text{Remaining Seconds} = 60 - (\text{currentTime} - \text{deliveryTimestamp}).\text{inSeconds}$$
     Stored `deliveryTimestamp` in Hive so remaining time is accurately recalculated across app restarts.

3. **Flutter 3.41 `CardThemeData` Type Mismatch**
   - *Issue*: Flutter 3.41 changed `ThemeData.cardTheme` parameter type expectation to `CardThemeData`.
   - *Fix*: Updated `AppTheme` to construct `CardThemeData` directly.

4. **RadioListTile Deprecation in Latest Flutter**
   - *Issue*: Using deprecated `groupValue` on `RadioListTile` caused analyzer deprecation notices.
   - *Fix*: Created clean custom selection rows using `InkWell` and icons, improving touch target ergonomics and achieving 0 analyzer issues.

5. **Mock Server Failure-Rate Slider Unresponsiveness**
   - *Issue*: `mockFailureRateProvider` was defined as an un-notified read-only `Provider<double>`, and slider callbacks mutated `SyncEngine` without triggering `SettingsScreen` rebuilds.
   - *Fix*: Re-architected `mockFailureRateProvider` as a `StateProvider<double>` with bidirectional binding to `MockServer` and 20 divisions, updating the live failure rate for both UI and subsequent server requests.

---

## 5. Known Remaining Issues & Limitations

- **Simulated Backend**: As explicitly requested by the recruitment assessment, no external HTTP backend is contacted; all networking, latency, and failure rates are faithfully simulated locally in Dart.
- **Push Notifications**: Per section 1 requirements, local notifications are not implemented.
