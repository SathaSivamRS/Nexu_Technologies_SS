import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme.dart';
import '../../../../core/enums/priority.dart';
import '../../../../core/enums/workflow_status.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/utils/date_time_formatter.dart';
import '../../../route_management/domain/entities/route_stop.dart';
import '../../../route_management/domain/services/time_alert_evaluator.dart';
import '../../../route_management/presentation/providers/route_providers.dart';
import '../../../route_management/presentation/widgets/sync_status_badge.dart';
import '../../../route_management/presentation/widgets/time_alert_badge.dart';
import '../../../synchronization/presentation/providers/sync_providers.dart';
import '../providers/workflow_provider.dart';
import 'delivery_confirmation_sheet.dart';
import 'failure_report_sheet.dart';
import 'undo_delivery_banner.dart';

class StopDetailSheet extends ConsumerStatefulWidget {
  final String stopId;

  const StopDetailSheet({super.key, required this.stopId});

  @override
  ConsumerState<StopDetailSheet> createState() => _StopDetailSheetState();
}

class _StopDetailSheetState extends ConsumerState<StopDetailSheet> {
  bool _isLoading = false;

  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.errorRed : AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _markArrived(RouteStop stop) async {
    setState(() => _isLoading = true);
    try {
      final workflow = ref.read(workflowServiceProvider);
      await workflow.markArrived(stop.id);
      await ref.read(routeStopsNotifierProvider.notifier).reload();
      _showSnackBar('Marked ${stop.id} as Arrived.');
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openDeliverySheet(RouteStop stop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DeliveryConfirmationSheet(
        stop: stop,
        onConfirm: (recipientName, confirmedPackages) async {
          final workflow = ref.read(workflowServiceProvider);
          await workflow.markDelivered(
            stopId: stop.id,
            recipientName: recipientName,
            confirmedPackages: confirmedPackages,
          );
          await ref.read(routeStopsNotifierProvider.notifier).reload();
          _showSnackBar('Delivery confirmed for ${stop.id}!');
        },
      ),
    );
  }

  void _openFailureSheet(RouteStop stop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FailureReportSheet(
        stop: stop,
        onConfirm: (reason, note) async {
          final workflow = ref.read(workflowServiceProvider);
          await workflow.markFailed(
            stopId: stop.id,
            reason: reason,
            note: note,
          );
          await ref.read(routeStopsNotifierProvider.notifier).reload();
          _showSnackBar('Delivery failure recorded for ${stop.id}.');
        },
      ),
    );
  }

