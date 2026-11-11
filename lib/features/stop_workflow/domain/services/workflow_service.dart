import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/enums/failure_reason.dart';
import '../../../../core/enums/priority.dart';
import '../../../../core/enums/sync_status.dart';
import '../../../../core/enums/workflow_status.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/clock_service.dart';
import '../../../../core/utils/date_time_formatter.dart';
import '../../../route_management/domain/entities/route_stop.dart';
import '../../../route_management/domain/repositories/route_repository.dart';
import '../../../synchronization/data/sync_queue_storage.dart';
import '../../../synchronization/domain/entities/sync_action.dart';
import '../../../synchronization/domain/services/sync_engine.dart';

class WorkflowService {
  final RouteRepository _routeRepository;
  final SyncQueueStorage _syncQueueStorage;
  final SyncEngine _syncEngine;
  final ClockService _clockService;
  final Uuid _uuid;

  WorkflowService({
    required RouteRepository routeRepository,
    required SyncQueueStorage syncQueueStorage,
    required SyncEngine syncEngine,
    required ClockService clockService,
    Uuid? uuid,
  })  : _routeRepository = routeRepository,
        _syncQueueStorage = syncQueueStorage,
        _syncEngine = syncEngine,
        _clockService = clockService,
        _uuid = uuid ?? const Uuid();

  // R1: Only one active stop can be Arrived
  Future<RouteStop> markArrived(String stopId) async {
    final stops = await _routeRepository.getStops();
    final targetStop = stops.firstWhere(
      (s) => s.id == stopId,
      orElse: () => throw WorkflowFailure('Stop $stopId not found.'),
    );

    // Check if another stop is already Arrived (R1)
    for (final s in stops) {
      if (s.id != stopId && s.status == WorkflowStatus.arrived) {
        throw WorkflowFailure(
          'Cannot mark arrived. Stop ${s.id} (${s.customerName}) is currently active. Only one stop can be Arrived at a time.',
        );
      }
    }

    if (targetStop.status == WorkflowStatus.delivered) {
      throw const WorkflowFailure('Stop is already delivered.');
    }
    if (targetStop.status == WorkflowStatus.returnedToHub) {
      throw const WorkflowFailure(
        'Stop is permanently locked (Returned to hub). Cannot be retried.',
      );
    }
    if (targetStop.status == WorkflowStatus.arrived) {
      return targetStop; // Already arrived
    }

    final now = _clockService.now();
    final historyEntry = DeliveryHistoryEntry(
      timestamp: now,
      status: WorkflowStatus.arrived,
      note: 'Agent arrived at stop location',
    );

    final updatedStop = targetStop.copyWith(
      status: WorkflowStatus.arrived,
      history: [...targetStop.history, historyEntry],
    );

    // S1: Optimistic UI - persist locally before sync
    await _routeRepository.updateStop(updatedStop);

    final actionId = _uuid.v4();
    final seqNum = _syncQueueStorage.getNextSequenceNumber(stopId);
    final syncAction = SyncAction(
      id: actionId,
      stopId: stopId,
      actionType: 'markArrived',
      payload: {
        'stopId': stopId,
        'timestamp': now.toIso8601String(),
      },
      createdAt: now,
      sequenceNumber: seqNum,
      status: SyncStatus.pending,
    );

    await _syncQueueStorage.enqueue(syncAction);

    // Asynchronously trigger sync
    _syncEngine.processEligibleQueue();

    return updatedStop;
  }

