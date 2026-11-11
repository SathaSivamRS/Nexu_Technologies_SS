import '../../../../core/enums/sync_status.dart';
import '../../../../core/services/clock_service.dart';
import '../../data/mock_server.dart';
import '../../data/sync_queue_storage.dart';
import '../entities/sync_action.dart';
import 'retry_policy.dart';

class ProcessActionResult {
  final bool success;
  final SyncAction updatedAction;
  final bool removed;

  const ProcessActionResult({
    required this.success,
    required this.updatedAction,
    required this.removed,
  });
}

class RequestProcessor {
  final MockServer _mockServer;
  final SyncQueueStorage _queueStorage;
  final RetryPolicy _retryPolicy;
  final ClockService _clockService;

  RequestProcessor({
    required MockServer mockServer,
    required SyncQueueStorage queueStorage,
    required RetryPolicy retryPolicy,
    required ClockService clockService,
  })  : _mockServer = mockServer,
        _queueStorage = queueStorage,
        _retryPolicy = retryPolicy,
        _clockService = clockService;

  Future<ProcessActionResult> processAction(SyncAction action) async {
    try {
      final response = await _mockServer.processAction(action);

      if (response.success) {
        // Successful server acknowledgement: Remove from local queue
        await _queueStorage.remove(action.id);
        final completedAction = action.copyWith(status: SyncStatus.synced);
        return ProcessActionResult(
          success: true,
          updatedAction: completedAction,
          removed: true,
        );
      } else {
        // Server returned failure
        final decision = _retryPolicy.evaluateFailure(
          action,
          _clockService.now(),
        );

        final updated = action.copyWith(
          status: decision.nextStatus,
          retryCount: decision.newRetryCount,
          nextRetryTime: decision.nextRetryTime,
          clearNextRetryTime: decision.nextRetryTime == null,
          lastError: response.message,
        );

        await _queueStorage.update(updated);
        return ProcessActionResult(
          success: false,
          updatedAction: updated,
          removed: false,
        );
      }
    } catch (e) {
      final decision = _retryPolicy.evaluateFailure(
        action,
        _clockService.now(),
      );

      final updated = action.copyWith(
        status: decision.nextStatus,
        retryCount: decision.newRetryCount,
        nextRetryTime: decision.nextRetryTime,
        clearNextRetryTime: decision.nextRetryTime == null,
        lastError: e.toString(),
      );

      await _queueStorage.update(updated);
      return ProcessActionResult(
        success: false,
        updatedAction: updated,
        removed: false,
      );
    }
  }
}
