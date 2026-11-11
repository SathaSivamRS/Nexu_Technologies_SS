import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/enums/workflow_status.dart';
import '../../domain/entities/route_stop.dart';
import 'route_providers.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final statusFilterProvider = StateProvider<WorkflowStatus?>((ref) => null);

final filteredStopsProvider = Provider<List<RouteStop>>((ref) {
  final stopsState = ref.watch(routeStopsNotifierProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final statusFilter = ref.watch(statusFilterProvider);

  return stopsState.stops.where((stop) {
    // Search query filter (customer name, address, or ID)
    if (query.isNotEmpty) {
      final matchesName = stop.customerName.toLowerCase().contains(query);
      final matchesAddress = stop.address.toLowerCase().contains(query);
      final matchesId = stop.id.toLowerCase().contains(query);
      if (!matchesName && !matchesAddress && !matchesId) {
        return false;
      }
    }

    // Status filter
    if (statusFilter != null && stop.status != statusFilter) {
      return false;
    }

    return true;
  }).toList();
});
