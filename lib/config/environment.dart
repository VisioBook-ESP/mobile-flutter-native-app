/// Configuration des environnements (dev/prod)
enum Environment { dev, prod }

class EnvironmentConfig {
  static Environment _current = Environment.dev;

  static Environment get current => _current;

  static void setEnvironment(Environment env) {
    _current = env;
  }

  /// Base URL de l'API Gateway
  static String get apiBaseUrl {
    switch (_current) {
      case Environment.dev:
        return 'http://localhost';
      case Environment.prod:
        return 'https://api.visiobook.com';
    }
  }

  /// Core User Service (port 8081)
  static String get userServiceUrl => '$apiBaseUrl:8081/api/v1';

  /// Core Project Service (port 8086)
  static String get projectServiceUrl => '$apiBaseUrl:8086/api/v1';

  /// Support Storage Service (port 8089)
  static String get storageServiceUrl => '$apiBaseUrl:8089/api/v1';

  /// AI Analysis Service (port 8083)
  static String get aiServiceUrl => '$apiBaseUrl:8083/api/v1';
}
