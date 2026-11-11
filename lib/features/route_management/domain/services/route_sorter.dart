import '../../../../core/enums/priority.dart';
import '../../../../core/enums/workflow_status.dart';
import '../entities/route_stop.dart';

class RouteSorter {
  static List<RouteStop> sortStops(List<RouteStop> stops) {
    final list = List<RouteStop>.from(stops);
    list.sort(_compareStops);
    return list;
  }

  static int _compareStops(RouteStop a, RouteStop b) {
    // 1. Retries / Failed stops that are moved to the end
    final aIsEnd = a.isRetry || a.status == WorkflowStatus.failed;
    final bIsEnd = b.isRetry || b.status == WorkflowStatus.failed;

    if (!aIsEnd && bIsEnd) return -1;
    if (aIsEnd && !bIsEnd) return 1;

    if (aIsEnd && bIsEnd) {
      // Both are moved to end as retries
      // If customOrder is present, compare customOrder
      if (a.customOrder != null && b.customOrder != null) {
        final orderComp = a.customOrder!.compareTo(b.customOrder!);
        if (orderComp != 0) return orderComp;
      } else if (a.customOrder != null) {
        return 1;
      } else if (b.customOrder != null) {
        return -1;
      }
      // Secondary comparison for retries: windowStart -> Priority -> ID
      return _compareStandardSchedule(a, b);
    }

    // Both are standard schedule stops
    return _compareStandardSchedule(a, b);
  }

  static int _compareStandardSchedule(RouteStop a, RouteStop b) {
    // 1. Window start time ascending (e.g. "08:30" vs "09:00")
    final timeComp = a.windowStart.compareTo(b.windowStart);
    if (timeComp != 0) return timeComp;

    // 2. Urgent before Normal (urgent has higher priority -> comes first)
    if (a.priority == StopPriority.urgent && b.priority != StopPriority.urgent) {
      return -1;
    }
    if (a.priority != StopPriority.urgent && b.priority == StopPriority.urgent) {
      return 1;
    }

    // 3. Deterministic tie-breaker: Stop ID ascending
    return a.id.compareTo(b.id);
  }
}
