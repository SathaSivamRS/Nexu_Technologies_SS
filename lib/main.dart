import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app/app.dart';
import 'core/constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive local persistence
  await Hive.initFlutter();

  // Open all required Hive storage boxes
  await Future.wait([
    Hive.openBox(AppConstants.authBoxName),
    Hive.openBox(AppConstants.routeBoxName),
    Hive.openBox(AppConstants.syncQueueBoxName),
    Hive.openBox(AppConstants.mockServerBoxName),
    Hive.openBox(AppConstants.settingsBoxName),
  ]);

  runApp(
    const ProviderScope(
      child: NexuRouteRunnerApp(),
    ),
  );
}
