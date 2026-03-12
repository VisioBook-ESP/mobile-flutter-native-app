import 'package:flutter_test/flutter_test.dart';
import 'package:visiobook_mobile/config/environment.dart';

void main() {
  group('EnvironmentConfig', () {
    setUp(() {
      // Reset to default dev environment before each test
      EnvironmentConfig.setEnvironment(Environment.dev);
    });

    test('default environment is dev', () {
      expect(EnvironmentConfig.current, Environment.dev);
    });

    test('useMockData is true by default', () {
      expect(EnvironmentConfig.useMockData, isTrue);
    });

    test('setEnvironment changes current environment', () {
      EnvironmentConfig.setEnvironment(Environment.prod);
      expect(EnvironmentConfig.current, Environment.prod);
    });

    group('dev environment', () {
      test('apiBaseUrl returns dev URL', () {
        expect(EnvironmentConfig.apiBaseUrl, 'http://51.178.52.51');
      });

      test('userServiceUrl appends /api/v1', () {
        expect(EnvironmentConfig.userServiceUrl, 'http://51.178.52.51/api/v1');
      });

      test('projectServiceUrl appends /api/v1', () {
        expect(
          EnvironmentConfig.projectServiceUrl,
          'http://51.178.52.51/api/v1',
        );
      });

      test('storageServiceUrl appends /api/v1', () {
        expect(
          EnvironmentConfig.storageServiceUrl,
          'http://51.178.52.51/api/v1',
        );
      });

      test('aiServiceUrl appends /api/v1', () {
        expect(EnvironmentConfig.aiServiceUrl, 'http://51.178.52.51/api/v1');
      });
    });

    group('prod environment', () {
      setUp(() {
        EnvironmentConfig.setEnvironment(Environment.prod);
      });

      test('apiBaseUrl returns prod URL', () {
        expect(EnvironmentConfig.apiBaseUrl, 'https://visiobook.cloud');
      });

      test('userServiceUrl appends /api/v1', () {
        expect(
          EnvironmentConfig.userServiceUrl,
          'https://visiobook.cloud/api/v1',
        );
      });

      test('projectServiceUrl appends /api/v1', () {
        expect(
          EnvironmentConfig.projectServiceUrl,
          'https://visiobook.cloud/api/v1',
        );
      });

      test('storageServiceUrl appends /api/v1', () {
        expect(
          EnvironmentConfig.storageServiceUrl,
          'https://visiobook.cloud/api/v1',
        );
      });

      test('aiServiceUrl appends /api/v1', () {
        expect(
          EnvironmentConfig.aiServiceUrl,
          'https://visiobook.cloud/api/v1',
        );
      });
    });
  });
}
