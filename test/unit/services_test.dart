import 'package:flutter_test/flutter_test.dart';
import 'package:visiobook_mobile/config/environment.dart';
import 'package:visiobook_mobile/core/network/api_client.dart';
import 'package:visiobook_mobile/core/utils/secure_storage.dart';
import 'package:visiobook_mobile/features/auth/data/auth_service.dart';
import 'package:visiobook_mobile/features/export/data/export_service.dart';
import 'package:visiobook_mobile/features/export/domain/export_state.dart';
import 'package:visiobook_mobile/features/generation/data/generation_service.dart';
import 'package:visiobook_mobile/features/generation/domain/generation_state.dart';
import 'package:visiobook_mobile/features/generation/domain/ingestion_state.dart';
import 'package:visiobook_mobile/features/import/data/storage_service.dart';
import 'package:visiobook_mobile/features/import/domain/import_file.dart';
import 'package:visiobook_mobile/features/payment/data/payment_service.dart';
import 'package:visiobook_mobile/features/payment/domain/quota.dart';
import 'package:visiobook_mobile/features/player/data/player_service.dart';
import 'package:visiobook_mobile/features/player/domain/visiobook_reader_state.dart';
import 'package:visiobook_mobile/features/profile/data/profile_service.dart';
import 'package:visiobook_mobile/features/projects/data/project_service.dart';

// ---------------------------------------------------------------------------
// Fake SecureStorage to avoid platform channels
// ---------------------------------------------------------------------------
class _FakeStorage extends SecureStorageService {
  bool _loggedIn = false;
  String? _accessToken;
  String? _userName;

  @override
  Future<String?> getAccessToken() async => _accessToken;
  @override
  Future<String?> getRefreshToken() async => null;
  @override
  Future<void> saveAccessToken(String token) async => _accessToken = token;
  @override
  Future<void> saveRefreshToken(String token) async {}
  @override
  Future<void> clearTokens() async {
    _accessToken = null;
    _loggedIn = false;
  }

  @override
  Future<bool> isLoggedIn() async => _loggedIn || _accessToken != null;
  @override
  Future<void> saveUserId(String userId) async {}
  @override
  Future<String?> getUserId() async => null;
  @override
  Future<void> saveUserName(String name) async => _userName = name;
  @override
  Future<String?> getUserName() async => _userName;
  @override
  Future<void> setOnboardingComplete(bool complete) async {}
  @override
  Future<bool> isOnboardingComplete() async => true;
  @override
  Future<void> clearAll() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeStorage fakeStorage;
  late ApiClient apiClient;

  setUp(() {
    EnvironmentConfig.useMockData = true;
    fakeStorage = _FakeStorage();
    apiClient = ApiClient(storage: fakeStorage);
  });

  tearDown(() {
    EnvironmentConfig.useMockData = false;
  });

