import 'package:flutter/material.dart';
import '../../../../app/theme.dart';
import '../../../../core/enums/sync_status.dart';

class SyncStatusBadge extends StatelessWidget {
  final SyncStatus status;

  const SyncStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status) {
      case SyncStatus.synced:
        bg = AppTheme.successGreen.withAlpha(25);
        fg = AppTheme.successGreen;
        icon = Icons.check_circle_outline_rounded;
        break;
      case SyncStatus.pending:
        bg = const Color(0xFFE2E8F0);
        fg = const Color(0xFF475569);
        icon = Icons.schedule_rounded;
        break;
      case SyncStatus.retrying:
        bg = AppTheme.warningOrange.withAlpha(35);
        fg = const Color(0xFFD97706);
        icon = Icons.sync_rounded;
        break;
      case SyncStatus.needsAttention:
        bg = AppTheme.errorRed.withAlpha(30);
        fg = AppTheme.errorRed;
        icon = Icons.error_outline_rounded;
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
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            status.label,
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
