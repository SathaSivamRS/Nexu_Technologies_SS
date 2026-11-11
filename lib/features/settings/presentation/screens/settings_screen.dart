import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/utils/date_time_formatter.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../route_management/presentation/providers/route_providers.dart';
import '../../../synchronization/presentation/providers/sync_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clockService = ref.watch(clockServiceProvider);
    final currentClock =
        ref.watch(currentTimeProvider).value ?? DateTime.now();
    final isOffline = ref.watch(offlineModeProvider);
    final failureRate = ref.watch(mockFailureRateProvider);
    final syncEngine = ref.read(syncEngineProvider);
    final mockServer = ref.watch(mockServerProvider);
    final queue = ref.watch(unsyncedActionsProvider);
    final processedIds = mockServer.getProcessedRequestIds();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Diagnostics'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section 1: Offline Mode
          _buildSectionHeader('Network Connectivity Simulation'),
          Card(
            margin: EdgeInsets.zero,
            child: SwitchListTile(
              secondary: Icon(
                isOffline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
                color: isOffline ? AppTheme.errorRed : AppTheme.successGreen,
              ),
              title: const Text(
                'Offline Mode',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: Text(
                isOffline
                    ? 'All server sync requests are currently blocked. Actions queue locally.'
                    : 'Device is connected. Queued actions auto-sync in sequence.',
                style: const TextStyle(fontSize: 12),
              ),
              value: isOffline,
              onChanged: (val) {
                syncEngine.setOfflineMode(val);
              },
            ),
          ),
          const SizedBox(height: 20),

          // Section 2: Demo Clock Controls
          _buildSectionHeader('Demo Clock Simulation (Section 6)'),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time_filled,
                          color: AppTheme.secondaryBlue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        clockService.isSimulated
                            ? 'Simulated Clock Active'
                            : 'Actual Device Clock Active',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      if (clockService.isSimulated)
                        TextButton(
                          onPressed: () {
                            clockService.resetToActualTime();
                          },
                          child: const Text('Reset to Real Time'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Text(
                      '${DateTimeFormatter.displayDateFormat.format(currentClock)}  •  ${DateTimeFormatter.displayTimeFormat.format(currentClock)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Quick Step Buttons
                  const Text(
                    'Quick Adjustments for Time Window Testing:',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          // Jump to 08:45 (Before 09:00 window - Normal)
                          final target = DateTime(
                            currentClock.year,
                            currentClock.month,
                            currentClock.day,
                            8,
                            45,
                          );
                          clockService.setSimulatedTime(target);
                        },
                        child: const Text('Set 08:45 AM (Early)'),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          // Jump to 09:50 (Within 10-15m before 10:00 - At Risk)
                          final target = DateTime(
                            currentClock.year,
                            currentClock.month,
                            currentClock.day,
                            9,
                            50,
                          );
                          clockService.setSimulatedTime(target);
                        },
                        child: const Text('Set 09:50 AM (At Risk)'),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          // Jump to 10:15 (Past 10:00 - Late)
                          final target = DateTime(
                            currentClock.year,
                            currentClock.month,
                            currentClock.day,
                            10,
                            15,
                          );
                          clockService.setSimulatedTime(target);
                        },
                        child: const Text('Set 10:15 AM (Late)'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Pick Date & Time Row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today_rounded,
                              size: 16),
                          label: const Text('Pick Date'),
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: currentClock,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (pickedDate != null) {
                              final updated = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                currentClock.hour,
                                currentClock.minute,
                              );
                              clockService.setSimulatedTime(updated);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.schedule_rounded, size: 16),
                          label: const Text('Pick Time'),
                          onPressed: () async {
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(currentClock),
                            );
                            if (pickedTime != null) {
                              final updated = DateTime(
                                currentClock.year,
                                currentClock.month,
                                currentClock.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );
                              clockService.setSimulatedTime(updated);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Section 3: Mock Server Failure Rate
          _buildSectionHeader('Mock Server Network Reliability (S3)'),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Simulated Failure Rate:',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${(failureRate * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryBlue,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: failureRate,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    label: '${(failureRate * 100).toInt()}%',
                    onChanged: (val) {
                      syncEngine.setFailureRate(val);
                    },
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => syncEngine.setFailureRate(0.0),
                          child: const Text('0% (Pass)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => syncEngine.setFailureRate(0.30),
                          child: const Text('30% (Default)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => syncEngine.setFailureRate(1.0),
                          child: const Text('100% (Fail)'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Section 4: Sync Diagnostics & Idempotency
          _buildSectionHeader('Idempotency & Queue Storage (S5, S7)'),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Local Queued Actions:'),
                      Text(
                        '${queue.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Processed Request IDs (Persistent):'),
                      Text(
                        '${processedIds.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            syncEngine.processEligibleQueue();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Sync triggered for queue!'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          icon: const Icon(Icons.sync_rounded, size: 16),
                          label: const Text('Force Sync'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await mockServer.clearProcessedRequestIds();
                            ref.invalidate(mockServerProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Cleared mock server IDs.'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.delete_outline, size: 16),
                          label: const Text('Clear Server IDs'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Section 5: Data Reset & Sign Out
          _buildSectionHeader('Data Management & Session'),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.restore_page_outlined,
                      color: AppTheme.warningOrange),
                  title: const Text('Reset Route Data to Initial JSON'),
                  subtitle: const Text(
                      'Restores the 14 realistic stops from assets/data/route_stops.json'),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Reset Route Data?'),
                        content: const Text(
                            'This will discard local stop mutations and reload the initial 14 stops.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.warningOrange,
                            ),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref
                          .read(routeStopsNotifierProvider.notifier)
                          .resetRoute();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Route data reset to initial JSON.')),
                        );
                      }
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading:
                      const Icon(Icons.logout_rounded, color: AppTheme.errorRed),
                  title: const Text(
                    'Sign Out',
                    style: TextStyle(
                      color: AppTheme.errorRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text('Clears current agent session'),
                  onTap: () async {
                    await ref.read(authNotifierProvider.notifier).signOut();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppTheme.textSecondary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
