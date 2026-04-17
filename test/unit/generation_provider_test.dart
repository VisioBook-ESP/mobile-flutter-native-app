import 'package:flutter_test/flutter_test.dart';
import 'package:visiobook_mobile/core/network/api_client.dart';
import 'package:visiobook_mobile/core/utils/secure_storage.dart';
import 'package:visiobook_mobile/features/generation/data/generation_service.dart';
import 'package:visiobook_mobile/features/generation/domain/generation_state.dart';
import 'package:visiobook_mobile/features/generation/presentation/providers/generation_provider.dart';

// ---------------------------------------------------------------------------
// Stubs to avoid platform channels (FlutterSecureStorage)
// ---------------------------------------------------------------------------

/// A minimal SecureStorageService subclass that overrides all methods so that
/// no platform channel is ever invoked.
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

/// A GenerationService subclass that never makes real HTTP calls.
/// All methods return deterministic results.
class _FakeGenerationService extends GenerationService {
  bool startGenerationCalled = false;
  bool shouldFail = false;

  _FakeGenerationService()
    : super(apiClient: ApiClient(storage: _FakeSecureStorage()));

  @override
  Future<GenerationResult<StartGenerationData>> startGeneration(
    String projectId,
  ) async {
    startGenerationCalled = true;
    if (shouldFail) {
      return GenerationResult(success: false, error: 'Mock error');
    }
    return GenerationResult(
      success: true,
      data: StartGenerationData(
        versionId: 'fake_version',
        executionId: 'fake_execution',
      ),
    );
  }

