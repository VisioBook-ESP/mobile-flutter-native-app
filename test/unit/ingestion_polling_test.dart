import 'package:flutter_test/flutter_test.dart';
import 'package:visiobook_mobile/config/environment.dart';
import 'package:visiobook_mobile/core/network/api_client.dart';
import 'package:visiobook_mobile/core/utils/secure_storage.dart';
import 'package:visiobook_mobile/features/generation/data/ingestion_polling_service.dart';
import 'package:visiobook_mobile/features/generation/domain/ingestion_state.dart';

// ---------------------------------------------------------------------------
// Fake SecureStorage to avoid platform channels
// ---------------------------------------------------------------------------
class _FakeStorage extends SecureStorageService {
  @override
  Future<String?> getAccessToken() async => null;
  @override
  Future<String?> getRefreshToken() async => null;
  @override
  Future<void> saveAccessToken(String token) async {}
  @override
  Future<void> saveRefreshToken(String token) async {}
  @override
  Future<void> clearTokens() async {}
  @override
  Future<bool> isLoggedIn() async => false;
  @override
  Future<void> saveUserId(String userId) async {}
  @override
  Future<String?> getUserId() async => null;
  @override
  Future<void> saveUserName(String name) async {}
  @override
  Future<String?> getUserName() async => null;
  @override
  Future<void> setOnboardingComplete(bool complete) async {}
  @override
  Future<bool> isOnboardingComplete() async => true;
  @override
  Future<void> clearAll() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late IngestionPollingService service;
  late ApiClient apiClient;

  setUp(() {
    EnvironmentConfig.useMockData = true;
    apiClient = ApiClient(storage: _FakeStorage());
    service = IngestionPollingService(apiClient: apiClient);
  });

  tearDown(() {
    service.dispose();
    EnvironmentConfig.useMockData = false;
  });

  group('IngestionPollingService', () {
    test('constructor creates service', () {
      expect(service, isNotNull);
    });

    test('dispose does not throw', () {
      expect(() => service.dispose(), returnsNormally);
    });

    test('stopPolling does not throw when not polling', () {
      expect(() => service.stopPolling(), returnsNormally);
    });

    test('stopPolling can be called multiple times safely', () {
      service.stopPolling();
      service.stopPolling();
      // Should not throw
    });

    test('getIngestionStatus returns null on network error', () async {
      // Even in mock mode, the API client will fail because there is
      // no mock implementation for getIngestionStatus on ApiClient.
      // The service catches all exceptions and returns null.
      final state = await service.getIngestionStatus('nonexistent-job');
      expect(state, isNull);
    });

    test('dispose after stopPolling does not throw', () {
      service.stopPolling();
      expect(() => service.dispose(), returnsNormally);
    });
  });

  group('IngestionState', () {
    test('fromJson parses all statuses', () {
      for (final status in IngestionStatus.values) {
        final state = IngestionState.fromJson('j', {'status': status.name});
        expect(state.status, equals(status));
      }
    });

    test('fromJson defaults to failed for unknown status', () {
      final state = IngestionState.fromJson('j', {'status': 'unknown_xyz'});
      expect(state.status, equals(IngestionStatus.failed));
    });

    test('fromJson parses error field', () {
      final state = IngestionState.fromJson('j', {
        'status': 'failed',
        'error': 'Something went wrong',
      });
      expect(state.error, equals('Something went wrong'));
    });

    test('fromJson parses totalChunks from result', () {
      final state = IngestionState.fromJson('j', {
        'status': 'completed',
        'result': {'totalChunks': 42},
      });
      expect(state.totalChunks, equals(42));
    });

    test('fromJson handles missing result', () {
      final state = IngestionState.fromJson('j', {'status': 'queued'});
      expect(state.totalChunks, isNull);
    });

    test('isFinished and isInProgress are mutually exclusive', () {
      for (final status in IngestionStatus.values) {
        final state = IngestionState(jobId: 'j', status: status);
        // They should never both be true
        expect(state.isFinished && state.isInProgress, isFalse);
      }
    });
  });
}
