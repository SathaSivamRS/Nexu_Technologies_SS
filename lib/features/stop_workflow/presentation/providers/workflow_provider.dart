import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../route_management/presentation/providers/route_providers.dart';
import '../../../synchronization/presentation/providers/sync_providers.dart';
import '../../domain/services/workflow_service.dart';

final workflowServiceProvider = Provider<WorkflowService>((ref) {
  final routeRepo = ref.watch(routeRepositoryProvider);
  final syncQueueStorage = ref.watch(syncQueueStorageProvider);
  final syncEngine = ref.watch(syncEngineProvider);
  final clockService = ref.watch(clockServiceProvider);

  return WorkflowService(
    routeRepository: routeRepo,
    syncQueueStorage: syncQueueStorage,
    syncEngine: syncEngine,
    clockService: clockService,
  );
});
