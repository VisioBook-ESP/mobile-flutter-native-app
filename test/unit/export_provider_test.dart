import 'package:flutter_test/flutter_test.dart';
import 'package:visiobook_mobile/config/environment.dart';
import 'package:visiobook_mobile/core/network/api_client.dart';
import 'package:visiobook_mobile/core/utils/secure_storage.dart';
import 'package:visiobook_mobile/features/export/data/export_service.dart';
import 'package:visiobook_mobile/features/export/domain/export_state.dart';
import 'package:visiobook_mobile/features/export/presentation/providers/export_provider.dart';

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

  late ExportProvider provider;
  late ExportService exportService;

  setUp(() {
    EnvironmentConfig.useMockData = true;
    exportService = ExportService(
      apiClient: ApiClient(storage: _FakeSecureStorage()),
    );
    provider = ExportProvider(exportService: exportService);
  });

  tearDown(() {
    EnvironmentConfig.useMockData = false;
    provider.dispose();
  });

  group('ExportProvider initial state', () {
    test('status is idle', () {
      expect(provider.status, ExportStatus.idle);
    });

    test('downloadProgress is 0', () {
      expect(provider.downloadProgress, 0.0);
    });

    test('downloadedFilePath is null', () {
      expect(provider.downloadedFilePath, isNull);
    });

    test('shareLink is null', () {
      expect(provider.shareLink, isNull);
    });

    test('error is null', () {
      expect(provider.error, isNull);
    });

    test('selectedQuality is high', () {
      expect(provider.selectedQuality, ExportQuality.high);
    });

    test('isDownloading is false', () {
      expect(provider.isDownloading, isFalse);
    });

    test('isCompleted is false', () {
      expect(provider.isCompleted, isFalse);
    });

    test('downloadState is idle', () {
      expect(provider.downloadState, ExportDownloadState.idle);
    });

    test('downloadError is null', () {
      expect(provider.downloadError, isNull);
    });
  });

  group('ExportProvider setQuality', () {
    test('sets quality from ExportQuality enum', () {
      provider.setQuality(ExportQuality.low);
      expect(provider.selectedQuality, ExportQuality.low);
    });

    test('sets quality from string label', () {
      provider.setQuality('720p');
      expect(provider.selectedQuality, ExportQuality.medium);
    });

    test('sets quality to high from unknown string', () {
      provider.setQuality('unknown');
      expect(provider.selectedQuality, ExportQuality.high);
    });

    test('notifies listeners', () {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.setQuality(ExportQuality.medium);

      expect(notifyCount, 1);
    });
  });

  group('ExportProvider downloadVideo mock mode', () {
    test('downloads video successfully', () async {
      await provider.downloadVideo('project_123');

      expect(provider.status, ExportStatus.completed);
      expect(provider.isCompleted, isTrue);
      expect(provider.downloadedFilePath, isNotNull);
      expect(provider.downloadedFilePath, contains('VisioBook_project_123'));
      expect(provider.downloadProgress, 1.0);
      expect(provider.error, isNull);
    });

    test('downloadState is completed after download', () async {
      await provider.downloadVideo('project_123');

      expect(provider.downloadState, ExportDownloadState.completed);
    });
  });

  group('ExportProvider startDownload', () {
    test('startDownload with quality string', () async {
      await provider.startDownload('project_123', '480p');

      expect(provider.selectedQuality, ExportQuality.low);
      expect(provider.status, ExportStatus.completed);
    });

    test('startDownload with ExportQuality enum', () async {
      await provider.startDownload('project_123', ExportQuality.medium);

      expect(provider.selectedQuality, ExportQuality.medium);
      expect(provider.status, ExportStatus.completed);
    });

    test('startDownload without quality keeps current', () async {
      provider.setQuality(ExportQuality.low);
      await provider.startDownload('project_123');

      expect(provider.selectedQuality, ExportQuality.low);
      expect(provider.status, ExportStatus.completed);
    });
  });

  group('ExportProvider generateAndCopyShareLink mock mode', () {
    test('generates share link', () async {
      await provider.generateAndCopyShareLink('project_123');

      expect(provider.shareLink, isNotNull);
      expect(provider.shareLink, 'https://visiobook.app/share/project_123');
      expect(provider.error, isNull);
    });
  });

  group('ExportProvider reset', () {
    test('clears all state', () async {
      await provider.downloadVideo('project_123');
      expect(provider.status, ExportStatus.completed);

      provider.reset();

      expect(provider.status, ExportStatus.idle);
      expect(provider.downloadProgress, 0.0);
      expect(provider.downloadedFilePath, isNull);
      expect(provider.shareLink, isNull);
      expect(provider.error, isNull);
      expect(provider.selectedQuality, ExportQuality.high);
    });

    test('notifies listeners', () {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.reset();

      expect(notifyCount, 1);
    });
  });
}
