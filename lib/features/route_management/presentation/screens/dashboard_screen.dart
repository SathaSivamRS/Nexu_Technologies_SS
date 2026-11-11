import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme.dart';
import '../../../../core/enums/workflow_status.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/utils/date_time_formatter.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../stop_workflow/presentation/screens/stop_detail_screen.dart';
import '../../../synchronization/presentation/providers/sync_providers.dart';
import '../providers/filter_providers.dart';
import '../providers/route_providers.dart';
import '../widgets/route_stop_card.dart';
import '../widgets/summary_metric_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final metrics = ref.watch(routeMetricsProvider);
    final stops = ref.watch(filteredStopsProvider);
    final routeState = ref.watch(routeStopsNotifierProvider);
    final isOffline = ref.watch(offlineModeProvider);
    final isSyncProcessing = ref.watch(syncEngineProvider).isProcessing;
    final unsyncedCount = ref.watch(unsyncedActionsProvider).length;
    final activeStop = ref.watch(activeStopProvider);
    final currentClock =
        ref.watch(currentTimeProvider).value ?? DateTime.now();

    final agentName = authState.session?.agentName ?? 'Asha';

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(routeStopsNotifierProvider.notifier).reload();
            await ref.read(syncEngineProvider).processEligibleQueue();
          },
          child: CustomScrollView(
            slivers: [
              // Top Header Bar
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  color: AppTheme.primaryNavy,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.local_shipping_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Good morning, $agentName.',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.schedule,
                                        size: 13, color: Color(0xFF94A3B8)),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${DateTimeFormatter.displayTimeFormat.format(currentClock)}${ref.watch(clockServiceProvider).isSimulated ? " (Demo Clock)" : ""}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF94A3B8),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Offline Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isOffline
                                  ? AppTheme.errorRed.withAlpha(50)
                                  : AppTheme.successGreen.withAlpha(50),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isOffline
                                    ? AppTheme.errorRed
                                    : AppTheme.successGreen,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isOffline
                                      ? Icons.wifi_off_rounded
                                      : Icons.wifi_rounded,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isOffline ? 'OFFLINE' : 'ONLINE',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Sync Activity Indicator
                          if (isSyncProcessing)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          else if (unsyncedCount > 0)
                            GestureDetector(
                              onTap: () {
                                ref.read(syncEngineProvider).processEligibleQueue();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.warningOrange,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$unsyncedCount sync',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Metrics Cards Row
                      Row(
                        children: [
                          Expanded(
                            child: SummaryMetricCard(
                              title: 'Total Stops',
                              value: '${metrics.totalStops}',
                              icon: Icons.list_alt_rounded,
                              color: AppTheme.primaryNavy,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SummaryMetricCard(
                              title: 'Delivered',
                              value: '${metrics.deliveredCount}',
                              icon: Icons.check_circle_outline_rounded,
                              color: AppTheme.successGreen,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SummaryMetricCard(
                              title: 'Failed',
                              value: '${metrics.failedCount + metrics.returnedToHubCount}',
                              icon: Icons.cancel_outlined,
                              color: AppTheme.errorRed,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SummaryMetricCard(
                              title: 'Remaining',
                              value: '${metrics.remainingCount}',
                              icon: Icons.pending_actions_rounded,
                              color: AppTheme.secondaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Active Stop Banner (R1)
              if (activeStop != null)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryBlue.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.secondaryBlue),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.navigation_rounded,
                          color: AppTheme.secondaryBlue,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ACTIVE STOP: ${activeStop.id} – ${activeStop.customerName}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppTheme.secondaryBlue,
                                ),
                              ),
                              Text(
                                activeStop.address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    StopDetailScreen(stopId: activeStop.id),
                              ),
                            );
                          },
                          child: const Text('VIEW'),
                        ),
                      ],
                    ),
                  ),
                ),

              // Search & Filters Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    children: [
                      // Search Bar
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Search customer, address, or stop ID...',
                          prefixIcon:
                              const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: ref.watch(searchQueryProvider).isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded,
                                      size: 18),
                                  onPressed: () {
                                    ref
                                        .read(searchQueryProvider.notifier)
                                        .state = '';
                                  },
                                )
                              : null,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                        ),
                        onChanged: (val) {
                          ref.read(searchQueryProvider.notifier).state = val;
                        },
                      ),
                      const SizedBox(height: 8),

                      // Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip(
                              label: 'All',
                              isSelected:
                                  ref.watch(statusFilterProvider) == null,
                              onSelected: () {
                                ref.read(statusFilterProvider.notifier).state =
                                    null;
                              },
                            ),
                            ...WorkflowStatus.values.map((status) {
                              final isSelected =
                                  ref.watch(statusFilterProvider) == status;
                              return Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: _buildFilterChip(
                                  label: status.label,
                                  isSelected: isSelected,
                                  onSelected: () {
                                    ref
                                        .read(statusFilterProvider.notifier)
                                        .state = isSelected ? null : status;
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Stops List
              if (routeState.isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (stops.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No delivery stops match your filter.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            ref.read(searchQueryProvider.notifier).state = '';
                            ref.read(statusFilterProvider.notifier).state = null;
                          },
                          child: const Text('Clear Filters'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final stop = stops[index];
                      return RouteStopCard(
                        stop: stop,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  StopDetailScreen(stopId: stop.id),
                            ),
                          );
                        },
                      );
                    },
                    childCount: stops.length,
                  ),
                ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : AppTheme.textPrimary,
        ),
      ),
      selected: isSelected,
      selectedColor: AppTheme.primaryNavy,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppTheme.primaryNavy : AppTheme.borderColor,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      onSelected: (_) => onSelected(),
    );
  }
}
