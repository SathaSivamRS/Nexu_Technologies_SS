import 'package:flutter/material.dart';
import '../../../../app/theme.dart';
import '../../../../core/constants/app_constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        title: const Text('About NEXU RouteRunner'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // App Branding Icon & Title
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
                  size: 52,
                ),
              ),
            ),
            const SizedBox(height: 16),
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
              AppConstants.appDescription,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.secondaryBlue.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.secondaryBlue.withAlpha(40)),
              ),
              child: const Text(
                'v${AppConstants.appVersion}+${AppConstants.appBuildNumber}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondaryBlue,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Card 1: Application & Assessment Metadata
            _buildSectionHeader('APPLICATION & CANDIDATE DETAILS'),
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
                    const Divider(height: 18),
                    _buildInfoRow(
                      'Description',
                      AppConstants.appDescription,
                      Icons.description_rounded,
                    ),
                    const Divider(height: 18),
                    _buildInfoRow(
                      'Version',
                      '${AppConstants.appVersion} (Build ${AppConstants.appBuildNumber})',
                      Icons.info_outline_rounded,
                    ),
                    const Divider(height: 18),
                    _buildInfoRow(
                      'Developer',
                      AppConstants.developerName,
                      Icons.person_rounded,
                    ),
                    const Divider(height: 18),
                    _buildInfoRow(
                      'Company',
                      AppConstants.companyName,
                      Icons.business_rounded,
                    ),
                    const Divider(height: 18),
                    _buildInfoRow(
                      'Assessment',
                      AppConstants.assessmentTitle,
                      Icons.assignment_rounded,
                    ),
                    const Divider(height: 18),
                    _buildInfoRow(
                      'Received Date',
                      AppConstants.assessmentReceivedDate,
                      Icons.calendar_today_rounded,
                    ),
                    const Divider(height: 18),
                    _buildInfoRow(
                      'Received Time',
                      AppConstants.assessmentReceivedTime,
                      Icons.access_time_rounded,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Card 2: Technology Stack
            _buildSectionHeader('TECHNOLOGY STACK'),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildTechRow('Framework', 'Flutter 3.41.6 (Channel stable)', Icons.flutter_dash),
                    const Divider(height: 16),
                    _buildTechRow('Language', 'Dart 3.11.4', Icons.code_rounded),
                    const Divider(height: 16),
                    _buildTechRow('State Management', 'Riverpod 2.5.1', Icons.account_tree_rounded),
                    const Divider(height: 16),
                    _buildTechRow('Local Persistence', 'Hive 2.2.3 (5 isolated boxes)', Icons.storage_rounded),
                    const Divider(height: 16),
                    _buildTechRow('Idempotency / UUID', 'uuid 4.4.0 (UUID v4)', Icons.fingerprint_rounded),
                    const Divider(height: 16),
                    _buildTechRow('Date & Time', 'intl 0.19.0', Icons.schedule_rounded),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Card 3: Architecture & Engineering Highlights
            _buildSectionHeader('ENGINEERING HIGHLIGHTS'),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBullet('Clean Architecture: Strict Presentation, Domain, Data & Core layer separation.'),
                    _buildBullet('Stop Workflow Rules (R1–R6): Single active stop, delivered checks, failure escalation, 60s real-elapsed undo, urgent stop protection.'),
                    _buildBullet('Offline Sync Engine (S1–S7): Optimistic UI, exponential backoff (2s, 4s, 8s), per-stop FIFO pipeline, UUID idempotency & restart safety.'),
                    _buildBullet('Interactive Demo Clock: Centralized injectable ClockService for time-window alert simulation.'),
                    _buildBullet('Controlled Mock Server: Dynamic failure-rate slider (0% to 100%) and instant offline mode toggling.'),
                    _buildBullet('Persistent Navigation: 4 dedicated bottom-navigation tabs with preserved state.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondaryBlue, fontSize: 14)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechRow(String category, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.secondaryBlue),
        const SizedBox(width: 12),
        SizedBox(
          width: 120,
          child: Text(
            category,
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

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.secondaryBlue),
        const SizedBox(width: 12),
        SizedBox(
          width: 105,
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

