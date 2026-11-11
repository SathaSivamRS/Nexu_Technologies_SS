import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme.dart';
import '../../../../core/enums/sync_status.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/utils/date_time_formatter.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../route_management/presentation/providers/route_providers.dart';
import '../../../synchronization/presentation/providers/sync_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final clockService = ref.watch(clockServiceProvider);
    final currentClock =
        ref.watch(currentTimeProvider).value ?? DateTime.now();
    final isOffline = ref.watch(offlineModeProvider);
    final failureRate = ref.watch(mockFailureRateProvider);
    final syncEngine = ref.read(syncEngineProvider);
    final queue = ref.watch(unsyncedActionsProvider);

    final queueCount = queue.length;
    final pendingCount =
        queue.where((a) => a.status == SyncStatus.pending).length;
    final retryingCount =
        queue.where((a) => a.status == SyncStatus.retrying).length;
    final attentionCount =
        queue.where((a) => a.status == SyncStatus.needsAttention).length;

    final agentName = authState.session?.agentName ?? 'Asha';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section A: Network Configuration
          _buildSectionHeader('A. NETWORK CONFIGURATION'),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(
                    isOffline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
                    color:
                        isOffline ? AppTheme.errorRed : AppTheme.successGreen,
                  ),
                  title: const Text(
                    'Offline Mode',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    isOffline
                        ? 'State: OFFLINE. All server requests fail; operations queue locally.'
                        : 'State: ONLINE. Real-time background sync is active.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isOffline ? AppTheme.errorRed : AppTheme.textSecondary,
                    ),
                  ),
                  value: isOffline,
                  onChanged: (val) {
                    syncEngine.setOfflineMode(val);
                  },
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Mock Server Failure Rate:',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${(failureRate * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.secondaryBlue,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: failureRate.clamp(0.0, 1.0),
                        min: 0.0,
                        max: 1.0,
                        divisions: 20,
                        label: '${(failureRate * 100).round()}%',
                        onChanged: (val) {
                          final rounded = (val * 100).round() / 100.0;
                          ref.read(mockFailureRateProvider.notifier).state =
                              rounded;
                        },
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                              ),
                              onPressed: () {
                                ref
                                    .read(mockFailureRateProvider.notifier)
                                    .state = 0.0;
                              },
                              child: const Text('0% Pass',
                                  style: TextStyle(fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                              ),
                              onPressed: () {
                                ref
                                    .read(mockFailureRateProvider.notifier)
                                    .state = 0.30;
                              },
                              child: const Text('30% Default',
                                  style: TextStyle(fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                              ),
                              onPressed: () {
                                ref
                                    .read(mockFailureRateProvider.notifier)
                                    .state = 1.0;
                              },
                              child: const Text('100% Fail',
                                  style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section B: Demo Clock
          _buildSectionHeader('B. DEMO CLOCK SIMULATION'),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time_filled_rounded,
                          color: AppTheme.secondaryBlue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        clockService.isSimulated
                            ? 'Simulated Clock (Active)'
                            : 'Actual Device Clock (Real)',
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
                  // Current simulated time display
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Column(
                      children: [
                        Text(
                          DateTimeFormatter.displayTimeFormat
                              .format(currentClock),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryNavy,
                          ),
                        ),
                        Text(
                          DateTimeFormatter.displayDateFormat
                              .format(currentClock),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Date & Time pickers
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today_rounded,
                              size: 16),
                          label: const Text('Select Date'),
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
                          label: const Text('Select Time'),
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

          // Section C: Synchronization Diagnostics
          _buildSectionHeader('C. SYNCHRONIZATION DIAGNOSTICS'),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDiagRow('Total Queued Actions', '$queueCount',
                      Icons.storage_rounded, AppTheme.primaryNavy),
                  const Divider(height: 16),
                  _buildDiagRow('Pending Actions', '$pendingCount',
                      Icons.schedule_rounded, const Color(0xFF64748B)),
                  const Divider(height: 16),
                  _buildDiagRow('Retrying Actions', '$retryingCount',
                      Icons.sync_rounded, const Color(0xFFD97706)),
                  const Divider(height: 16),
                  _buildDiagRow('Needs Attention Actions', '$attentionCount',
                      Icons.error_outline_rounded, AppTheme.errorRed),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        syncEngine.processEligibleQueue();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Force sync initiated for queue.'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      icon: const Icon(Icons.sync_rounded, size: 18),
                      label: const Text('Force Sync Queue Now'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Section D: Account & Data Management
          _buildSectionHeader('D. ACCOUNT & DATA MANAGEMENT'),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.account_circle_outlined,
                      color: AppTheme.secondaryBlue),
                  title: const Text('Signed-In Agent',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text(agentName,
                      style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restore_page_outlined,
                      color: AppTheme.warningOrange),
                  title: const Text('Reset Route to Initial JSON'),
                  subtitle: const Text('Reloads original 14 stops',
                      style: TextStyle(fontSize: 12)),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Reset Route Data?'),
                        content: const Text(
                            'This will discard local stop mutations and reload the initial 14 stops from route_stops.json.'),
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
                      fontSize: 14,
                    ),
                  ),
                  subtitle: const Text('Clear session and return to sign in',
                      style: TextStyle(fontSize: 12)),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Sign Out?'),
                        content: const Text(
                            'Are you sure you want to sign out? Your queued sync actions and route state will remain safely preserved in Hive.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.errorRed,
                            ),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Sign Out'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref.read(authNotifierProvider.notifier).signOut();
                    }
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
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.textSecondary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildDiagRow(
      String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
