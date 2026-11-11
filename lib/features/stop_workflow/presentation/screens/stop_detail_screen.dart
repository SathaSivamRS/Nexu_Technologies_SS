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
import '../widgets/delivery_confirmation_sheet.dart';
import '../widgets/failure_report_sheet.dart';
import '../widgets/undo_delivery_banner.dart';

class StopDetailScreen extends ConsumerStatefulWidget {
  final String stopId;

  const StopDetailScreen({super.key, required this.stopId});

  @override
  ConsumerState<StopDetailScreen> createState() => _StopDetailScreenState();
}

class _StopDetailScreenState extends ConsumerState<StopDetailScreen> {
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
      return Scaffold(
        appBar: AppBar(title: const Text('Stop Details')),
        body: const Center(child: Text('Stop not found')),
      );
    }

    final timeAlert = TimeAlertEvaluator.evaluate(stop, currentClock);
    final syncStatus = ref.watch(stopSyncStatusProvider(stop.id));
    final isUrgent = stop.priority == StopPriority.urgent;
    final isArrived = stop.status == WorkflowStatus.arrived;
    final isDelivered = stop.status == WorkflowStatus.delivered;
    final isFailed = stop.status == WorkflowStatus.failed;
    final isReturned = stop.status == WorkflowStatus.returnedToHub;

    return Scaffold(
      appBar: AppBar(
        title: Text('${stop.id} – Details'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: SyncStatusBadge(status: syncStatus)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Undo Banner if Delivered
            if (isDelivered) ...[
              UndoDeliveryBanner(
                stop: stop,
                onUndo: () => _handleUndo(stop),
                isUndoing: _isLoading,
              ),
              const SizedBox(height: 16),
            ],

            // Customer Card
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                            ],
                          ),
                        ),
                        TimeAlertBadge(alert: timeAlert),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildDetailItem(
                          'Expected Packages',
                          '${stop.expectedPackages}',
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Workflow Status & Metadata Card
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Workflow Status',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(stop.status).withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: _getStatusColor(stop.status)
                                    .withAlpha(90)),
                          ),
                          child: Text(
                            stop.status.label,
                            style: TextStyle(
                              color: _getStatusColor(stop.status),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (stop.isRetry)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.warningOrange.withAlpha(30),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Retry Attempt: ${stop.failureCount} of 2',
                              style: const TextStyle(
                                color: Color(0xFFD97706),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (isDelivered && stop.recipientName != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Received by: ${stop.recipientName} (${stop.confirmedPackages} pkgs confirmed)',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.successGreen,
                        ),
                      ),
                      if (stop.deliveryTimestamp != null)
                        Text(
                          'Delivered at: ${DateTimeFormatter.formatFull(stop.deliveryTimestamp!)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                    ],
                    if (stop.lastFailureReason != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Failure Reason: ${stop.lastFailureReason!.label}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.errorRed,
                        ),
                      ),
                      if (stop.lastFailureNote != null &&
                          stop.lastFailureNote!.isNotEmpty)
                        Text(
                          'Note: "${stop.lastFailureNote}"',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Attempt History
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Delivery History Audit Trail',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (stop.history.isEmpty)
                      const Text(
                        'No actions recorded yet for this stop.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: stop.history.length,
                        separatorBuilder: (ctx, i) =>
                            const Divider(height: 16),
                        itemBuilder: (context, index) {
                          final entry = stop.history[index];
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _getStatusColor(entry.status),
                                ),
                              ),
                              const SizedBox(width: 10),
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
                                            fontSize: 13,
                                            color:
                                                _getStatusColor(entry.status),
                                          ),
                                        ),
                                        Text(
                                          DateTimeFormatter.formatFull(
                                              entry.timestamp),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (entry.note != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        entry.note!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            if (!isDelivered && !isReturned) ...[
              if (stop.status == WorkflowStatus.pending || isFailed)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryBlue,
                    ),
                    onPressed: _isLoading ? null : () => _markArrived(stop),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.navigation_rounded),
                    label: Text(
                      isFailed ? 'Retry & Mark Arrived' : 'Mark Arrived',
                      style: const TextStyle(
                        fontSize: 15,
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
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successGreen,
                          ),
                          onPressed: () => _openDeliverySheet(stop),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text(
                            'Complete Delivery',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.errorRed,
                            side: const BorderSide(color: AppTheme.errorRed),
                          ),
                          onPressed: () => _openFailureSheet(stop),
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text(
                            'Report Failure',
                            style: TextStyle(
                              fontSize: 14,
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
            const SizedBox(height: 32),
          ],
        ),
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
            Icon(icon, size: 14, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
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
