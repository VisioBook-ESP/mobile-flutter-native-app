/// Configuration des environnements (dev/prod)
enum Environment { dev, prod }

class EnvironmentConfig {
  static Environment _current = Environment.dev;

  /// Mode mock pour tester l'UI sans backend
  static bool useMockData = false;

  static Environment get current => _current;

  static void setEnvironment(Environment env) {
    _current = env;
  }

  /// Base URL de l'API Gateway
  static String get apiBaseUrl {
    switch (_current) {
      case Environment.dev:
        return 'http://51.178.52.51';
      case Environment.prod:
        return 'https://visiobook.cloud';
    }
  }

  /// Core User Service
  static String get userServiceUrl => '$apiBaseUrl/api/v1';

  /// Core Project Service
  static String get projectServiceUrl => '$apiBaseUrl/api/v1';

  /// Content Ingestion Service
  static String get ingestionServiceUrl => '$apiBaseUrl/api/v1';

  /// AI Analysis Service (port 8083)
  static String get aiServiceUrl => '$apiBaseUrl/api/v1';
}
