import '../../domain/entities/route_stop.dart';
import '../../domain/repositories/route_repository.dart';
import '../../domain/services/route_sorter.dart';
import '../datasources/route_local_datasource.dart';

class RouteRepositoryImpl implements RouteRepository {
  final RouteLocalDataSource _localDataSource;

  RouteRepositoryImpl(this._localDataSource);

  @override
  Future<List<RouteStop>> getStops() async {
    final stops = await _localDataSource.getStops();
    return RouteSorter.sortStops(stops);
  }

  @override
  Future<RouteStop?> getStopById(String id) async {
    final stops = await _localDataSource.getStops();
    try {
      return stops.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> updateStop(RouteStop updatedStop) async {
    final stops = await _localDataSource.getStops();
    final index = stops.indexWhere((s) => s.id == updatedStop.id);
    if (index != -1) {
      stops[index] = updatedStop;
      await _localDataSource.saveStops(stops);
    }
  }

  @override
  Future<void> saveAllStops(List<RouteStop> stops) async {
    await _localDataSource.saveStops(stops);
  }

  @override
  Future<void> resetRoute() async {
    await _localDataSource.resetRoute();
  }
}
