/// App-wide constants.
abstract final class AppConstants {
  /// Default API base URL for Android emulator.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api/v1',
  );

  /// WebSocket URL.
  static const String wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'ws://10.0.2.2:3001/ws',
  );

  /// Pagination default page size.
  static const int defaultPageSize = 20;

  /// Sync retry limit.
  static const int maxSyncRetries = 5;

  /// 8dp grid spacing unit.
  static const double spacing = 8.0;
}
