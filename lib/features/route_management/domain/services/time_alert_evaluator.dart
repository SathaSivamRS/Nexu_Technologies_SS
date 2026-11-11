import '../../../../core/enums/time_alert.dart';
import '../../../../core/enums/workflow_status.dart';
import '../../../../core/utils/date_time_formatter.dart';
import '../entities/route_stop.dart';

class TimeAlertEvaluator {
  static TimeAlert evaluate(RouteStop stop, DateTime currentTime) {
    // Delivered and Returned to hub stops are not active delivery alerts
    if (stop.status == WorkflowStatus.delivered ||
        stop.status == WorkflowStatus.returnedToHub) {
      return TimeAlert.normal;
    }

    final windowEndDateTime =
        DateTimeFormatter.parseWindowTime(stop.windowEnd, currentTime);

    // If currentTime is after window end: Late
    if (currentTime.isAfter(windowEndDateTime)) {
      return TimeAlert.late;
    }

    // Minutes remaining until windowEnd
    final remainingSeconds =
        windowEndDateTime.difference(currentTime).inSeconds;
    final remainingMinutes = remainingSeconds / 60.0;

    // Fewer than 15 minutes remain: At risk
    // (Note: <= 15.0 minutes)
    if (remainingMinutes <= 15.0) {
      return TimeAlert.atRisk;
    }

    return TimeAlert.normal;
  }
}
