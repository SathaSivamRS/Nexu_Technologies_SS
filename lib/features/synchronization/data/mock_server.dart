import 'dart:async';
import 'dart:math';
import 'package:hive/hive.dart';
import '../../../../core/constants/app_constants.dart';
import '../domain/entities/sync_action.dart';

class MockServerResponse {
  final bool success;
  final String message;
  final bool wasDuplicate;
  final DateTime processedAt;

  const MockServerResponse({
    required this.success,
    required this.message,
    this.wasDuplicate = false,
    required this.processedAt,
  });

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'wasDuplicate': wasDuplicate,
        'processedAt': processedAt.toIso8601String(),
      };

  factory MockServerResponse.fromJson(Map<String, dynamic> json) =>
      MockServerResponse(
        success: json['success'] as bool,
        message: json['message'] as String,
        wasDuplicate: json['wasDuplicate'] as bool? ?? false,
        processedAt: DateTime.parse(json['processedAt'] as String),
      );
}

class MockServer {
  final Box _storageBox;
  final Future<void> Function(Duration)? _customDelay;
  final Random _random;
  double Function()? _failureRateGetter;
  void Function(double)? _onFailureRateChanged;

  double _failureRate = AppConstants.defaultFailureRate;
  bool _offlineMode = false;

  MockServer(
    this._storageBox, {
    Future<void> Function(Duration)? customDelay,
    Random? random,
    double Function()? failureRateGetter,
  })  : _customDelay = customDelay,
        _random = random ?? Random(),
        _failureRateGetter = failureRateGetter {
    _loadSettings();
  }

  void setFailureRateGetter(double Function()? getter) {
    _failureRateGetter = getter;
  }

  void setOnFailureRateChanged(void Function(double)? callback) {
    _onFailureRateChanged = callback;
  }

  void _loadSettings() {
    final savedRate = _storageBox.get(AppConstants.mockFailureRateKey);
    if (savedRate is double) {
      _failureRate = savedRate;
    }
    final savedOffline = _storageBox.get(AppConstants.offlineModeKey);
    if (savedOffline is bool) {
      _offlineMode = savedOffline;
    }
  }

  double get failureRate =>
      _failureRateGetter != null ? _failureRateGetter!() : _failureRate;
  bool get isOffline => _offlineMode;

  Future<void> setFailureRate(double rate) async {
    _failureRate = rate.clamp(0.0, 1.0);
    await _storageBox.put(AppConstants.mockFailureRateKey, _failureRate);
    _onFailureRateChanged?.call(_failureRate);
  }

  Future<void> setOfflineMode(bool offline) async {
    _offlineMode = offline;
    await _storageBox.put(AppConstants.offlineModeKey, _offlineMode);
  }

  Set<String> getProcessedRequestIds() {
    final list = _storageBox.get(AppConstants.processedRequestIdsKey);
    if (list is List) {
      return Set<String>.from(list);
    }
    return <String>{};
  }

  Future<void> _recordProcessedId(String id) async {
    final set = getProcessedRequestIds();
    set.add(id);
    await _storageBox.put(AppConstants.processedRequestIdsKey, set.toList());
  }

  Future<void> clearProcessedRequestIds() async {
    await _storageBox.delete(AppConstants.processedRequestIdsKey);
  }

  Future<MockServerResponse> processAction(SyncAction action) async {
    // 1. Simulate network delay (1 to 3 seconds)
    final delaySeconds = 1 + _random.nextInt(3); // 1, 2, or 3
    final delayDuration = Duration(seconds: delaySeconds);

    if (_customDelay != null) {
      await _customDelay(delayDuration);
    } else {
      await Future.delayed(delayDuration);
    }

    // 2. Check Offline Mode: S6
    if (_offlineMode) {
      return MockServerResponse(
        success: false,
        message: 'Network error: Device is in Offline Mode.',
        processedAt: DateTime.now(),
      );
    }

    // 3. Check Duplicate Request ID: S5 Idempotency
    final processedIds = getProcessedRequestIds();
    if (processedIds.contains(action.id)) {
      return MockServerResponse(
        success: true,
        message: 'Duplicate request acknowledged (idempotent).',
        wasDuplicate: true,
        processedAt: DateTime.now(),
      );
    }

    // 4. Simulate Failure Rate: S3
    final activeRate = failureRate;
    if (activeRate > 0) {
      final roll = _random.nextDouble();
      if (roll < activeRate) {
        return MockServerResponse(
          success: false,
          message:
              'Simulated network/server error (${(activeRate * 100).round()}% failure rate active).',
          processedAt: DateTime.now(),
        );
      }
    }

    // 5. Successful processing: Record persistent request ID
    await _recordProcessedId(action.id);

    return MockServerResponse(
      success: true,
      message: 'Action ${action.actionType} successfully applied on server.',
      wasDuplicate: false,
      processedAt: DateTime.now(),
    );
  }
}
