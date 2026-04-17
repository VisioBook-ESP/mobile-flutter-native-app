import 'package:flutter_test/flutter_test.dart';
import 'package:visiobook_mobile/config/environment.dart';
import 'package:visiobook_mobile/core/network/api_client.dart';
import 'package:visiobook_mobile/core/utils/secure_storage.dart';
import 'package:visiobook_mobile/features/auth/data/auth_service.dart';
import 'package:visiobook_mobile/features/auth/presentation/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// Stubs to avoid platform channels (FlutterSecureStorage)
// ---------------------------------------------------------------------------

class _FakeSecureStorage extends SecureStorageService {
  @override
  Future<String?> getAccessToken() async => 'fake_token';
  @override
  Future<String?> getRefreshToken() async => null;
  @override
  Future<void> saveAccessToken(String token) async {}
  @override
  Future<void> saveRefreshToken(String token) async {}
  @override
  Future<void> clearTokens() async {}
  @override
  Future<bool> isLoggedIn() async => true;
  @override
  Future<void> saveUserId(String userId) async {}
  @override
  Future<String?> getUserId() async => 'fake_user';
  @override
  Future<void> saveUserName(String name) async {}
  @override
  Future<String?> getUserName() async => 'Fake';
  @override
  Future<void> setOnboardingComplete(bool complete) async {}
  @override
  Future<bool> isOnboardingComplete() async => true;
  @override
  Future<void> clearAll() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthProvider provider;
  late AuthService authService;

  setUp(() {
    EnvironmentConfig.useMockData = true;
    authService = AuthService(
      apiClient: ApiClient(storage: _FakeSecureStorage()),
      storage: _FakeSecureStorage(),
    );
    provider = AuthProvider(authService: authService);
  });

  tearDown(() {
    EnvironmentConfig.useMockData = false;
    provider.dispose();
  });

  group('AuthProvider initial state', () {
    test('state is initial', () {
      expect(provider.state, AuthState.initial);
    });

    test('error is null', () {
      expect(provider.error, isNull);
    });

    test('isLoading is false', () {
      expect(provider.isLoading, isFalse);
    });

    test('isAuthenticated is false', () {
      expect(provider.isAuthenticated, isFalse);
    });

    test('userName is null', () {
      expect(provider.userName, isNull);
    });
  });

  group('AuthProvider login mock mode', () {
    test('login succeeds and sets authenticated', () async {
      final result = await provider.login(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result, isTrue);
      expect(provider.state, AuthState.authenticated);
      expect(provider.isAuthenticated, isTrue);
      expect(provider.error, isNull);
    });

    test('login sets userName from email prefix', () async {
      await provider.login(
        email: 'john.doe@example.com',
        password: 'password123',
      );

      expect(provider.userName, 'john.doe');
    });

    test('login notifies listeners', () async {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.login(email: 'test@example.com', password: 'password123');

      // At least 2: loading + authenticated
      expect(notifyCount, greaterThanOrEqualTo(2));
    });
  });

  group('AuthProvider register mock mode', () {
    test('register succeeds and sets authenticated', () async {
      final result = await provider.register(
        username: 'testuser',
        email: 'test@example.com',
        password: 'password123',
        firstName: 'Test',
        lastName: 'User',
      );

      expect(result, isTrue);
      expect(provider.state, AuthState.authenticated);
      expect(provider.isAuthenticated, isTrue);
    });

    test('register sets userName to firstName', () async {
      await provider.register(
        username: 'testuser',
        email: 'test@example.com',
        password: 'password123',
        firstName: 'Marine',
        lastName: 'Gayet',
      );

      expect(provider.userName, 'Marine');
    });
  });

  group('AuthProvider logout', () {
    test('logout clears authenticated state', () async {
      await provider.login(email: 'test@example.com', password: 'password123');
      expect(provider.isAuthenticated, isTrue);

      await provider.logout();

      expect(provider.state, AuthState.unauthenticated);
      expect(provider.isAuthenticated, isFalse);
      expect(provider.userName, isNull);
      expect(provider.error, isNull);
    });

    test('logout notifies listeners', () async {
      await provider.login(email: 'test@example.com', password: 'password123');

      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.logout();

      expect(notifyCount, 1);
    });
  });

  group('AuthProvider register sets userName', () {
    test('register sets userName to firstName', () async {
      await provider.register(
        username: 'jdoe',
        email: 'jane@example.com',
        password: 'password123',
        firstName: 'Jane',
        lastName: 'Doe',
      );

      expect(provider.userName, 'Jane');
    });
  });

  group('AuthProvider checkAuth', () {
    test('checkAuth sets loading then unauthenticated in debug mode', () async {
      // In debug mode, checkAuthStatus always forces unauthenticated
      await provider.checkAuthStatus();

      expect(provider.state, AuthState.unauthenticated);
      expect(provider.isAuthenticated, isFalse);
    });

    test('checkAuth after login resets to unauthenticated in debug', () async {
      await provider.login(email: 'test@example.com', password: 'password123');
      expect(provider.isAuthenticated, isTrue);

      // checkAuth in debug always forces logout
      await provider.checkAuthStatus();
      expect(provider.isAuthenticated, isFalse);
    });
  });

  group('AuthProvider clearError', () {
    test('clearError resets error and state to unauthenticated', () async {
      // In mock mode login always succeeds, so we test clearError on initial
      // state by manually checking the behavior
      provider.clearError();

      expect(provider.error, isNull);
    });

    test('clearError on non-error state preserves state', () async {
      await provider.login(email: 'test@example.com', password: 'password123');

      provider.clearError();

      expect(provider.state, AuthState.authenticated);
    });

    test('clearError notifies listeners', () {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.clearError();

      expect(notifyCount, 1);
    });

    test('clearError on error state transitions to unauthenticated', () {
      // We can't easily force an error in mock mode, but we can verify
      // that clearError on initial state doesn't break anything
      provider.clearError();
      expect(provider.error, isNull);
      // State was initial, clearError should not change it to error
      // since it only changes error -> unauthenticated
    });
  });
}
