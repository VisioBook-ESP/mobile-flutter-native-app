import 'package:flutter_test/flutter_test.dart';
import 'package:visiobook_mobile/config/environment.dart';
import 'package:visiobook_mobile/core/network/api_client.dart';
import 'package:visiobook_mobile/core/utils/secure_storage.dart';
import 'package:visiobook_mobile/features/import/data/storage_service.dart';
import 'package:visiobook_mobile/features/import/domain/import_file.dart';
import 'package:visiobook_mobile/features/import/presentation/providers/import_provider.dart';

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

  late ImportProvider provider;

  setUp(() {
    EnvironmentConfig.useMockData = true;
    final storageService = StorageService(
      apiClient: ApiClient(storage: _FakeSecureStorage()),
    );
    provider = ImportProvider(storageService: storageService);
  });

  tearDown(() {
    EnvironmentConfig.useMockData = false;
    provider.dispose();
  });

  group('uploadFile sets correct states during mock flow', () {
    test('transitions through uploading to uploaded', () async {
      // Use uploadScannedImages to set _selectedFile, then verify states
      final states = <ImportState>[];
      provider.addListener(() {
        states.add(provider.state);
      });

      final result = await provider.uploadScannedImages(['/tmp/test.jpg']);

      expect(result, isTrue);
      // The first notification should be uploading
      expect(states.first, ImportState.uploading);
      // The last notification should be uploaded
      expect(states.last, ImportState.uploaded);
      // Progress should be 1.0 at the end
      expect(provider.uploadProgress, 1.0);
    });

    test('uploadFile without file goes to error state', () async {
      final states = <ImportState>[];
      provider.addListener(() {
        states.add(provider.state);
      });

      final result = await provider.uploadFile();

      expect(result, isFalse);
      expect(states.last, ImportState.error);
      expect(provider.error, 'Aucun fichier selectionne');
    });
  });

  group('uploadFile sets lastIngestionJobId and lastIngestionFileId', () {
    test('sets job and file IDs after mock upload', () async {
      await provider.uploadScannedImages(['/tmp/test.jpg']);

      expect(provider.lastIngestionJobId, isNotNull);
      expect(provider.lastIngestionJobId!.startsWith('mock_job_'), isTrue);
      expect(provider.lastIngestionFileId, isNotNull);
      expect(provider.lastIngestionFileId!.startsWith('mock_file_'), isTrue);
    });

    test('job and file IDs are cleared on reset', () async {
      await provider.uploadScannedImages(['/tmp/test.jpg']);
      expect(provider.lastIngestionJobId, isNotNull);

      provider.reset();

      expect(provider.lastIngestionJobId, isNull);
      expect(provider.lastIngestionFileId, isNull);
    });
  });

  group('uploadScannedImages in mock mode', () {
    test('works with single image', () async {
      final result = await provider.uploadScannedImages(['/tmp/single.jpg']);

      expect(result, isTrue);
      expect(provider.state, ImportState.uploaded);
      expect(provider.selectedFile, isNotNull);
      expect(provider.selectedFile!.type, ImportFileType.jpeg);
      expect(provider.uploadResult, isNotNull);
      expect(provider.uploadResult!.success, isTrue);
      expect(provider.uploadResult!.extractedText, isNotNull);
      expect(provider.uploadResult!.extractedText!.isNotEmpty, isTrue);
    });

    test('works with multiple images', () async {
      final result = await provider.uploadScannedImages([
        '/tmp/page1.jpg',
        '/tmp/page2.jpg',
        '/tmp/page3.jpg',
      ]);

      expect(result, isTrue);
      expect(provider.state, ImportState.uploaded);
      expect(provider.uploadResult, isNotNull);
      expect(provider.uploadResult!.success, isTrue);
    });

    test('fails with empty image list', () async {
      final result = await provider.uploadScannedImages([]);

      expect(result, isFalse);
      expect(provider.state, ImportState.error);
      expect(provider.error, 'Aucune image capturee');
    });

    test('sets selectedFile name to scan pattern', () async {
      await provider.uploadScannedImages(['/tmp/scan.jpg']);

      expect(provider.selectedFile, isNotNull);
      expect(provider.selectedFile!.name.startsWith('scan_'), isTrue);
    });
  });

  group('updateExtractedText with existing uploadResult', () {
    test('updates text and recalculates word count', () async {
      await provider.uploadScannedImages(['/tmp/test.jpg']);

      provider.updateExtractedText('Hello world test');

      expect(provider.uploadResult!.extractedText, 'Hello world test');
      expect(provider.uploadResult!.wordCount, 3);
    });

    test('preserves fileId and fileUrl after update', () async {
      await provider.uploadScannedImages(['/tmp/test.jpg']);
      final originalFileId = provider.uploadResult!.fileId;

      provider.updateExtractedText('New text content');

      expect(provider.uploadResult!.fileId, originalFileId);
      expect(provider.uploadResult!.success, isTrue);
    });

    test('handles empty text', () async {
      await provider.uploadScannedImages(['/tmp/test.jpg']);

      provider.updateExtractedText('');

      expect(provider.uploadResult!.extractedText, '');
      expect(provider.uploadResult!.wordCount, 0);
    });

    test('handles text with only whitespace', () async {
      await provider.uploadScannedImages(['/tmp/test.jpg']);

      provider.updateExtractedText('   \n\t  ');

      expect(provider.uploadResult!.extractedText, '   \n\t  ');
      expect(provider.uploadResult!.wordCount, 0);
    });

    test('does nothing when uploadResult is null', () {
      provider.updateExtractedText('some text');

      expect(provider.uploadResult, isNull);
    });

    test('notifies listeners on update', () async {
      await provider.uploadScannedImages(['/tmp/test.jpg']);

      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.updateExtractedText('Updated text');

      expect(notifyCount, 1);
    });
  });
}
