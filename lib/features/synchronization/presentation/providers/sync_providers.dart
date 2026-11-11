import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/enums/sync_status.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/mock_server.dart';
import '../../data/sync_queue_storage.dart';
import '../../domain/entities/sync_action.dart';
import '../../domain/services/request_processor.dart';
import '../../domain/services/retry_policy.dart';
import '../../domain/services/sync_engine.dart';

final syncQueueStorageProvider = Provider<SyncQueueStorage>((ref) {
  final box = ref.watch(syncQueueBoxProvider);
  return SyncQueueStorageImpl(box);
});

final mockServerProvider = Provider<MockServer>((ref) {
  final box = ref.watch(mockServerBoxProvider);
  return MockServer(box);
});

final retryPolicyProvider = Provider<RetryPolicy>((ref) {
  return const RetryPolicy();
});

final requestProcessorProvider = Provider<RequestProcessor>((ref) {
  final mockServer = ref.watch(mockServerProvider);
  final queueStorage = ref.watch(syncQueueStorageProvider);
  final retryPolicy = ref.watch(retryPolicyProvider);
  final clockService = ref.watch(clockServiceProvider);

  return RequestProcessor(
    mockServer: mockServer,
    queueStorage: queueStorage,
    retryPolicy: retryPolicy,
    clockService: clockService,
  );
});

final syncEngineProvider = ChangeNotifierProvider<SyncEngine>((ref) {
  final queueStorage = ref.watch(syncQueueStorageProvider);
  final requestProcessor = ref.watch(requestProcessorProvider);
  final mockServer = ref.watch(mockServerProvider);
  final clockService = ref.watch(clockServiceProvider);
  final retryPolicy = ref.watch(retryPolicyProvider);

  return SyncEngine(
    queueStorage: queueStorage,
    requestProcessor: requestProcessor,
    mockServer: mockServer,
    clockService: clockService,
    retryPolicy: retryPolicy,
    autoStartTimer: true,
  );
});

// Provider for stop-level sync status
final stopSyncStatusProvider =
    Provider.family<SyncStatus, String>((ref, stopId) {
  final syncEngine = ref.watch(syncEngineProvider);
  return syncEngine.getStopSyncStatus(stopId);
});

// Provider for unsynced actions in queue
final unsyncedActionsProvider = Provider<List<SyncAction>>((ref) {
  final syncEngine = ref.watch(syncEngineProvider);
  return syncEngine.queue;
});

// Offline Mode state
final offlineModeProvider = Provider<bool>((ref) {
  final syncEngine = ref.watch(syncEngineProvider);
  return syncEngine.isOffline;
});

// Mock Server failure rate state
final mockFailureRateProvider = Provider<double>((ref) {
  final mockServer = ref.watch(mockServerProvider);
  return mockServer.failureRate;
});
