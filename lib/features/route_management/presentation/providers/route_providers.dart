import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/enums/workflow_status.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/route_local_datasource.dart';
import '../../data/repositories/route_repository_impl.dart';
import '../../domain/entities/route_stop.dart';
import '../../domain/repositories/route_repository.dart';

final routeLocalDataSourceProvider = Provider<RouteLocalDataSource>((ref) {
  final box = ref.watch(routeBoxProvider);
  return RouteLocalDataSourceImpl(box);
});

final routeRepositoryProvider = Provider<RouteRepository>((ref) {
  final dataSource = ref.watch(routeLocalDataSourceProvider);
  return RouteRepositoryImpl(dataSource);
});

class RouteStopsState {
  final bool isLoading;
  final List<RouteStop> stops;
  final String? error;

  const RouteStopsState({
    this.isLoading = false,
    this.stops = const [],
    this.error,
  });

  RouteStopsState copyWith({
    bool? isLoading,
    List<RouteStop>? stops,
    String? error,
    bool clearError = false,
  }) {
    return RouteStopsState(
      isLoading: isLoading ?? this.isLoading,
      stops: stops ?? this.stops,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class RouteStopsNotifier extends StateNotifier<RouteStopsState> {
  final RouteRepository _repository;

  RouteStopsNotifier(this._repository)
      : super(const RouteStopsState(isLoading: true)) {
    loadStops();
  }

  Future<void> loadStops() async {
    try {
      final stops = await _repository.getStops();
      state = RouteStopsState(stops: stops, isLoading: false);
    } catch (e) {
      state = RouteStopsState(
        isLoading: false,
        stops: state.stops,
        error: e.toString(),
      );
    }
  }

  Future<void> reload() async {
    await loadStops();
  }

  Future<void> resetRoute() async {
    state = state.copyWith(isLoading: true);
    await _repository.resetRoute();
    await loadStops();
  }
}

final routeStopsNotifierProvider =
    StateNotifierProvider<RouteStopsNotifier, RouteStopsState>((ref) {
  final repo = ref.watch(routeRepositoryProvider);
  return RouteStopsNotifier(repo);
});

// Active Stop Provider (R1: Stop currently in Arrived status)
final activeStopProvider = Provider<RouteStop?>((ref) {
  final state = ref.watch(routeStopsNotifierProvider);
  try {
    return state.stops.firstWhere((s) => s.status == WorkflowStatus.arrived);
  } catch (_) {
    return null;
  }
});

// Single Stop by ID Provider
final stopByIdProvider = Provider.family<RouteStop?, String>((ref, stopId) {
  final state = ref.watch(routeStopsNotifierProvider);
  try {
    return state.stops.firstWhere((s) => s.id == stopId);
  } catch (_) {
    return null;
  }
});

class RouteMetrics {
  final int totalStops;
  final int deliveredCount;
  final int failedCount;
  final int returnedToHubCount;
  final int remainingCount;

  const RouteMetrics({
    required this.totalStops,
    required this.deliveredCount,
    required this.failedCount,
    required this.returnedToHubCount,
    required this.remainingCount,
  });
}

final routeMetricsProvider = Provider<RouteMetrics>((ref) {
  final state = ref.watch(routeStopsNotifierProvider);
  final stops = state.stops;

  final total = stops.length;
  final delivered =
      stops.where((s) => s.status == WorkflowStatus.delivered).length;
  final failed = stops.where((s) => s.status == WorkflowStatus.failed).length;
  final returned =
      stops.where((s) => s.status == WorkflowStatus.returnedToHub).length;
  final remaining = stops
      .where((s) =>
          s.status == WorkflowStatus.pending ||
          s.status == WorkflowStatus.arrived ||
          s.status == WorkflowStatus.failed)
      .length;

  return RouteMetrics(
    totalStops: total,
    deliveredCount: delivered,
    failedCount: failed,
    returnedToHubCount: returned,
    remainingCount: remaining,
  );
});
