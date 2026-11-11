import 'package:flutter/material.dart';
import '../../../../app/theme.dart';
import '../../../../core/enums/time_alert.dart';

class TimeAlertBadge extends StatelessWidget {
  final TimeAlert alert;

  const TimeAlertBadge({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;

    switch (alert) {
      case TimeAlert.late:
        bg = AppTheme.errorRed.withAlpha(30);
        fg = AppTheme.errorRed;
        icon = Icons.alarm_off_rounded;
        break;
      case TimeAlert.atRisk:
        bg = AppTheme.warningOrange.withAlpha(35);
        fg = const Color(0xFFD97706);
        icon = Icons.access_time_filled_rounded;
        break;
      case TimeAlert.normal:
        bg = const Color(0xFFF1F5F9);
        fg = AppTheme.textSecondary;
        icon = Icons.access_time_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            alert.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
