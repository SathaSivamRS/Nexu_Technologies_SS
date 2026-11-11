import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/enums/sync_status.dart';
import '../../../../core/enums/workflow_status.dart';
import '../../../../core/utils/date_time_formatter.dart';
import '../../../route_management/presentation/providers/route_providers.dart';
import '../../../synchronization/domain/entities/sync_action.dart';
import '../../../synchronization/presentation/providers/sync_providers.dart';

class DailySummaryData {
  final int totalStops;
  final int deliveredCount;
  final int onTimeDeliveredCount;
  final int failedCount;
  final int returnedToHubCount;
  final int remainingCount;
  final double successRate;
  final double onTimeRate;
  final int pendingSyncCount;
  final int needsAttentionCount;
  final List<SyncAction> unsyncedActions;

  const DailySummaryData({
    required this.totalStops,
    required this.deliveredCount,
    required this.onTimeDeliveredCount,
    required this.failedCount,
    required this.returnedToHubCount,
    required this.remainingCount,
    required this.successRate,
    required this.onTimeRate,
    required this.pendingSyncCount,
    required this.needsAttentionCount,
    required this.unsyncedActions,
  });
}

final dailySummaryProvider = Provider<DailySummaryData>((ref) {
  final routeState = ref.watch(routeStopsNotifierProvider);
  final stops = routeState.stops;
  final queue = ref.watch(unsyncedActionsProvider);

  final total = stops.length;
  final deliveredStops =
      stops.where((s) => s.status == WorkflowStatus.delivered).toList();
  final deliveredCount = deliveredStops.length;

  int onTimeDeliveredCount = 0;
  for (final stop in deliveredStops) {
    if (stop.deliveryTimestamp != null) {
      final windowEnd = DateTimeFormatter.parseWindowTime(
        stop.windowEnd,
        stop.deliveryTimestamp!,
      );
      if (!stop.deliveryTimestamp!.isAfter(windowEnd)) {
        onTimeDeliveredCount++;
      }
    }
  }

  final failedCount =
      stops.where((s) => s.status == WorkflowStatus.failed).length;
  final returnedToHubCount =
      stops.where((s) => s.status == WorkflowStatus.returnedToHub).length;
  final remainingCount = stops
      .where((s) =>
          s.status == WorkflowStatus.pending ||
          s.status == WorkflowStatus.arrived ||
          s.status == WorkflowStatus.failed)
      .length;

  final successRate =
      total > 0 ? (deliveredCount / total) * 100.0 : 0.0;
  final onTimeRate = deliveredCount > 0
      ? (onTimeDeliveredCount / deliveredCount) * 100.0
      : 0.0;

  final pendingSyncCount =
      queue.where((a) => a.status != SyncStatus.synced).length;
  final needsAttentionCount =
      queue.where((a) => a.status == SyncStatus.needsAttention).length;

  return DailySummaryData(
    totalStops: total,
    deliveredCount: deliveredCount,
    onTimeDeliveredCount: onTimeDeliveredCount,
    failedCount: failedCount,
    returnedToHubCount: returnedToHubCount,
    remainingCount: remainingCount,
    successRate: successRate,
    onTimeRate: onTimeRate,
    pendingSyncCount: pendingSyncCount,
    needsAttentionCount: needsAttentionCount,
    unsyncedActions: queue,
  );
});
