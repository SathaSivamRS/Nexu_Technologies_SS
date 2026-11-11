import 'package:flutter/material.dart';
import '../../../../app/theme.dart';
import '../../../../core/constants/app_constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Application'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryNavy,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryNavy.withAlpha(50),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: Colors.white,
                  size: 54,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryNavy,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Version ${AppConstants.appVersion}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Metadata Card
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow(
                      'Application',
                      AppConstants.appName,
                      Icons.apps_rounded,
                    ),
                    const Divider(height: 20),
                    _buildInfoRow(
                      'Developer',
                      AppConstants.developerName,
                      Icons.person_rounded,
                    ),
                    const Divider(height: 20),
                    _buildInfoRow(
                      'Assessment',
                      AppConstants.assessmentTitle,
                      Icons.assignment_rounded,
                    ),
                    const Divider(height: 20),
                    _buildInfoRow(
                      'Company',
                      AppConstants.companyName,
                      Icons.business_rounded,
                    ),
                    const Divider(height: 20),
                    _buildInfoRow(
                      'Assessment Date',
                      AppConstants.assessmentReceivedDate,
                      Icons.calendar_today_rounded,
                    ),
                    const Divider(height: 20),
                    _buildInfoRow(
                      'Received Time',
                      AppConstants.assessmentReceivedTime,
                      Icons.access_time_rounded,
                    ),
                    const Divider(height: 20),
                    _buildInfoRow(
                      'Version',
                      AppConstants.appVersion,
                      Icons.info_outline_rounded,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Assessment Architecture Summary Card
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Architecture & Tech Highlights',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildBullet('Clean Architecture: Presentation, Domain, Data, Core.'),
                    _buildBullet('State Management: Riverpod 2.x.'),
                    _buildBullet('Local Persistence: Hive with JSON serialization.'),
                    _buildBullet('Offline Sync: Optimistic UI with per-stop strict ordering.'),
                    _buildBullet('Idempotency: Persistent UUID request IDs.'),
                    _buildBullet('Exponential Backoff: 2s, 4s, 8s retry schedule with Needs Attention fallback.'),
                    _buildBullet('Deterministic Sorting: Window start, Urgent priority, tie-breaker.'),
                    _buildBullet('60-Second Real-Time Elapsed Delivery Undo with countdown.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondaryBlue)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.secondaryBlue),
        const SizedBox(width: 12),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
