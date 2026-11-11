import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/route_stop.dart';

abstract class RouteLocalDataSource {
  Future<List<RouteStop>> getStops();
  Future<void> saveStops(List<RouteStop> stops);
  Future<void> resetRoute();
}

class RouteLocalDataSourceImpl implements RouteLocalDataSource {
  final Box _box;
  final AssetBundle _assetBundle;

  RouteLocalDataSourceImpl(this._box, [AssetBundle? assetBundle])
      : _assetBundle = assetBundle ?? rootBundle;

  @override
  Future<List<RouteStop>> getStops() async {
    final raw = _box.get(AppConstants.routeStopsKey);
    if (raw != null) {
      try {
        final List<dynamic> list = raw is String
            ? jsonDecode(raw) as List<dynamic>
            : (raw as List<dynamic>);
        return list
            .map((e) => RouteStop.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } catch (_) {
        // Fallback to reload if corrupted
      }
    }

    // First time initialization: Load from assets
    final jsonString =
        await _assetBundle.loadString('assets/data/route_stops.json');
    final List<dynamic> list = jsonDecode(jsonString) as List<dynamic>;
    final stops = list
        .map((e) => RouteStop.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    await saveStops(stops);
    return stops;
  }

  @override
  Future<void> saveStops(List<RouteStop> stops) async {
    final jsonList = stops.map((e) => e.toJson()).toList();
    await _box.put(AppConstants.routeStopsKey, jsonEncode(jsonList));
  }

  @override
  Future<void> resetRoute() async {
    await _box.delete(AppConstants.routeStopsKey);
    await getStops();
  }
}