  // R2: Delivered Validation
  Future<RouteStop> markDelivered({
    required String stopId,
    required String recipientName,
    required int confirmedPackages,
  }) async {
    final targetStop = await _routeRepository.getStopById(stopId);
    if (targetStop == null) {
      throw WorkflowFailure('Stop $stopId not found.');
    }

    if (targetStop.status != WorkflowStatus.arrived) {
      throw const WorkflowFailure(
        'Stop must have "Arrived" status before it can be marked Delivered.',
      );
    }

    // Validation R2
    final trimmedName = recipientName.trim();
    if (trimmedName.isEmpty) {
      throw const ValidationFailure('Recipient name is mandatory.');
    }
    if (trimmedName.length < 2) {
      throw const ValidationFailure(
        'Recipient name must contain at least two characters.',
      );
    }

    if (confirmedPackages != targetStop.expectedPackages) {
      throw ValidationFailure(
        'Confirmed package count ($confirmedPackages) must equal expected packages (${targetStop.expectedPackages}).',
      );
    }

    if (confirmedPackages > targetStop.expectedPackages) {
      throw ValidationFailure(
        'Confirmed package count cannot exceed expected packages (${targetStop.expectedPackages}).',
      );
    }

    final now = _clockService.now();
    final historyEntry = DeliveryHistoryEntry(
      timestamp: now,
      status: WorkflowStatus.delivered,
      recipientName: trimmedName,
      confirmedPackages: confirmedPackages,
      note: 'Delivered to $trimmedName',
    );

    final updatedStop = targetStop.copyWith(
      status: WorkflowStatus.delivered,
      recipientName: trimmedName,
      confirmedPackages: confirmedPackages,
      deliveryTimestamp: now,
      history: [...targetStop.history, historyEntry],
    );

    // S1: Optimistic UI
    await _routeRepository.updateStop(updatedStop);

    final actionId = _uuid.v4();
    final seqNum = _syncQueueStorage.getNextSequenceNumber(stopId);
    final syncAction = SyncAction(
      id: actionId,
      stopId: stopId,
      actionType: 'markDelivered',
      payload: {
        'stopId': stopId,
        'recipientName': trimmedName,
        'confirmedPackages': confirmedPackages,
        'deliveryTimestamp': now.toIso8601String(),
      },
      createdAt: now,
      sequenceNumber: seqNum,
      status: SyncStatus.pending,
    );

    await _syncQueueStorage.enqueue(syncAction);
    _syncEngine.processEligibleQueue();

    return updatedStop;
  }

  // R3, R4, R6: Failed Delivery
  Future<RouteStop> markFailed({
    required String stopId,
    required FailureReason reason,
    String? note,
  }) async {
    final targetStop = await _routeRepository.getStopById(stopId);
    if (targetStop == null) {
      throw WorkflowFailure('Stop $stopId not found.');
    }

    if (targetStop.status != WorkflowStatus.arrived) {
      throw const WorkflowFailure(
        'Stop must have "Arrived" status before reporting a failure.',
      );
    }

    final now = _clockService.now();

    // R6: Urgent stop validation
    if (targetStop.priority == StopPriority.urgent &&
        reason == FailureReason.customerAbsent) {
      final windowStart = DateTimeFormatter.parseWindowTime(
        targetStop.windowStart,
        now,
      );
      if (now.isBefore(windowStart)) {
        throw ValidationFailure(
          'For Urgent stops, failure reason "Customer absent" cannot be reported before the delivery window starts (${targetStop.windowStart}). Current time is ${DateTimeFormatter.formatTime(now)}.',
        );
      }
    }

    // R3: Other note validation
    final trimmedNote = (note ?? '').trim();
    if (reason == FailureReason.other) {
      if (trimmedNote.isEmpty) {
        throw const ValidationFailure(
          'A note is mandatory when "Other" failure reason is selected.',
        );
      }
      if (trimmedNote.length < 10) {
        throw const ValidationFailure(
          'Failure note must contain at least 10 characters.',
        );
      }
    }

    // R4: Attempt count and status transitions
    final newFailureCount = targetStop.failureCount + 1;
    final WorkflowStatus newStatus;
    int? customOrder;

    if (newFailureCount >= AppConstants.maxFailureAttempts) {
      // Second failure -> Returned to hub (Final status, permanently locked)
      newStatus = WorkflowStatus.returnedToHub;
    } else {
      // First failure -> Failed, move to end of route, retry allowed
      newStatus = WorkflowStatus.failed;
      final allStops = await _routeRepository.getStops();
      var maxOrder = allStops.length;
      for (final s in allStops) {
        if (s.customOrder != null && s.customOrder! > maxOrder) {
          maxOrder = s.customOrder!;
        }
      }
      customOrder = maxOrder + 1;
    }

    final historyEntry = DeliveryHistoryEntry(
      timestamp: now,
      status: newStatus,
      failureReason: reason,
      failureNote: trimmedNote.isNotEmpty ? trimmedNote : null,
      note: 'Failed: ${reason.label}${trimmedNote.isNotEmpty ? " ($trimmedNote)" : ""}',
    );

    final updatedStop = targetStop.copyWith(
      status: newStatus,
      isRetry: newFailureCount < AppConstants.maxFailureAttempts,
      failureCount: newFailureCount,
      lastFailureReason: reason,
      lastFailureNote: trimmedNote.isNotEmpty ? trimmedNote : null,
      customOrder: customOrder,
      history: [...targetStop.history, historyEntry],
    );

    // S1: Optimistic UI
    await _routeRepository.updateStop(updatedStop);

    final actionId = _uuid.v4();
    final seqNum = _syncQueueStorage.getNextSequenceNumber(stopId);
    final syncAction = SyncAction(
      id: actionId,
      stopId: stopId,
      actionType: 'markFailed',
      payload: {
        'stopId': stopId,
        'reason': reason.name,
        'note': trimmedNote,
        'failureCount': newFailureCount,
        'resultingStatus': newStatus.name,
        'timestamp': now.toIso8601String(),
      },
      createdAt: now,
      sequenceNumber: seqNum,
      status: SyncStatus.pending,
    );

    await _syncQueueStorage.enqueue(syncAction);
    _syncEngine.processEligibleQueue();

    return updatedStop;
  }

