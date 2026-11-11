import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/enums/sync_status.dart';
import '../../../../core/services/clock_service.dart';
import '../../data/mock_server.dart';
import '../../data/sync_queue_storage.dart';
import '../entities/sync_action.dart';
import 'request_processor.dart';
import 'retry_policy.dart';

class SyncEngine extends ChangeNotifier {
  final SyncQueueStorage _queueStorage;
  final RequestProcessor _requestProcessor;
  final MockServer _mockServer;
  final ClockService _clockService;
  final RetryPolicy _retryPolicy;

  bool _isProcessing = false;
  Timer? _pollingTimer;

  SyncEngine({
    required SyncQueueStorage queueStorage,
    required RequestProcessor requestProcessor,
    required MockServer mockServer,
    required ClockService clockService,
    RetryPolicy? retryPolicy,
    bool autoStartTimer = true,
  })  : _queueStorage = queueStorage,
        _requestProcessor = requestProcessor,
        _mockServer = mockServer,
        _clockService = clockService,
        _retryPolicy = retryPolicy ?? const RetryPolicy() {
    if (autoStartTimer) {
      _startPeriodicTimer();
    }
  }

  bool get isProcessing => _isProcessing;
  bool get isOffline => _mockServer.isOffline;
  List<SyncAction> get queue => _queueStorage.getQueue();

  void _startPeriodicTimer() {
    _pollingTimer?.cancel();
    // Periodically inspect queue for retries whose scheduled time has elapsed
    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isProcessing && !_mockServer.isOffline) {
        processEligibleQueue();
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  SyncStatus getStopSyncStatus(String stopId) {
    final actions = _queueStorage.getQueue().where((a) => a.stopId == stopId).toList();
    if (actions.isEmpty) {
      return SyncStatus.synced;
    }
    if (actions.any((a) => a.status == SyncStatus.needsAttention)) {
      return SyncStatus.needsAttention;
    }
    if (actions.any((a) => a.status == SyncStatus.retrying)) {
      return SyncStatus.retrying;
    }
    return SyncStatus.pending;
  }

  Future<void> processEligibleQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;
    notifyListeners();

    try {
      final currentQueue = _queueStorage.getQueue();
      if (currentQueue.isEmpty) {
        return;
      }

      // Group actions by stopId for per-stop sequential ordering (S4)
      final Map<String, List<SyncAction>> grouped = {};
      for (final action in currentQueue) {
        grouped.putIfAbsent(action.stopId, () => []).add(action);
      }

      final currentTime = _clockService.now();

      // Process each stop's head action
      for (final stopId in grouped.keys) {
        final stopActions = grouped[stopId]!;
        // Sort strictly by sequenceNumber
        stopActions.sort((a, b) => a.sequenceNumber.compareTo(b.sequenceNumber));

        final headAction = stopActions.first;

        // If head action requires attention, it blocks ALL later actions for this stop!
        if (headAction.status == SyncStatus.needsAttention) {
          continue;
        }

        // If head action is retrying, check if nextRetryTime has arrived
        if (headAction.status == SyncStatus.retrying) {
          if (headAction.nextRetryTime != null &&
              currentTime.isBefore(headAction.nextRetryTime!)) {
            // Still waiting for backoff delay
            continue;
          }
        }

        // Eligible to process head action
        final result = await _requestProcessor.processAction(headAction);
        notifyListeners();

        // If processing succeeded, and there are more actions for this stop,
        // we can process the next action in the next cycle.
        // If it failed, subsequent actions remain blocked.
        if (!result.success) {
          // Stop processing further actions for this stopId in this iteration
          continue;
        }
      }
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> manualRetryAction(String actionId) async {
    final currentQueue = _queueStorage.getQueue();
    final action = currentQueue.firstWhere((a) => a.id == actionId);

    final resetAction = _retryPolicy.prepareManualRetry(action);
    await _queueStorage.update(resetAction);
    notifyListeners();

    await processEligibleQueue();
  }

  Future<void> manualRetryAll() async {
    final currentQueue = _queueStorage.getQueue();
    for (final action in currentQueue) {
      if (action.status == SyncStatus.needsAttention ||
          action.status == SyncStatus.retrying) {
        final resetAction = _retryPolicy.prepareManualRetry(action);
        await _queueStorage.update(resetAction);
      }
    }
    notifyListeners();
    await processEligibleQueue();
  }

  Future<void> setOfflineMode(bool offline) async {
    await _mockServer.setOfflineMode(offline);
    notifyListeners();
    if (!offline) {
      // S6: Automatically restart queue processing when offline mode is disabled
      await processEligibleQueue();
    }
  }

  Future<void> setFailureRate(double rate) async {
    await _mockServer.setFailureRate(rate);
    notifyListeners();
  }
}
