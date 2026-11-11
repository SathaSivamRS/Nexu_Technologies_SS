import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme.dart';
import '../../../../core/enums/priority.dart';
import '../../../../core/enums/workflow_status.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../stop_workflow/presentation/providers/workflow_provider.dart';
import '../../../stop_workflow/presentation/widgets/delivery_confirmation_sheet.dart';
import '../../../stop_workflow/presentation/widgets/failure_report_sheet.dart';
import '../../../synchronization/presentation/providers/sync_providers.dart';
import '../../domain/entities/route_stop.dart';
import '../../domain/services/time_alert_evaluator.dart';
import '../providers/route_providers.dart';
import 'sync_status_badge.dart';
import 'time_alert_badge.dart';

class RouteStopCard extends ConsumerStatefulWidget {
  final RouteStop stop;
  final VoidCallback onTap;

  const RouteStopCard({
    super.key,
    required this.stop,
    required this.onTap,
  });

  @override
  ConsumerState<RouteStopCard> createState() => _RouteStopCardState();
}

class _RouteStopCardState extends ConsumerState<RouteStopCard> {
  bool _isActionLoading = false;

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleMarkArrived() async {
    setState(() => _isActionLoading = true);
    try {
      final workflowService = ref.read(workflowServiceProvider);
      await workflowService.markArrived(widget.stop.id);
      ref.read(routeStopsNotifierProvider.notifier).reload();
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  void _openDeliverySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DeliveryConfirmationSheet(
        stop: widget.stop,
        onConfirm: (recipientName, confirmedPackages) async {
          final workflowService = ref.read(workflowServiceProvider);
          await workflowService.markDelivered(
            stopId: widget.stop.id,
            recipientName: recipientName,
            confirmedPackages: confirmedPackages,
          );
          ref.read(routeStopsNotifierProvider.notifier).reload();
        },
      ),
    );
  }

  void _openFailureSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FailureReportSheet(
        stop: widget.stop,
        onConfirm: (reason, note) async {
          final workflowService = ref.read(workflowServiceProvider);
          await workflowService.markFailed(
            stopId: widget.stop.id,
            reason: reason,
            note: note,
          );
          ref.read(routeStopsNotifierProvider.notifier).reload();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentClock =
        ref.watch(currentTimeProvider).value ?? DateTime.now();
    final timeAlert = TimeAlertEvaluator.evaluate(widget.stop, currentClock);
    final syncStatus = ref.watch(stopSyncStatusProvider(widget.stop.id));

    final isUrgent = widget.stop.priority == StopPriority.urgent;
    final isArrived = widget.stop.status == WorkflowStatus.arrived;
    final isDelivered = widget.stop.status == WorkflowStatus.delivered;
    final isReturned = widget.stop.status == WorkflowStatus.returnedToHub;
    final isFailed = widget.stop.status == WorkflowStatus.failed;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isArrived
              ? AppTheme.secondaryBlue
              : (isUrgent ? AppTheme.warningOrange.withAlpha(120) : AppTheme.borderColor),
          width: isArrived ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Stop ID, Priority Badge, Time Alert, Sync Badge
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryNavy,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      widget.stop.id,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (isUrgent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.errorRed.withAlpha(25),
                        borderRadius: BorderRadius.circular(5),
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
                  if (widget.stop.isRetry) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.warningOrange.withAlpha(30),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        'RETRY (${widget.stop.failureCount})',
                        style: const TextStyle(
                          color: Color(0xFFD97706),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  TimeAlertBadge(alert: timeAlert),
                  const SizedBox(width: 6),
                  SyncStatusBadge(status: syncStatus),
                ],
              ),
              const SizedBox(height: 10),

              // Customer Name & Workflow Status Tag
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.stop.customerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  _buildStatusChip(widget.stop.status),
                ],
              ),
              const SizedBox(height: 6),

              // Address
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.stop.address,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Packages & Window Info
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined,
                        size: 15, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.stop.expectedPackages} pkg(s)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.schedule,
                        size: 15, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.stop.windowStart} – ${widget.stop.windowEnd}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              // Quick Actions Bar
              if (!isDelivered && !isReturned) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (widget.stop.status == WorkflowStatus.pending ||
                        isFailed) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            side: const BorderSide(color: AppTheme.secondaryBlue),
                            foregroundColor: AppTheme.secondaryBlue,
                          ),
                          onPressed:
                              _isActionLoading ? null : _handleMarkArrived,
                          icon: _isActionLoading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Icon(Icons.navigation_rounded, size: 16),
                          label: Text(
                            isFailed ? 'Retry & Arrive' : 'Mark Arrived',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                    if (isArrived) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successGreen,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          onPressed: _openDeliverySheet,
                          icon: const Icon(Icons.check_circle_outline,
                              size: 16),
                          label: const Text('Complete',
                              style: TextStyle(fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.errorRed,
                            side: const BorderSide(color: AppTheme.errorRed),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          onPressed: _openFailureSheet,
                          icon: const Icon(Icons.cancel_outlined, size: 16),
                          label: const Text('Failed',
                              style: TextStyle(fontSize: 13)),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(WorkflowStatus status) {
    Color color;
    switch (status) {
      case WorkflowStatus.pending:
        color = const Color(0xFF64748B);
        break;
      case WorkflowStatus.arrived:
        color = AppTheme.secondaryBlue;
        break;
      case WorkflowStatus.delivered:
        color = AppTheme.successGreen;
        break;
      case WorkflowStatus.failed:
        color = const Color(0xFFD97706);
        break;
      case WorkflowStatus.returnedToHub:
        color = AppTheme.errorRed;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
