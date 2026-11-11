import 'package:intl/intl.dart';

class DateTimeFormatter {
  static final DateFormat timeFormat = DateFormat('HH:mm');
  static final DateFormat fullDateTimeFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  static final DateFormat displayDateFormat = DateFormat('EEE, d MMM yyyy');
  static final DateFormat displayTimeFormat = DateFormat('hh:mm a');

  static DateTime parseWindowTime(String timeStr, DateTime referenceDate) {
    final parts = timeStr.trim().split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
      hour,
      minute,
    );
  }

  static String formatTime(DateTime dateTime) {
    return timeFormat.format(dateTime);
  }

  static String formatFull(DateTime dateTime) {
    return fullDateTimeFormat.format(dateTime);
  }
}
