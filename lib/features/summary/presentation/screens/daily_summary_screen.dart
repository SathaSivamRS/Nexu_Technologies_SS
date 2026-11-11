import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme.dart';
import '../../../../core/enums/sync_status.dart';
import '../../../../core/utils/date_time_formatter.dart';
import '../../../route_management/presentation/widgets/sync_status_badge.dart';
import '../../../synchronization/presentation/providers/sync_providers.dart';
import '../providers/summary_provider.dart';

class DailySummaryScreen extends ConsumerWidget {
  const DailySummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dailySummaryProvider);
    final syncEngine = ref.read(syncEngineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Performance & Sync Summary'),
        actions: [
          if (summary.unsyncedActions.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.sync_rounded),
              tooltip: 'Sync All Queued',
              onPressed: () {
                syncEngine.processEligibleQueue();
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Overview Cards
            const Text(
              'Route Performance KPIs',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    'Success Rate',
                    '${summary.successRate.toStringAsFixed(1)}%',
                    '${summary.deliveredCount} / ${summary.totalStops} delivered',
                    Icons.trending_up_rounded,
                    summary.successRate >= 80
                        ? AppTheme.successGreen
                        : (summary.successRate >= 50
                            ? const Color(0xFFD97706)
                            : AppTheme.errorRed),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    'On-Time Rate',
                    '${summary.onTimeRate.toStringAsFixed(1)}%',
                    '${summary.onTimeDeliveredCount} / ${summary.deliveredCount} on-time',
                    Icons.alarm_on_rounded,
                    summary.onTimeRate >= 80
                        ? AppTheme.successGreen
                        : (summary.onTimeRate >= 50
                            ? const Color(0xFFD97706)
                            : AppTheme.errorRed),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Stop Status Breakdown
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildRowItem('Total Scheduled Stops', '${summary.totalStops}',
                        Icons.local_shipping_outlined),
                    const Divider(height: 16),
                    _buildRowItem('Successfully Delivered',
                        '${summary.deliveredCount}', Icons.check_circle_outline,
                        color: AppTheme.successGreen),
                    const Divider(height: 16),
                    _buildRowItem('Delivery Failed (Retry)',
                        '${summary.failedCount}', Icons.replay_rounded,
                        color: const Color(0xFFD97706)),
                    const Divider(height: 16),
                    _buildRowItem('Returned to Hub (Final)',
                        '${summary.returnedToHubCount}', Icons.block_rounded,
                        color: AppTheme.errorRed),
                    const Divider(height: 16),
                    _buildRowItem('Remaining Active Stops',
                        '${summary.remainingCount}', Icons.pending_actions_rounded,
                        color: AppTheme.secondaryBlue),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Sync Queue Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Unsynced Offline Queue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '${summary.pendingSyncCount} pending, ${summary.needsAttentionCount} require attention',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (summary.needsAttentionCount > 0)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorRed,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                    ),
                    onPressed: () {
                      syncEngine.manualRetryAll();
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 14),
                    label: const Text('Retry All',
                        style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (summary.unsyncedActions.isEmpty)
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.cloud_done_rounded,
                          size: 44,
                          color: AppTheme.successGreen,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'All actions are fully synced!',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'No pending offline operations in the queue.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: summary.unsyncedActions.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final action = summary.unsyncedActions[index];
                  final isAttention =
                      action.status == SyncStatus.needsAttention;

                  return Card(
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isAttention
                            ? AppTheme.errorRed
                            : AppTheme.borderColor,
                        width: isAttention ? 1.5 : 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryNavy,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  action.stopId,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                action.actionType,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              SyncStatusBadge(status: action.status),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Created: ${DateTimeFormatter.formatFull(action.createdAt)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              Text(
                                'Retry Attempt: ${action.retryCount} / 3',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          if (action.lastError != null) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.errorRed.withAlpha(20),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Error: ${action.lastError}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.errorRed,
                                ),
                              ),
                            ),
                          ],
                          if (isAttention) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.errorRed,
                                  side: const BorderSide(
                                      color: AppTheme.errorRed),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                ),
                                onPressed: () {
                                  syncEngine.manualRetryAction(action.id);
                                },
                                icon: const Icon(Icons.refresh_rounded,
                                    size: 14),
                                label: const Text('Manual Retry',
                                    style: TextStyle(fontSize: 12)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(
    String label,
    String value,
    String sublabel,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sublabel,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRowItem(String title, String value, IconData icon,
      {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? AppTheme.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color ?? AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
