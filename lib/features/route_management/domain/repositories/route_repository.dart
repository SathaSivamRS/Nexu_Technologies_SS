import '../entities/route_stop.dart';

abstract class RouteRepository {
  Future<List<RouteStop>> getStops();
  Future<RouteStop?> getStopById(String id);
  Future<void> updateStop(RouteStop stop);
  Future<void> saveAllStops(List<RouteStop> stops);
  Future<void> resetRoute();
}
