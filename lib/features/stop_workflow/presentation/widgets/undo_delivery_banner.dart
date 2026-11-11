import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../route_management/domain/entities/route_stop.dart';

class UndoDeliveryBanner extends ConsumerWidget {
  final RouteStop stop;
  final VoidCallback onUndo;
  final bool isUndoing;

  const UndoDeliveryBanner({
    super.key,
    required this.stop,
    required this.onUndo,
    this.isUndoing = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (stop.deliveryTimestamp == null) {
      return const SizedBox.shrink();
    }

    final currentClock =
        ref.watch(currentTimeProvider).value ?? DateTime.now();
    final elapsedSeconds =
        currentClock.difference(stop.deliveryTimestamp!).inSeconds;
    final remainingSeconds =
        AppConstants.undoDeliveryWindowSeconds - elapsedSeconds;

    if (remainingSeconds <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: const Row(
          children: [
            Icon(Icons.lock_outline_rounded,
                size: 18, color: AppTheme.textSecondary),
            SizedBox(width: 8),
            Text(
              'Delivery permanently locked (60s undo window expired).',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.warningOrange.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.warningOrange.withAlpha(90)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.timer_outlined,
            size: 20,
            color: Color(0xFFD97706),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery Completed',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD97706),
                  ),
                ),
                Text(
                  'Undo available: ${remainingSeconds}s remaining',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: isUndoing ? null : onUndo,
            icon: isUndoing
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.undo_rounded, size: 16),
            label: const Text('Undo', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
