/// App-wide constants.
abstract final class AppConstants {
  /// Current build flavor (dev or prod), set via --dart-define=FLAVOR=prod.
  static const String flavor = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'dev',
  );

  /// Whether this is a production build.
  static const bool isProduction = flavor == 'prod';

  /// API base URL — dev defaults to emulator, prod to cricscores.in.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: isProduction
        ? 'https://cricscores.in/api/v1'
        : 'http://10.0.2.2:3001/api/v1',
  );

  /// WebSocket URL.
  static const String wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: isProduction
        ? 'wss://cricscores.in/ws'
        : 'ws://10.0.2.2:3001/ws',
  );

  /// Pagination default page size.
  static const int defaultPageSize = 20;

  /// Sync retry limit.
  static const int maxSyncRetries = 5;

  /// 8dp grid spacing unit.
  static const double spacing = 8.0;

  /// WebSocket reconnect: max attempts before giving up.
  static const int wsReconnectMaxAttempts = 30;

  /// WebSocket reconnect: initial delay in milliseconds.
  static const int wsReconnectInitialDelayMs = 1000;

  /// WebSocket reconnect: maximum delay in milliseconds.
  static const int wsReconnectMaxDelayMs = 30000;
}
