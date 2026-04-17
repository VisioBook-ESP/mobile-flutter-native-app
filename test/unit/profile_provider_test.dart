import 'package:flutter_test/flutter_test.dart';
import 'package:visiobook_mobile/config/environment.dart';
import 'package:visiobook_mobile/core/network/api_client.dart';
import 'package:visiobook_mobile/core/utils/secure_storage.dart';
import 'package:visiobook_mobile/features/profile/data/profile_service.dart';
import 'package:visiobook_mobile/features/profile/presentation/providers/profile_provider.dart';

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

  late ProfileProvider provider;
  late ProfileService profileService;

  setUp(() {
    EnvironmentConfig.useMockData = true;
    profileService = ProfileService(
      apiClient: ApiClient(storage: _FakeSecureStorage()),
    );
    provider = ProfileProvider(profileService: profileService);
  });

  tearDown(() {
    EnvironmentConfig.useMockData = false;
    provider.dispose();
  });

  group('ProfileProvider initial state', () {
    test('state is initial', () {
      expect(provider.state, ProfileState.initial);
    });

    test('profile is null', () {
      expect(provider.profile, isNull);
    });

    test('error is null', () {
      expect(provider.error, isNull);
    });

    test('isLoading is false', () {
      expect(provider.isLoading, isFalse);
    });
  });

  group('ProfileProvider loadProfile mock mode', () {
    test('loads mock profile successfully', () async {
      await provider.loadProfile();

      expect(provider.state, ProfileState.loaded);
      expect(provider.profile, isNotNull);
      expect(provider.profile!.id, 'mock-user-001');
      expect(provider.profile!.username, 'demo_user');
      expect(provider.profile!.email, 'demo@visiobook.com');
      expect(provider.profile!.firstName, 'Demo');
      expect(provider.profile!.lastName, 'User');
      expect(provider.profile!.credits, 150);
      expect(provider.error, isNull);
    });

    test('notifies listeners during load', () async {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.loadProfile();

      // At least 2: loading + loaded
      expect(notifyCount, greaterThanOrEqualTo(2));
    });
  });

  group('ProfileProvider updateProfile mock mode', () {
    test('updates profile fields', () async {
      final result = await provider.updateProfile(
        firstName: 'Updated',
        lastName: 'Name',
      );

      expect(result, isTrue);
      expect(provider.state, ProfileState.loaded);
      expect(provider.profile, isNotNull);
      expect(provider.profile!.firstName, 'Updated');
      expect(provider.profile!.lastName, 'Name');
    });
  });

  group('ProfileProvider changePassword mock mode', () {
    test('succeeds in mock mode', () async {
      final result = await provider.changePassword(newPassword: 'newpass123');

      expect(result, isTrue);
      expect(provider.state, ProfileState.loaded);
    });
  });

  group('ProfileProvider deleteAccount mock mode', () {
    test('clears profile on delete', () async {
      await provider.loadProfile();
      expect(provider.profile, isNotNull);

      final result = await provider.deleteAccount();

      expect(result, isTrue);
      expect(provider.profile, isNull);
      expect(provider.state, ProfileState.initial);
    });
  });

  group('ProfileProvider refreshCredits', () {
    test('updates credits on loaded profile', () async {
      await provider.loadProfile();
      final creditsBefore = provider.profile!.credits;

      await provider.refreshCredits();

      // In mock mode getCredits returns 0
      expect(provider.profile!.credits, 0);
      expect(creditsBefore, 150); // Was 150 before refresh
    });

    test('does nothing when profile is null', () async {
      // Should not throw
      await provider.refreshCredits();
      expect(provider.profile, isNull);
    });
  });

  group('ProfileProvider clearError', () {
    test('clears error and returns to initial when no profile', () {
      provider.clearError();
      expect(provider.error, isNull);
      expect(provider.state, ProfileState.initial);
    });

    test('clears error and returns to loaded when profile exists', () async {
      await provider.loadProfile();
      provider.clearError();
      expect(provider.state, ProfileState.loaded);
    });

    test('notifies listeners', () {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.clearError();

      expect(notifyCount, 1);
    });
  });
}
