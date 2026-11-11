import 'package:flutter/material.dart';
import '../../../../app/theme.dart';
import '../../../../core/enums/failure_reason.dart';
import '../../../route_management/domain/entities/route_stop.dart';

class FailureReportSheet extends StatefulWidget {
  final RouteStop stop;
  final Future<void> Function(FailureReason reason, String? note) onConfirm;

  const FailureReportSheet({
    super.key,
    required this.stop,
    required this.onConfirm,
  });

  @override
  State<FailureReportSheet> createState() => _FailureReportSheetState();
}

class _FailureReportSheetState extends State<FailureReportSheet> {
  FailureReason _selectedReason = FailureReason.customerAbsent;
  final _noteController = TextEditingController();
  String? _errorMessage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _validateAndSubmit() async {
    final note = _noteController.text.trim();

    if (_selectedReason == FailureReason.other) {
      if (note.isEmpty) {
        setState(() {
          _errorMessage =
              'A note is mandatory when "Other" failure reason is selected.';
        });
        return;
      }
      if (note.length < 10) {
        setState(() {
          _errorMessage =
              'Note must contain at least 10 characters (currently ${note.length}).';
        });
        return;
      }
    }

    setState(() {
      _errorMessage = null;
      _isSubmitting = true;
    });

    try {
      await widget.onConfirm(_selectedReason, note.isNotEmpty ? note : null);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSecondAttempt = widget.stop.failureCount >= 1;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.errorRed,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Report Delivery Failure',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        isSecondAttempt
                            ? 'Warning: Second failure will mark as Returned to Hub (Final)'
                            : 'First attempt failure will move stop to end for retry',
                        style: TextStyle(
                          fontSize: 12,
                          color: isSecondAttempt
                              ? AppTheme.errorRed
                              : AppTheme.textSecondary,
                          fontWeight: isSecondAttempt
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 24),
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.errorRed.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppTheme.errorRed, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppTheme.errorRed,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const Text(
              'Select Failure Reason *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ...FailureReason.values.map((reason) {
              final isSelected = _selectedReason == reason;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedReason = reason;
                    _errorMessage = null;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        size: 20,
                        color: isSelected
                            ? AppTheme.secondaryBlue
                            : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        reason.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? AppTheme.textPrimary
                              : const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 12),
            Text(
              _selectedReason == FailureReason.other
                  ? 'Explanation Note (Mandatory, min 10 characters) *'
                  : 'Optional Note',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _selectedReason == FailureReason.other
                    ? AppTheme.errorRed
                    : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: _selectedReason == FailureReason.other
                    ? 'Provide detailed reason (at least 10 characters)...'
                    : 'Add optional notes...',
              ),
              onChanged: (_) {
                if (_errorMessage != null) {
                  setState(() => _errorMessage = null);
                }
              },
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorRed,
                ),
                onPressed: _isSubmitting ? null : _validateAndSubmit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        isSecondAttempt
                            ? 'Confirm Return to Hub'
                            : 'Confirm Failure & Move to End',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
