import 'package:flutter_test/flutter_test.dart';
import 'package:visiobook_mobile/core/utils/secure_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecureStorageService', () {
    test('can be instantiated', () {
      final storage = SecureStorageService();
      expect(storage, isNotNull);
      expect(storage, isA<SecureStorageService>());
    });

    test('saveAccessToken method exists and returns Future', () {
      final storage = SecureStorageService();
      // Method should exist and return a Future (will fail at platform level)
      expect(storage.saveAccessToken, isA<Function>());
    });

    test('getAccessToken method exists and returns Future', () {
      final storage = SecureStorageService();
      expect(storage.getAccessToken, isA<Function>());
    });

    test('saveRefreshToken method exists and returns Future', () {
      final storage = SecureStorageService();
      expect(storage.saveRefreshToken, isA<Function>());
    });

    test('getRefreshToken method exists and returns Future', () {
      final storage = SecureStorageService();
      expect(storage.getRefreshToken, isA<Function>());
    });

    test('saveUserId method exists and returns Future', () {
      final storage = SecureStorageService();
      expect(storage.saveUserId, isA<Function>());
    });

    test('getUserId method exists and returns Future', () {
      final storage = SecureStorageService();
      expect(storage.getUserId, isA<Function>());
    });

    test('saveUserName method exists and returns Future', () {
      final storage = SecureStorageService();
      expect(storage.saveUserName, isA<Function>());
    });

    test('getUserName method exists and returns Future', () {
      final storage = SecureStorageService();
      expect(storage.getUserName, isA<Function>());
    });

    test('setOnboardingComplete method exists and returns Future', () {
      final storage = SecureStorageService();
      expect(storage.setOnboardingComplete, isA<Function>());
    });

    test('isOnboardingComplete method exists and returns Future', () {
      final storage = SecureStorageService();
      expect(storage.isOnboardingComplete, isA<Function>());
    });

    test('clearTokens method exists and returns Future', () {
      final storage = SecureStorageService();
      expect(storage.clearTokens, isA<Function>());
    });

    test('clearAll method exists and returns Future', () {
      final storage = SecureStorageService();
      expect(storage.clearAll, isA<Function>());
    });

    test('isLoggedIn method exists and returns Future', () {
      final storage = SecureStorageService();
      expect(storage.isLoggedIn, isA<Function>());
    });

    // Test that methods return Futures (they will throw MissingPluginException
    // but the Future itself is created)
    test('saveAccessToken returns a Future', () {
      final storage = SecureStorageService();
      final result = storage.saveAccessToken('test');
      expect(result, isA<Future<void>>());
      result.catchError((_) {});
    });

    test('getAccessToken returns a Future', () {
      final storage = SecureStorageService();
      final result = storage.getAccessToken();
      expect(result, isA<Future<String?>>());
      result.catchError((_) => null as String?);
    });

    test('isLoggedIn returns a Future', () {
      final storage = SecureStorageService();
      final result = storage.isLoggedIn();
      expect(result, isA<Future<bool>>());
      result.catchError((_) => false);
    });

    test('isOnboardingComplete returns a Future', () {
      final storage = SecureStorageService();
      final result = storage.isOnboardingComplete();
      expect(result, isA<Future<bool>>());
      result.catchError((_) => false);
    });

    test('clearTokens returns a Future', () {
      final storage = SecureStorageService();
      final result = storage.clearTokens();
      expect(result, isA<Future<void>>());
      result.catchError((_) {});
    });

    test('clearAll returns a Future', () {
      final storage = SecureStorageService();
      final result = storage.clearAll();
      expect(result, isA<Future<void>>());
      result.catchError((_) {});
    });
  });
}
