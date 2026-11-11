import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../constants/app_constants.dart';
import '../services/clock_service.dart';

final authBoxProvider = Provider<Box>((ref) {
  return Hive.box(AppConstants.authBoxName);
});

final routeBoxProvider = Provider<Box>((ref) {
  return Hive.box(AppConstants.routeBoxName);
});

final syncQueueBoxProvider = Provider<Box>((ref) {
  return Hive.box(AppConstants.syncQueueBoxName);
});

final mockServerBoxProvider = Provider<Box>((ref) {
  return Hive.box(AppConstants.mockServerBoxName);
});

final settingsBoxProvider = Provider<Box>((ref) {
  return Hive.box(AppConstants.settingsBoxName);
});

final clockServiceProvider = ChangeNotifierProvider<ClockService>((ref) {
  final box = ref.watch(settingsBoxProvider);
  final savedIso = box.get(AppConstants.simulatedClockKey);
  DateTime? initialSim;
  if (savedIso is String) {
    initialSim = DateTime.tryParse(savedIso);
  }
  return ClockService(initialSimulatedTime: initialSim);
});

// Periodic tick provider that emits currentTime every second based on ClockService
final currentTimeProvider = StreamProvider.autoDispose<DateTime>((ref) async* {
  final clock = ref.watch(clockServiceProvider);
  yield clock.now();
  final timerStream = Stream.periodic(const Duration(seconds: 1), (_) => clock.now());
  yield* timerStream;
});