  // R5: Locking and Undo
  int getRemainingUndoSeconds(RouteStop stop) {
    if (stop.status != WorkflowStatus.delivered ||
        stop.deliveryTimestamp == null) {
      return 0;
    }
    final now = _clockService.now();
    final elapsedSeconds = now.difference(stop.deliveryTimestamp!).inSeconds;
    final remaining = AppConstants.undoDeliveryWindowSeconds - elapsedSeconds;
    return remaining > 0 ? remaining : 0;
  }

  bool isUndoEligible(RouteStop stop) {
    return getRemainingUndoSeconds(stop) > 0;
  }

  Future<RouteStop> undoDelivered(String stopId) async {
    final targetStop = await _routeRepository.getStopById(stopId);
    if (targetStop == null) {
      throw WorkflowFailure('Stop $stopId not found.');
    }

    if (targetStop.status != WorkflowStatus.delivered) {
      throw const WorkflowFailure('Only Delivered stops can be undone.');
    }

    if (!isUndoEligible(targetStop)) {
      throw const WorkflowFailure(
        'Undo delivery window has expired (60-second limit exceeded).',
      );
    }

    final now = _clockService.now();
    final historyEntry = DeliveryHistoryEntry(
      timestamp: now,
      status: WorkflowStatus.arrived,
      note: 'Delivery undone by agent within 60s window',
    );

    // Restore to Arrived state, restore route ordering, clear deliveryTimestamp
    final updatedStop = targetStop.copyWith(
      status: WorkflowStatus.arrived,
      clearDeliveryTimestamp: true,
      clearCustomOrder: true,
      history: [...targetStop.history, historyEntry],
    );

    // S1: Optimistic UI
    await _routeRepository.updateStop(updatedStop);

    final actionId = _uuid.v4();
    final seqNum = _syncQueueStorage.getNextSequenceNumber(stopId);
    final syncAction = SyncAction(
      id: actionId,
      stopId: stopId,
      actionType: 'undoDelivered',
      payload: {
        'stopId': stopId,
        'timestamp': now.toIso8601String(),
      },
      createdAt: now,
      sequenceNumber: seqNum,
      status: SyncStatus.pending,
    );

    await _syncQueueStorage.enqueue(syncAction);
    _syncEngine.processEligibleQueue();

    return updatedStop;
  }
}
