class AppConstants {
  // Demo Authentication
  static const String demoAgentName = 'Asha';
  static const String demoPin = '1234';

  // Workflow Constants
  static const int maxFailureAttempts = 2;
  static const int undoDeliveryWindowSeconds = 60;
  static const int atRiskThresholdMinutes = 15;

  // Synchronization Constants
  static const double defaultFailureRate = 0.30;
  static const List<int> retryDelaysSeconds = [2, 4, 8];
  static const int maxRetryAttempts = 3; // 3 retries after initial attempt

  // Hive Box Names
  static const String authBoxName = 'nexu_auth_box';
  static const String routeBoxName = 'nexu_route_box';
  static const String syncQueueBoxName = 'nexu_sync_queue_box';
  static const String mockServerBoxName = 'nexu_mock_server_box';
  static const String settingsBoxName = 'nexu_settings_box';

  // Storage Keys
  static const String authSessionKey = 'auth_session';
  static const String routeStopsKey = 'route_stops';
  static const String offlineModeKey = 'offline_mode';
  static const String simulatedClockKey = 'simulated_clock';
  static const String mockFailureRateKey = 'mock_failure_rate';
  static const String processedRequestIdsKey = 'processed_request_ids';

  // About Metadata
  static const String appName = 'NEXU RouteRunner';
  static const String appDescription =
      'Offline-first delivery management application.';
  static const String developerName = 'Sathasivam R S';
  static const String assessmentTitle =
      'Application Developer Intern – Mobile Applications';
  static const String companyName = 'NEXU Technologies Private Limited';
  static const String assessmentReceivedDate = '11 November 2026';
  static const String assessmentReceivedTime = '07:27:00 IST';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
}