  Future<void> _handleUndo(RouteStop stop) async {
    setState(() => _isLoading = true);
    try {
      final workflow = ref.read(workflowServiceProvider);
      await workflow.undoDelivered(stop.id);
      await ref.read(routeStopsNotifierProvider.notifier).reload();
      _showSnackBar('Delivery undone for ${stop.id}. Restored to active.');
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stop = ref.watch(stopByIdProvider(widget.stopId));
    final currentClock =
        ref.watch(currentTimeProvider).value ?? DateTime.now();

    if (stop == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: const Center(child: Text('Stop not found')),
      );
    }

    final timeAlert = TimeAlertEvaluator.evaluate(stop, currentClock);
    final syncStatus = ref.watch(stopSyncStatusProvider(stop.id));
    final isUrgent = stop.priority == StopPriority.urgent;
    final isArrived = stop.status == WorkflowStatus.arrived;
    final isDelivered = stop.status == WorkflowStatus.delivered;
    final isFailed = stop.status == WorkflowStatus.failed;
    final isReturned = stop.status == WorkflowStatus.returnedToHub;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle & top bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryNavy,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        stop.id,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isUrgent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.errorRed.withAlpha(25),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: AppTheme.errorRed.withAlpha(120)),
                        ),
                        child: const Text(
                          'URGENT',
                          style: TextStyle(
                            color: AppTheme.errorRed,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const Spacer(),
                    TimeAlertBadge(alert: timeAlert),
                    const SizedBox(width: 6),
                    SyncStatusBadge(status: syncStatus),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable stop detail body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Undo Banner if Delivered (R5)
                  if (isDelivered) ...[
                    UndoDeliveryBanner(
                      stop: stop,
                      onUndo: () => _handleUndo(stop),
                      isUndoing: _isLoading,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Customer name & full address
                  Text(
                    stop.customerName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          stop.address,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Metadata Cards (Packages, Window, Priority)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildDetailItem(
                          'Expected Packages',
                          '${stop.expectedPackages} pkg(s)',
                          Icons.inventory_2_outlined,
                        ),
                        _buildDetailItem(
                          'Delivery Window',
                          '${stop.windowStart} – ${stop.windowEnd}',
                          Icons.schedule_rounded,
                        ),
                        _buildDetailItem(
                          'Priority',
                          stop.priority.label,
                          Icons.flag_outlined,
                          isUrgent ? AppTheme.errorRed : AppTheme.textPrimary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Workflow Status Info
                  Row(
                    children: [
                      const Text(
                        'Current Status: ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _getStatusColor(stop.status).withAlpha(25),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: _getStatusColor(stop.status).withAlpha(90)),
                        ),
                        child: Text(
                          stop.status.label,
                          style: TextStyle(
                            color: _getStatusColor(stop.status),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (stop.isRetry) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.warningOrange.withAlpha(30),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Retry: ${stop.failureCount}/2',
                            style: const TextStyle(
                              color: Color(0xFFD97706),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (isDelivered && stop.recipientName != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Received by: ${stop.recipientName} (${stop.confirmedPackages} pkgs)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.successGreen,
                      ),
                    ),
                  ],
                  if (stop.lastFailureReason != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Failure: ${stop.lastFailureReason!.label}${stop.lastFailureNote != null ? " (\"${stop.lastFailureNote}\")" : ""}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.errorRed,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Attempt History Audit Trail
                  const Text(
                    'Delivery History Audit Trail',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (stop.history.isEmpty)
                    const Text(
                      'No actions recorded yet for this stop.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: stop.history.length,
                      separatorBuilder: (ctx, i) => const Divider(height: 12),
                      itemBuilder: (context, index) {
                        final entry = stop.history[index];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 3),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _getStatusColor(entry.status),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        entry.status.label,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: _getStatusColor(entry.status),
                                        ),
                                      ),
                                      Text(
                                        DateTimeFormatter.formatFull(
                                            entry.timestamp),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (entry.note != null)
                                    Text(
                                      entry.note!,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  const SizedBox(height: 20),

                  // Action Buttons
                  if (!isDelivered && !isReturned) ...[
                    if (stop.status == WorkflowStatus.pending || isFailed)
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondaryBlue,
                          ),
                          onPressed: _isLoading ? null : () => _markArrived(stop),
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.navigation_rounded, size: 18),
                          label: Text(
                            isFailed ? 'Retry & Mark Arrived' : 'Mark Arrived',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    if (isArrived) ...[
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.successGreen,
                                ),
                                onPressed: () => _openDeliverySheet(stop),
                                icon: const Icon(Icons.check_circle_outline,
                                    size: 18),
                                label: const Text(
                                  'Complete Delivery',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.errorRed,
                                  side:
                                      const BorderSide(color: AppTheme.errorRed),
                                ),
                                onPressed: () => _openFailureSheet(stop),
                                icon: const Icon(Icons.cancel_outlined,
                                    size: 18),
                                label: const Text(
                                  'Report Failure',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(
    String label,
    String value,
    IconData icon, [
    Color? valueColor,
  ]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(WorkflowStatus status) {
    switch (status) {
      case WorkflowStatus.pending:
        return const Color(0xFF64748B);
      case WorkflowStatus.arrived:
        return AppTheme.secondaryBlue;
      case WorkflowStatus.delivered:
        return AppTheme.successGreen;
      case WorkflowStatus.failed:
        return const Color(0xFFD97706);
      case WorkflowStatus.returnedToHub:
        return AppTheme.errorRed;
    }
  }
}