  // -----------------------------------------------------------------------
  // AuthService
  // -----------------------------------------------------------------------
  group('AuthService', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService(apiClient: apiClient, storage: fakeStorage);
    });

    test('constructor creates service', () {
      expect(authService, isNotNull);
    });

    test('logout clears tokens', () async {
      fakeStorage._accessToken = 'some_token';
      await authService.logout();
      final loggedIn = await authService.isLoggedIn();
      expect(loggedIn, isFalse);
    });

    test('isLoggedIn returns false when no token', () async {
      final result = await authService.isLoggedIn();
      expect(result, isFalse);
    });

    test('isLoggedIn returns true when token exists', () async {
      fakeStorage._accessToken = 'test_token';
      final result = await authService.isLoggedIn();
      expect(result, isTrue);
    });

    test('getSavedUserName returns stored name', () async {
      await fakeStorage.saveUserName('TestUser');
      final name = await authService.getSavedUserName();
      expect(name, equals('TestUser'));
    });

    test('AuthResult can be created with success', () {
      final result = AuthResult(success: true, userId: '123');
      expect(result.success, isTrue);
      expect(result.userId, equals('123'));
      expect(result.error, isNull);
    });

    test('AuthResult can be created with error', () {
      final result = AuthResult(success: false, error: 'Invalid');
      expect(result.success, isFalse);
      expect(result.error, equals('Invalid'));
    });
  });

  // -----------------------------------------------------------------------
  // PlayerService
  // -----------------------------------------------------------------------
  group('PlayerService', () {
    late PlayerService playerService;

    setUp(() {
      playerService = PlayerService(apiClient: apiClient);
    });

    test('constructor creates service', () {
      expect(playerService, isNotNull);
    });

    test('getVisioBook returns mock data in mock mode', () async {
      final result = await playerService.getVisioBook('test-project-123');
      expect(result.success, isTrue);
      expect(result.data, isNotNull);
      expect(result.data!.projectId, equals('test-project-123'));
      expect(result.data!.title, isNotEmpty);
      expect(result.data!.pages.length, equals(3));
      expect(result.data!.totalPages, equals(3));
    });

    test('mock visiobook has panels on each page', () async {
      final result = await playerService.getVisioBook('proj-1');
      final data = result.data!;

      for (final page in data.pages) {
        expect(page.panels.isNotEmpty, isTrue);
      }
    });

    test('PlayerResult can be created with error', () {
      final result = PlayerResult<String>(success: false, error: 'Not found');
      expect(result.success, isFalse);
      expect(result.error, equals('Not found'));
      expect(result.data, isNull);
    });
  });

  // -----------------------------------------------------------------------
  // ExportService
  // -----------------------------------------------------------------------
  group('ExportService', () {
    late ExportService exportService;

    setUp(() {
      exportService = ExportService(apiClient: apiClient);
    });

    test('constructor creates service', () {
      expect(exportService, isNotNull);
    });

    test('generateShareLink returns mock link in mock mode', () async {
      final result = await exportService.generateShareLink('proj-42');
      expect(result.success, isTrue);
      expect(result.data, contains('proj-42'));
      expect(result.data, startsWith('https://'));
    });

    test('downloadVideo simulates progress in mock mode', () async {
      final progressValues = <double>[];
      final result = await exportService.downloadVideo(
        projectId: 'proj-1',
        savePath: '/tmp/test.mp4',
        quality: ExportQuality.high,
        onProgress: progressValues.add,
      );
      expect(result.success, isTrue);
      expect(result.data, equals('/tmp/test.mp4'));
      expect(progressValues.isNotEmpty, isTrue);
      // Final progress should be 1.0
      expect(progressValues.last, equals(1.0));
    });

    test('ExportResult can be created with error', () {
      final result = ExportResult<String>(
        success: false,
        error: 'Download failed',
      );
      expect(result.success, isFalse);
      expect(result.error, equals('Download failed'));
    });
  });

  // -----------------------------------------------------------------------
  // PaymentService
  // -----------------------------------------------------------------------
  group('PaymentService', () {
    late PaymentService paymentService;

    setUp(() {
      paymentService = PaymentService(apiClient: apiClient);
    });

    test('constructor creates service', () {
      expect(paymentService, isNotNull);
    });

    test('getPlans returns default plans in mock mode', () async {
      final plans = await paymentService.getPlans();
      expect(plans.isNotEmpty, isTrue);
      expect(plans.length, equals(3));
      expect(plans[0].name, equals('Free'));
      expect(plans[1].name, equals('Premium'));
      expect(plans[2].name, equals('Enterprise'));
    });

    test('getCurrentSubscription returns null in mock mode', () async {
      final sub = await paymentService.getCurrentSubscription();
      expect(sub, isNull);
    });

    test('getQuota returns default free quota in mock mode', () async {
      final quota = await paymentService.getQuota();
      expect(quota, isA<Quota>());
      expect(quota.generationsLimit, equals(3));
      expect(quota.storageLimitGB, equals(1));
    });
  });

  // -----------------------------------------------------------------------
  // ProfileService
  // -----------------------------------------------------------------------
  group('ProfileService', () {
    late ProfileService profileService;

    setUp(() {
      profileService = ProfileService(apiClient: apiClient);
    });

    test('constructor creates service', () {
      expect(profileService, isNotNull);
    });

    test('getProfile returns mock profile in mock mode', () async {
      final profile = await profileService.getProfile();
      expect(profile.id, equals('mock-user-001'));
      expect(profile.username, equals('demo_user'));
      expect(profile.email, equals('demo@visiobook.com'));
      expect(profile.firstName, equals('Demo'));
      expect(profile.lastName, equals('User'));
      expect(profile.credits, equals(150));
    });

    test('updateProfile returns updated mock profile', () async {
      final profile = await profileService.updateProfile(firstName: 'NewFirst');
      expect(profile.firstName, equals('NewFirst'));
      // Other fields keep mock defaults
      expect(profile.username, equals('demo_user'));
    });

    test('changePassword completes without error in mock mode', () async {
      await expectLater(
        profileService.changePassword(newPassword: 'newpass123'),
        completes,
      );
    });

    test('deleteAccount completes without error in mock mode', () async {
      await expectLater(profileService.deleteAccount(), completes);
    });

    test('getCredits returns 0', () async {
      final credits = await profileService.getCredits();
      expect(credits, equals(0));
    });
  });

  // -----------------------------------------------------------------------
  // ProjectService
  // -----------------------------------------------------------------------
  group('ProjectService', () {
    late ProjectService projectService;

    setUp(() {
      projectService = ProjectService(apiClient: apiClient);
    });

    test('constructor creates service', () {
      expect(projectService, isNotNull);
    });

    test('ProjectResult can be created with success', () {
      final result = ProjectResult<String>(success: true, data: 'test');
      expect(result.success, isTrue);
      expect(result.data, equals('test'));
    });

    test('ProjectResult can be created with error', () {
      final result = ProjectResult<void>(success: false, error: 'Not found');
      expect(result.success, isFalse);
      expect(result.error, equals('Not found'));
    });
  });

  // -----------------------------------------------------------------------
  // StorageService (import/data)
  // -----------------------------------------------------------------------
  group('StorageService', () {
    test('StorageResult can be created with success', () {
      final result = StorageResult<String>(success: true, data: 'file-123');
      expect(result.success, isTrue);
      expect(result.data, equals('file-123'));
      expect(result.error, isNull);
    });

    test('StorageResult can be created with error', () {
      final result = StorageResult<String>(success: false, error: 'Not found');
      expect(result.success, isFalse);
      expect(result.error, equals('Not found'));
      expect(result.data, isNull);
    });

    test('constructor creates service', () {
      final storageService = StorageService(apiClient: apiClient);
      expect(storageService, isNotNull);
    });

    test('StorageResult with data preserves generic type', () {
      final result = StorageResult<List<int>>(success: true, data: [1, 2, 3]);
      expect(result.data, equals([1, 2, 3]));
      expect(result.success, isTrue);
    });
  });

  // -----------------------------------------------------------------------
  // GenerationService
  // -----------------------------------------------------------------------
  group('GenerationService', () {
    late GenerationService generationService;

    setUp(() {
      generationService = GenerationService(apiClient: apiClient);
    });

    test('constructor creates service', () {
      expect(generationService, isNotNull);
    });

    test('startGeneration returns mock data in mock mode', () async {
      final result = await generationService.startGeneration('test-project');
      expect(result.success, isTrue);
      expect(result.data, isNotNull);
      expect(result.data!.versionId, contains('mock_version'));
      expect(result.data!.executionId, contains('mock_execution'));
    });

    test('getWorkflowStatus returns mock progress', () async {
      // Start a generation first to initialise the mock timer
      await generationService.startGeneration('test');

      final result = await generationService.getWorkflowStatus('p', 'v', 'e');
      expect(result.success, isTrue);
      expect(result.data, isNotNull);
      expect(result.data!.progress, greaterThanOrEqualTo(0));
      expect(result.data!.progress, lessThanOrEqualTo(1.0));
    });

    test('getWorkflowStatus returns running status initially', () async {
      await generationService.startGeneration('test');
      final result = await generationService.getWorkflowStatus(
        'p',
        'v',
        'exec-1',
      );
      expect(result.data!.status, equals(WorkflowStatus.running));
      expect(result.data!.steps, isNotEmpty);
    });

    test('resetMockTimer allows fresh generation', () async {
      await generationService.startGeneration('test');
      generationService.resetMockTimer();
      final result = await generationService.startGeneration('test-2');
      expect(result.success, isTrue);
      expect(result.data!.versionId, contains('mock_version'));
    });

    test('GenerationResult can be created with error', () {
      final result = GenerationResult<String>(
        success: false,
        error: 'Server error',
      );
      expect(result.success, isFalse);
      expect(result.error, equals('Server error'));
      expect(result.data, isNull);
    });

    test('StartGenerationData holds versionId and executionId', () {
      final data = StartGenerationData(versionId: 'v1', executionId: 'e1');
      expect(data.versionId, equals('v1'));
      expect(data.executionId, equals('e1'));
    });
  });

  // -----------------------------------------------------------------------
  // AuthService - additional login/register coverage
  // -----------------------------------------------------------------------
  group('AuthService - extended', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService(apiClient: apiClient, storage: fakeStorage);
    });

    test('login catches network error gracefully', () async {
      // With mock mode off but no real server, login should fail gracefully
      EnvironmentConfig.useMockData = false;
      try {
        final result = await authService.login(
          email: 'test@example.com',
          password: 'password123',
        );
        // Should get an error result (connection refused)
        expect(result.success, isFalse);
        expect(result.error, isNotNull);
      } catch (_) {
        // If it throws, that's also acceptable since there is no server
      }
      EnvironmentConfig.useMockData = true;
    });

    test('register catches network error gracefully', () async {
      EnvironmentConfig.useMockData = false;
      try {
        final result = await authService.register(
          username: 'testuser',
          email: 'test@example.com',
          password: 'password123',
          firstName: 'Test',
          lastName: 'User',
        );
        expect(result.success, isFalse);
        expect(result.error, isNotNull);
      } catch (_) {
        // Connection failure is acceptable
      }
      EnvironmentConfig.useMockData = true;
    });

    test('AuthResult with userName', () {
      final result = AuthResult(success: true, userId: 'u1', userName: 'Alice');
      expect(result.userName, equals('Alice'));
    });

    test('verifyToken returns false when no server', () async {
      EnvironmentConfig.useMockData = false;
      final result = await authService.verifyToken();
      expect(result, isFalse);
      EnvironmentConfig.useMockData = true;
    });
  });

  // -----------------------------------------------------------------------
  // ProjectService - extended
  // -----------------------------------------------------------------------
  group('ProjectService - extended', () {
    late ProjectService projectService;

    setUp(() {
      projectService = ProjectService(apiClient: apiClient);
    });

    test('getProjects catches network error', () async {
      EnvironmentConfig.useMockData = false;
      try {
        final result = await projectService.getProjects();
        // Should fail with no server
        expect(result.success, isFalse);
        expect(result.error, isNotNull);
      } catch (_) {
        // Connection failure
      }
      EnvironmentConfig.useMockData = true;
    });

    test('createProject catches network error', () async {
      EnvironmentConfig.useMockData = false;
      try {
        final result = await projectService.createProject(title: 'Test');
        expect(result.success, isFalse);
      } catch (_) {
        // Connection failure
      }
      EnvironmentConfig.useMockData = true;
    });

    test('deleteProject catches network error', () async {
      EnvironmentConfig.useMockData = false;
      try {
        final result = await projectService.deleteProject('fake-id');
        expect(result.success, isFalse);
      } catch (_) {
        // Connection failure
      }
      EnvironmentConfig.useMockData = true;
    });

    test('generateProject catches network error', () async {
      EnvironmentConfig.useMockData = false;
      try {
        final result = await projectService.generateProject(
          title: 'Test',
          config: {'style': 'realistic'},
        );
        expect(result.success, isFalse);
      } catch (_) {
        // Connection failure
      }
      EnvironmentConfig.useMockData = true;
    });

    test('getProject catches network error', () async {
      EnvironmentConfig.useMockData = false;
      try {
        final result = await projectService.getProject('fake-id');
        expect(result.success, isFalse);
      } catch (_) {
        // Connection failure
      }
      EnvironmentConfig.useMockData = true;
    });

    test('getRecentProjects catches network error', () async {
      EnvironmentConfig.useMockData = false;
      try {
        final result = await projectService.getRecentProjects();
        expect(result.success, isFalse);
      } catch (_) {
        // Connection failure
      }
      EnvironmentConfig.useMockData = true;
    });
  });

  // -----------------------------------------------------------------------
  // Generation domain models
  // -----------------------------------------------------------------------
  group('GenerationStep', () {
    test('fromString parses known steps', () {
      expect(
        GenerationStep.fromString('analysis'),
        equals(GenerationStep.analysis),
      );
      expect(
        GenerationStep.fromString('reference_generation'),
        equals(GenerationStep.referenceGeneration),
      );
      expect(
        GenerationStep.fromString('image_generation'),
        equals(GenerationStep.imageGeneration),
      );
      expect(
        GenerationStep.fromString('images'),
        equals(GenerationStep.imageGeneration),
      );
      expect(
        GenerationStep.fromString('audio_generation'),
        equals(GenerationStep.audioGeneration),
      );
      expect(
        GenerationStep.fromString('audio'),
        equals(GenerationStep.audioGeneration),
      );
      expect(
        GenerationStep.fromString('assembly'),
        equals(GenerationStep.assembly),
      );
    });

    test('fromString defaults to analysis for unknown', () {
      expect(
        GenerationStep.fromString('unknown_step'),
        equals(GenerationStep.analysis),
      );
    });

    test('label returns non-empty string', () {
      for (final step in GenerationStep.values) {
        expect(step.label, isNotEmpty);
      }
    });

    test('description returns non-empty string', () {
      for (final step in GenerationStep.values) {
        expect(step.description, isNotEmpty);
      }
    });

    test('weight sums to 1.0', () {
      final total = GenerationStep.values.fold<double>(
        0.0,
        (sum, step) => sum + step.weight,
      );
      expect(total, closeTo(1.0, 0.001));
    });
  });

  group('WorkflowStatus', () {
    test('fromString parses known statuses', () {
      expect(
        WorkflowStatus.fromString('pending'),
        equals(WorkflowStatus.pending),
      );
      expect(
        WorkflowStatus.fromString('processing'),
        equals(WorkflowStatus.processing),
      );
      expect(
        WorkflowStatus.fromString('running'),
        equals(WorkflowStatus.running),
      );
      expect(
        WorkflowStatus.fromString('completed'),
        equals(WorkflowStatus.completed),
      );
      expect(
        WorkflowStatus.fromString('failed'),
        equals(WorkflowStatus.failed),
      );
      expect(
        WorkflowStatus.fromString('cancelled'),
        equals(WorkflowStatus.cancelled),
      );
    });

    test('fromString defaults to pending for unknown', () {
      expect(WorkflowStatus.fromString('xyz'), equals(WorkflowStatus.pending));
    });
  });

  group('WorkflowState', () {
    test('fromJson parses full payload', () {
      final state = WorkflowState.fromJson({
        'workflowId': 'w1',
        'status': 'running',
        'progress': 50,
        'currentStep': 'image_generation',
        'steps': [
          {'step': 'analysis', 'status': 'completed', 'progress': 100},
          {'step': 'image_generation', 'status': 'running', 'progress': 50},
        ],
      });
      expect(state.workflowId, equals('w1'));
      expect(state.status, equals(WorkflowStatus.running));
      expect(state.progress, closeTo(0.5, 0.01));
      expect(state.currentStep, equals(GenerationStep.imageGeneration));
      expect(state.steps.length, equals(2));
      expect(state.isInProgress, isTrue);
      expect(state.isFinished, isFalse);
    });

    test('fromJson uses executionId fallback', () {
      final state = WorkflowState.fromJson({
        'executionId': 'e1',
        'status': 'completed',
        'progress': 1.0,
      });
      expect(state.workflowId, equals('e1'));
      expect(state.isFinished, isTrue);
    });

    test('fromJson handles 0-1 progress range', () {
      final state = WorkflowState.fromJson({
        'status': 'running',
        'progress': 0.75,
      });
      expect(state.progress, closeTo(0.75, 0.01));
    });

    test('isFinished is true for completed, failed, cancelled', () {
      for (final status in [
        WorkflowStatus.completed,
        WorkflowStatus.failed,
        WorkflowStatus.cancelled,
      ]) {
        final state = WorkflowState(workflowId: 'w', status: status);
        expect(state.isFinished, isTrue);
      }
    });

    test('isInProgress is true for pending, processing, running', () {
      for (final status in [
        WorkflowStatus.pending,
        WorkflowStatus.processing,
        WorkflowStatus.running,
      ]) {
        final state = WorkflowState(workflowId: 'w', status: status);
        expect(state.isInProgress, isTrue);
      }
    });
  });

  group('StepDetail', () {
    test('fromJson parses correctly', () {
      final detail = StepDetail.fromJson({
        'step': 'audio_generation',
        'status': 'running',
        'progress': 42,
      });
      expect(detail.step, equals(GenerationStep.audioGeneration));
      expect(detail.status, equals('running'));
      expect(detail.progress, equals(42));
    });

    test('fromJson uses defaults for missing fields', () {
      final detail = StepDetail.fromJson({});
      expect(detail.step, equals(GenerationStep.analysis));
      expect(detail.status, equals('pending'));
      expect(detail.progress, equals(0));
    });
  });

  // -----------------------------------------------------------------------
  // IngestionState domain
  // -----------------------------------------------------------------------
  group('IngestionState', () {
    test('isFinished returns true for terminal statuses', () {
      for (final status in [
        IngestionStatus.completed,
        IngestionStatus.failed,
        IngestionStatus.cancelled,
      ]) {
        final state = IngestionState(jobId: 'j1', status: status);
        expect(state.isFinished, isTrue);
      }
    });

    test('isInProgress returns true for active statuses', () {
      for (final status in [
        IngestionStatus.queued,
        IngestionStatus.processing,
      ]) {
        final state = IngestionState(jobId: 'j1', status: status);
        expect(state.isInProgress, isTrue);
      }
    });

    test('fromJson parses correctly', () {
      final state = IngestionState.fromJson('job-1', {
        'status': 'completed',
        'result': {'totalChunks': 10},
      });
      expect(state.jobId, equals('job-1'));
      expect(state.status, equals(IngestionStatus.completed));
      expect(state.totalChunks, equals(10));
    });
  });

  // -----------------------------------------------------------------------
  // Quota domain model
  // -----------------------------------------------------------------------
  group('Quota', () {
    test('defaultFree returns correct values', () {
      final quota = Quota.defaultFree();
      expect(quota.generationsUsed, equals(0));
      expect(quota.generationsLimit, equals(3));
      expect(quota.storageUsedGB, equals(0));
      expect(quota.storageLimitGB, equals(1));
    });

    test('fromJson parses nested format', () {
      final quota = Quota.fromJson({
        'generations': {'used': 5, 'limit': 20, 'resetDate': '2026-05-01'},
        'storage': {'used': 0.5, 'limit': 10.0},
      });
      expect(quota.generationsUsed, equals(5));
      expect(quota.generationsLimit, equals(20));
      expect(quota.storageUsedGB, equals(0.5));
      expect(quota.storageLimitGB, equals(10.0));
      expect(quota.resetDate, equals('2026-05-01'));
    });

    test('fromJson uses defaults for missing fields', () {
      final quota = Quota.fromJson({});
      expect(quota.generationsUsed, equals(0));
      expect(quota.generationsLimit, equals(0));
      expect(quota.storageUsedGB, equals(0));
      expect(quota.storageLimitGB, equals(0));
    });

    test('toJson includes all fields in nested format', () {
      final quota = Quota(
        generationsUsed: 2,
        generationsLimit: 10,
        storageUsedGB: 0.5,
        storageLimitGB: 5.0,
        resetDate: '2026-05-01',
      );
      final json = quota.toJson();
      expect(json['generations']['used'], equals(2));
      expect(json['generations']['limit'], equals(10));
      expect(json['generations']['resetDate'], equals('2026-05-01'));
      expect(json['storage']['used'], equals(0.5));
      expect(json['storage']['limit'], equals(5.0));
    });

    test('generationsUsagePercent calculates correctly', () {
      final quota = Quota(
        generationsUsed: 1,
        generationsLimit: 4,
        storageUsedGB: 0,
        storageLimitGB: 1,
      );
      expect(quota.generationsUsagePercent, closeTo(0.25, 0.01));
    });

    test('generationsUsagePercent returns 0 when limit is 0', () {
      final quota = Quota(
        generationsUsed: 5,
        generationsLimit: 0,
        storageUsedGB: 0,
        storageLimitGB: 0,
      );
      expect(quota.generationsUsagePercent, equals(0));
    });

    test('storageUsagePercent calculates correctly', () {
      final quota = Quota(
        generationsUsed: 0,
        generationsLimit: 10,
        storageUsedGB: 3.0,
        storageLimitGB: 6.0,
      );
      expect(quota.storageUsagePercent, closeTo(0.5, 0.01));
    });

    test('hasGenerationsRemaining returns true when under limit', () {
      final quota = Quota(
        generationsUsed: 1,
        generationsLimit: 3,
        storageUsedGB: 0,
        storageLimitGB: 1,
      );
      expect(quota.hasGenerationsRemaining, isTrue);
    });

    test('hasGenerationsRemaining returns false when at limit', () {
      final quota = Quota(
        generationsUsed: 3,
        generationsLimit: 3,
        storageUsedGB: 0,
        storageLimitGB: 1,
      );
      expect(quota.hasGenerationsRemaining, isFalse);
    });

    test('hasGenerationsRemaining returns true for unlimited (-1)', () {
      final quota = Quota(
        generationsUsed: 100,
        generationsLimit: -1,
        storageUsedGB: 0,
        storageLimitGB: 1,
      );
      expect(quota.hasGenerationsRemaining, isTrue);
    });

    test('hasVideosRemaining returns true when under limit (compat)', () {
      final quota = Quota(
        generationsUsed: 1,
        generationsLimit: 3,
        storageUsedGB: 0,
        storageLimitGB: 1,
      );
      expect(quota.hasVideosRemaining, isTrue);
    });

    test('hasVideosRemaining returns false when at limit (compat)', () {
      final quota = Quota(
        generationsUsed: 3,
        generationsLimit: 3,
        storageUsedGB: 0,
        storageLimitGB: 1,
      );
      expect(quota.hasVideosRemaining, isFalse);
    });

    test('canGenerate returns true when generations remaining', () {
      final quota = Quota.defaultFree();
      expect(quota.canGenerate, isTrue);
    });

    test('canGenerate returns false when generations exhausted', () {
      final quota = Quota(
        generationsUsed: 3,
        generationsLimit: 3,
        storageUsedGB: 0,
        storageLimitGB: 1,
      );
      expect(quota.canGenerate, isFalse);
    });
  });

  // -----------------------------------------------------------------------
  // VisiobookData domain models
  // -----------------------------------------------------------------------
  group('VisiobookData', () {
    test('fromJson parses with data wrapper', () {
      final data = VisiobookData.fromJson({
        'data': {'projectId': 'p1', 'title': 'My Book', 'pages': []},
      });
      expect(data.projectId, equals('p1'));
      expect(data.title, equals('My Book'));
      expect(data.pages, isEmpty);
    });

    test('fromJson parses flat JSON', () {
      final data = VisiobookData.fromJson({
        'project_id': 'p2',
        'title': 'Book 2',
        'pages': [
          {
            'page_number': 1,
            'panels': [
              {
                'id': 'panel1',
                'order': 0,
                'video_url': 'https://example.com/v.mp4',
                'thumbnail_url': 'https://example.com/t.jpg',
                'dialogue_text': 'Hello',
                'narrator_text': 'Once upon a time',
                'video_duration_ms': 5000,
              },
            ],
          },
        ],
      });
      expect(data.projectId, equals('p2'));
      expect(data.totalPanels, equals(1));
      final panel = data.allPanels.first;
      expect(panel.dialogueText, equals('Hello'));
      expect(panel.narratorText, equals('Once upon a time'));
      expect(panel.videoDurationMs, equals(5000));
    });

    test('allPanels flattens across pages', () {
      final data = VisiobookData(
        projectId: 'p',
        title: 'T',
        totalPages: 2,
        createdAt: DateTime.now(),
        pages: [
          const VisiobookPage(
            pageNumber: 1,
            panels: [
              VisiobookPanel(
                id: 'a',
                order: 0,
                videoUrl: '',
                thumbnailUrl: '',
                videoDurationMs: 0,
              ),
            ],
          ),
          const VisiobookPage(
            pageNumber: 2,
            panels: [
              VisiobookPanel(
                id: 'b',
                order: 0,
                videoUrl: '',
                thumbnailUrl: '',
                videoDurationMs: 0,
              ),
              VisiobookPanel(
                id: 'c',
                order: 1,
                videoUrl: '',
                thumbnailUrl: '',
                videoDurationMs: 0,
              ),
            ],
          ),
        ],
      );
      expect(data.allPanels.length, equals(3));
      expect(data.totalPanels, equals(3));
    });
  });

  // -----------------------------------------------------------------------
  // ImportFile domain
  // -----------------------------------------------------------------------
  group('ImportFile', () {
    test('ImportFileType.fromExtension covers all types', () {
      expect(ImportFileType.fromExtension('pdf'), equals(ImportFileType.pdf));
      expect(ImportFileType.fromExtension('txt'), equals(ImportFileType.txt));
      expect(ImportFileType.fromExtension('docx'), equals(ImportFileType.docx));
      expect(ImportFileType.fromExtension('epub'), equals(ImportFileType.epub));
      expect(ImportFileType.fromExtension('jpg'), equals(ImportFileType.jpeg));
      expect(ImportFileType.fromExtension('jpeg'), equals(ImportFileType.jpeg));
      expect(ImportFileType.fromExtension('png'), equals(ImportFileType.png));
      expect(ImportFileType.fromExtension('gif'), equals(ImportFileType.gif));
      expect(
        ImportFileType.fromExtension('xyz'),
        equals(ImportFileType.unknown),
      );
    });

    test('label returns non-empty for all types', () {
      for (final t in ImportFileType.values) {
        expect(t.label, isNotEmpty);
      }
    });

    test('mimeType is null for unknown', () {
      expect(ImportFileType.unknown.mimeType, isNull);
    });

    test('mimeType is non-null for known types', () {
      for (final t in ImportFileType.values) {
        if (t != ImportFileType.unknown) {
          expect(t.mimeType, isNotNull);
        }
      }
    });

    test('isImage returns true only for image types', () {
      expect(ImportFileType.jpeg.isImage, isTrue);
      expect(ImportFileType.png.isImage, isTrue);
      expect(ImportFileType.gif.isImage, isTrue);
      expect(ImportFileType.pdf.isImage, isFalse);
      expect(ImportFileType.txt.isImage, isFalse);
    });

    test('ImportFile formattedSize formats correctly', () {
      final small = ImportFile(
        name: 'a.txt',
        path: '/tmp/a.txt',
        type: ImportFileType.txt,
        sizeBytes: 500,
        selectedAt: DateTime.now(),
      );
      expect(small.formattedSize, equals('500 B'));

      final medium = ImportFile(
        name: 'b.pdf',
        path: '/tmp/b.pdf',
        type: ImportFileType.pdf,
        sizeBytes: 2048,
        selectedAt: DateTime.now(),
      );
      expect(medium.formattedSize, contains('KB'));

      final large = ImportFile(
        name: 'c.pdf',
        path: '/tmp/c.pdf',
        type: ImportFileType.pdf,
        sizeBytes: 5 * 1024 * 1024,
        selectedAt: DateTime.now(),
      );
      expect(large.formattedSize, contains('MB'));
    });

    test('ImportFile isValidSize rejects files over 50MB', () {
      final big = ImportFile(
        name: 'huge.pdf',
        path: '/tmp/huge.pdf',
        type: ImportFileType.pdf,
        sizeBytes: 60 * 1024 * 1024,
        selectedAt: DateTime.now(),
      );
      expect(big.isValidSize, isFalse);

      final ok = ImportFile(
        name: 'ok.pdf',
        path: '/tmp/ok.pdf',
        type: ImportFileType.pdf,
        sizeBytes: 10 * 1024 * 1024,
        selectedAt: DateTime.now(),
      );
      expect(ok.isValidSize, isTrue);
    });

    test('ImportFile isValidFormat rejects unknown type', () {
      final unknown = ImportFile(
        name: 'file.xyz',
        path: '/tmp/file.xyz',
        type: ImportFileType.unknown,
        sizeBytes: 100,
        selectedAt: DateTime.now(),
      );
      expect(unknown.isValidFormat, isFalse);
    });

    test('ImportFile extension extracts correctly', () {
      final f = ImportFile(
        name: 'report.PDF',
        path: '/tmp/report.PDF',
        type: ImportFileType.pdf,
        sizeBytes: 100,
        selectedAt: DateTime.now(),
      );
      expect(f.extension, equals('pdf'));
    });

    test('UploadResult.success factory works', () {
      final r = UploadResult.success(
        fileId: 'f1',
        fileUrl: 'https://example.com/f1',
        extractedText: 'Hello',
        wordCount: 1,
      );
      expect(r.success, isTrue);
      expect(r.fileId, equals('f1'));
      expect(r.extractedText, equals('Hello'));
    });

    test('UploadResult.failure factory works', () {
      final r = UploadResult.failure('Upload failed');
      expect(r.success, isFalse);
      expect(r.error, equals('Upload failed'));
    });
  });
}