  @override
  Future<GenerationResult<WorkflowState>> getWorkflowStatus(
    String projectId,
    String versionId,
    String executionId,
  ) async {
    return GenerationResult(
      success: true,
      data: WorkflowState(
        workflowId: executionId,
        status: WorkflowStatus.running,
        progress: 0.5,
        currentStep: GenerationStep.imageGeneration,
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GenerationProvider provider;
  late _FakeGenerationService fakeService;

  setUp(() {
    fakeService = _FakeGenerationService();
    provider = GenerationProvider(generationService: fakeService);
  });

  tearDown(() {
    // Cancel all active generations to stop polling timers before dispose
    for (final projectId in provider.activeGenerations.keys.toList()) {
      provider.cancelGeneration(projectId);
    }
    provider.dispose();
  });

  group('GenerationProvider initial state', () {
    test('activeGenerations is empty', () {
      expect(provider.activeGenerations, isEmpty);
    });

    test('hasActiveGeneration returns false for any project', () {
      expect(provider.hasActiveGeneration('unknown'), isFalse);
    });

    test('getGeneration returns null for unknown project', () {
      expect(provider.getGeneration('unknown'), isNull);
    });

    test('getProgress returns 0.0 for unknown project', () {
      expect(provider.getProgress('unknown'), 0.0);
    });

    test('getStep returns analysis for unknown project', () {
      expect(provider.getStep('unknown'), GenerationStep.analysis);
    });

    test('getStatus returns pending for unknown project', () {
      expect(provider.getStatus('unknown'), WorkflowStatus.pending);
    });

    test('isFinished returns false for unknown project', () {
      expect(provider.isFinished('unknown'), isFalse);
    });

    test('isInProgress returns false for unknown project', () {
      expect(provider.isInProgress('unknown'), isFalse);
    });

    test('getVideoUrl returns null for unknown project', () {
      expect(provider.getVideoUrl('unknown'), isNull);
    });

    test('getThumbnailUrl returns null for unknown project', () {
      expect(provider.getThumbnailUrl('unknown'), isNull);
    });

    test('getEstimatedTimeRemaining returns null for unknown project', () {
      expect(provider.getEstimatedTimeRemaining('unknown'), isNull);
    });

    test('getError returns null for unknown project', () {
      expect(provider.getError('unknown'), isNull);
    });

    test('getStepLabel returns Analyse for unknown project', () {
      expect(provider.getStepLabel('unknown'), 'Analyse');
    });

    test(
      'getStepDescription returns analysis description for unknown project',
      () {
        expect(
          provider.getStepDescription('unknown'),
          GenerationStep.analysis.description,
        );
      },
    );
  });

  group('GenerationProvider cancel and clear on empty state', () {
    test('cancelGeneration on non-existent project does nothing', () {
      // Should not throw
      provider.cancelGeneration('nonexistent');
      expect(provider.activeGenerations, isEmpty);
    });

    test('clearGeneration on non-existent project does nothing', () {
      // Should not throw
      provider.clearGeneration('nonexistent');
      expect(provider.activeGenerations, isEmpty);
    });

    test('clearError on non-existent project does nothing', () {
      // Should not throw
      provider.clearError('nonexistent');
      expect(provider.activeGenerations, isEmpty);
    });
  });

  group('GenerationProvider startGeneration', () {
    test('successful start creates an active generation', () async {
      final result = await provider.startGeneration('project1');

      expect(result, isTrue);
      expect(fakeService.startGenerationCalled, isTrue);
      expect(provider.hasActiveGeneration('project1'), isTrue);
      expect(provider.getGeneration('project1'), isNotNull);
      expect(provider.getGeneration('project1')!.versionId, 'fake_version');
      expect(provider.getGeneration('project1')!.executionId, 'fake_execution');
    });

    test('failed start sets error on the generation', () async {
      fakeService.shouldFail = true;

      final result = await provider.startGeneration('project1');

      expect(result, isFalse);
      expect(provider.hasActiveGeneration('project1'), isTrue);
      expect(provider.getError('project1'), 'Mock error');
    });

    test('starting generation notifies listeners', () async {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.startGeneration('project1');

      // At least 2 notifications: initial creation + after service response
      expect(notifyCount, greaterThanOrEqualTo(2));
    });
  });

  group('GenerationProvider cancelGeneration', () {
    test('cancelling an active generation marks it as cancelled', () async {
      await provider.startGeneration('project1');

      provider.cancelGeneration('project1');

      final gen = provider.getGeneration('project1');
      expect(gen, isNotNull);
      expect(gen!.isCancelled, isTrue);
    });
  });

  group('GenerationProvider clearGeneration', () {
    test('clearing an active generation removes it', () async {
      await provider.startGeneration('project1');
      expect(provider.hasActiveGeneration('project1'), isTrue);

      provider.clearGeneration('project1');

      expect(provider.hasActiveGeneration('project1'), isFalse);
      expect(provider.activeGenerations, isEmpty);
    });

    test('clearing notifies listeners', () async {
      await provider.startGeneration('project1');

      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.clearGeneration('project1');

      expect(notifyCount, 1);
    });
  });

  group('GenerationProvider clearError', () {
    test('clears error on active generation', () async {
      fakeService.shouldFail = true;
      await provider.startGeneration('project1');
      expect(provider.getError('project1'), isNotNull);

      provider.clearError('project1');

      expect(provider.getError('project1'), isNull);
    });
  });

  group('GenerationProvider multiple generations', () {
    test('can track multiple projects simultaneously', () async {
      final result1 = await provider.startGeneration('project1');
      final result2 = await provider.startGeneration('project2');

      expect(result1, isTrue);
      expect(result2, isTrue);
      expect(provider.activeGenerations.length, 2);
      expect(provider.hasActiveGeneration('project1'), isTrue);
      expect(provider.hasActiveGeneration('project2'), isTrue);
    });

    test('clearing one project does not affect another', () async {
      await provider.startGeneration('project1');
      await provider.startGeneration('project2');

      provider.clearGeneration('project1');

      expect(provider.hasActiveGeneration('project1'), isFalse);
      expect(provider.hasActiveGeneration('project2'), isTrue);
    });

    test('cancelling one project does not affect another', () async {
      await provider.startGeneration('project1');
      await provider.startGeneration('project2');

      provider.cancelGeneration('project1');

      expect(provider.getGeneration('project1')!.isCancelled, isTrue);
      expect(provider.getGeneration('project2')!.isCancelled, isFalse);
    });
  });

  group('GenerationProvider startMockGenerations', () {
    test('starts mock generations for a list of project IDs', () {
      provider.startMockGenerations(['projA', 'projB', 'projC']);

      expect(provider.activeGenerations.length, 3);
      expect(provider.hasActiveGeneration('projA'), isTrue);
      expect(provider.hasActiveGeneration('projB'), isTrue);
      expect(provider.hasActiveGeneration('projC'), isTrue);
    });

    test('skips projects that already have an active generation', () async {
      await provider.startGeneration('projA');
      expect(provider.activeGenerations.length, 1);

      provider.startMockGenerations(['projA', 'projB']);

      // projA already existed, so only projB is added
      expect(provider.activeGenerations.length, 2);
      // Original projA generation should still have 'fake_version'
      expect(provider.getGeneration('projA')!.versionId, 'fake_version');
    });

    test('empty list does nothing', () {
      provider.startMockGenerations([]);
      expect(provider.activeGenerations, isEmpty);
    });
  });

  group('GenerationProvider ingestion tracking', () {
    test('getIngestionState returns null for unknown project', () {
      expect(provider.getIngestionState('unknown'), isNull);
    });

    test('clearIngestionState on unknown project does not throw', () {
      // Should not throw
      provider.clearIngestionState('nonexistent');
    });

    test('clearIngestionState notifies listeners', () {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.clearIngestionState('nonexistent');
      expect(notifyCount, 1);
    });
  });

  group('GenerationProvider onGenerationFinished callback', () {
    test('callback is initially null', () {
      expect(provider.onGenerationFinished, isNull);
    });

    test('callback can be set and retrieved', () {
      bool callbackCalled = false;
      provider.onGenerationFinished = (projectId, success, error) {
        callbackCalled = true;
      };

      expect(provider.onGenerationFinished, isNotNull);
      provider.onGenerationFinished!('p1', true, null);
      expect(callbackCalled, isTrue);
    });

    test('callback receives correct parameters', () {
      String? receivedProjectId;
      bool? receivedSuccess;
      String? receivedError;
      provider.onGenerationFinished = (projectId, success, error) {
        receivedProjectId = projectId;
        receivedSuccess = success;
        receivedError = error;
      };

      provider.onGenerationFinished!('proj42', false, 'something failed');

      expect(receivedProjectId, 'proj42');
      expect(receivedSuccess, isFalse);
      expect(receivedError, 'something failed');
    });

    test('callback can be set to null', () {
      provider.onGenerationFinished = (projectId, success, error) {};
      expect(provider.onGenerationFinished, isNotNull);

      provider.onGenerationFinished = null;
      expect(provider.onGenerationFinished, isNull);
    });
  });

  group('GenerationProvider multiple concurrent generations', () {
    test('three concurrent generations track independently', () async {
      final r1 = await provider.startGeneration('p1');
      final r2 = await provider.startGeneration('p2');
      final r3 = await provider.startGeneration('p3');

      expect(r1, isTrue);
      expect(r2, isTrue);
      expect(r3, isTrue);
      expect(provider.activeGenerations.length, 3);

      // Each has its own version/execution IDs
      expect(provider.getGeneration('p1')!.versionId, 'fake_version');
      expect(provider.getGeneration('p2')!.versionId, 'fake_version');
      expect(provider.getGeneration('p3')!.versionId, 'fake_version');
    });

    test('error on one does not affect others', () async {
      await provider.startGeneration('p1');

      fakeService.shouldFail = true;
      await provider.startGeneration('p2');

      fakeService.shouldFail = false;
      await provider.startGeneration('p3');

      expect(provider.getError('p1'), isNull);
      expect(provider.getError('p2'), 'Mock error');
      expect(provider.getError('p3'), isNull);
    });

    test('clear all generations one by one', () async {
      await provider.startGeneration('p1');
      await provider.startGeneration('p2');
      await provider.startGeneration('p3');

      provider.clearGeneration('p1');
      expect(provider.activeGenerations.length, 2);

      provider.clearGeneration('p2');
      expect(provider.activeGenerations.length, 1);

      provider.clearGeneration('p3');
      expect(provider.activeGenerations, isEmpty);
    });
  });

  group('GenerationProvider dispose', () {
    test('dispose does not throw even with active generations', () async {
      await provider.startGeneration('project1');

      // Cancel first to stop polling timers, then dispose
      provider.cancelGeneration('project1');
      provider.dispose();

      // Re-create to avoid double-dispose in tearDown
      fakeService = _FakeGenerationService();
      provider = GenerationProvider(generationService: fakeService);
    });
  });
}
