import '../../../../core/constants/app_constants.dart';
import '../../../../core/enums/sync_status.dart';
import '../entities/sync_action.dart';

class RetryDecision {
  final SyncStatus nextStatus;
  final int newRetryCount;
  final DateTime? nextRetryTime;
  final Duration? delay;
  final bool shouldRetry;

  const RetryDecision({
    required this.nextStatus,
    required this.newRetryCount,
    this.nextRetryTime,
    this.delay,
    required this.shouldRetry,
  });
}

class RetryPolicy {
  final List<int> delaysSeconds;
  final int maxRetries;

  const RetryPolicy({
    this.delaysSeconds = AppConstants.retryDelaysSeconds, // [2, 4, 8]
    this.maxRetries = AppConstants.maxRetryAttempts, // 3
  });

  RetryDecision evaluateFailure(SyncAction action, DateTime currentTime) {
    final nextRetryIndex = action.retryCount; // 0 for 1st retry, 1 for 2nd, 2 for 3rd

    if (nextRetryIndex < delaysSeconds.length && nextRetryIndex < maxRetries) {
      final delaySeconds = delaysSeconds[nextRetryIndex];
      final delayDuration = Duration(seconds: delaySeconds);
      final nextTime = currentTime.add(delayDuration);

      return RetryDecision(
        nextStatus: SyncStatus.retrying,
        newRetryCount: action.retryCount + 1,
        nextRetryTime: nextTime,
        delay: delayDuration,
        shouldRetry: true,
      );
    } else {
      // Third retry failed -> Needs attention
      return RetryDecision(
        nextStatus: SyncStatus.needsAttention,
        newRetryCount: action.retryCount + 1,
        nextRetryTime: null,
        delay: null,
        shouldRetry: false,
      );
    }
  }

  SyncAction prepareManualRetry(SyncAction action) {
    return action.copyWith(
      status: SyncStatus.pending,
      retryCount: 0,
      clearNextRetryTime: true,
      clearLastError: true,
    );
  }
}
