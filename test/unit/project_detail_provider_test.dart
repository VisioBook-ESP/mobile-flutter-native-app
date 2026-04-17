import 'package:flutter_test/flutter_test.dart';
import 'package:visiobook_mobile/config/environment.dart';
import 'package:visiobook_mobile/core/network/api_client.dart';
import 'package:visiobook_mobile/core/utils/secure_storage.dart';
import 'package:visiobook_mobile/features/project_detail/domain/project_config.dart';
import 'package:visiobook_mobile/features/project_detail/presentation/providers/project_detail_provider.dart';
import 'package:visiobook_mobile/features/projects/data/project_service.dart';
import 'package:visiobook_mobile/features/projects/domain/project.dart';

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

  late ProjectDetailProvider provider;
  late ProjectService projectService;

  setUp(() {
    EnvironmentConfig.useMockData = true;
    projectService = ProjectService(
      apiClient: ApiClient(storage: _FakeSecureStorage()),
    );
    provider = ProjectDetailProvider(projectService: projectService);
  });

  tearDown(() {
    EnvironmentConfig.useMockData = false;
    provider.dispose();
  });

  group('ProjectDetailProvider initial state', () {
    test('state is initial', () {
      expect(provider.state, ProjectDetailState.initial);
    });

    test('project is null', () {
      expect(provider.project, isNull);
    });

    test('config has default values', () {
      expect(provider.config.style, VideoStyle.realistic);
      expect(provider.config.language, AudioLanguage.french);
      expect(provider.config.vibe, VideoVibe.calm);
      expect(provider.config.format, VideoFormat.portrait);
    });

    test('error is null', () {
      expect(provider.error, isNull);
    });

    test('extractedText is null', () {
      expect(provider.extractedText, isNull);
    });

    test('wordCount is null', () {
      expect(provider.wordCount, isNull);
    });

    test('isLoading is false', () {
      expect(provider.isLoading, isFalse);
    });

    test('isSaving is false', () {
      expect(provider.isSaving, isFalse);
    });

    test('isGenerating is false', () {
      expect(provider.isGenerating, isFalse);
    });

    test('hasProject is false', () {
      expect(provider.hasProject, isFalse);
    });
  });

  group('ProjectDetailProvider initFromImport', () {
    test('sets project from file data', () {
      provider.initFromImport(
        fileId: 'file_123',
        fileName: 'my_document.pdf',
        extractedText: 'Some extracted text content here.',
        wordCount: 5,
      );

      expect(provider.state, ProjectDetailState.loaded);
      expect(provider.hasProject, isTrue);
      expect(provider.project!.id, 'temp_file_123');
      expect(provider.project!.title, 'My Document');
      expect(provider.project!.status, ProjectStatus.draft);
      expect(provider.extractedText, 'Some extracted text content here.');
      expect(provider.wordCount, 5);
    });

    test('generates title from file name with underscores', () {
      provider.initFromImport(fileId: 'f1', fileName: 'hello_world_test.txt');

      expect(provider.project!.title, 'Hello World Test');
    });

    test('generates title from file name with dashes', () {
      provider.initFromImport(fileId: 'f1', fileName: 'my-great-book.epub');

      expect(provider.project!.title, 'My Great Book');
    });

    test('sets description from extracted text', () {
      provider.initFromImport(
        fileId: 'f1',
        fileName: 'doc.pdf',
        extractedText: 'Short text',
      );

      expect(provider.project!.description, 'Short text');
    });

    test('truncates long description', () {
      final longText = 'A' * 300;
      provider.initFromImport(
        fileId: 'f1',
        fileName: 'doc.pdf',
        extractedText: longText,
      );

      expect(provider.project!.description!.length, 203); // 200 + '...'
      expect(provider.project!.description!.endsWith('...'), isTrue);
    });

    test('notifies listeners', () {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.initFromImport(fileId: 'f1', fileName: 'doc.pdf');

      expect(notifyCount, 1);
    });
  });

  group('ProjectDetailProvider setStyle', () {
    test('updates style', () {
      provider.setStyle(VideoStyle.manga);
      expect(provider.config.style, VideoStyle.manga);
    });

    test('notifies listeners', () {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.setStyle(VideoStyle.cartoon);

      expect(notifyCount, 1);
    });
  });

  group('ProjectDetailProvider setLanguage', () {
    test('updates language', () {
      provider.setLanguage(AudioLanguage.english);
      expect(provider.config.language, AudioLanguage.english);
    });
  });

  group('ProjectDetailProvider setVibe', () {
    test('updates vibe', () {
      provider.setVibe(VideoVibe.epic);
      expect(provider.config.vibe, VideoVibe.epic);
    });
  });

  group('ProjectDetailProvider setTitle', () {
    test('does nothing when no project', () {
      provider.setTitle('New Title');
      expect(provider.project, isNull);
    });

    test('updates project title', () {
      provider.initFromImport(fileId: 'f1', fileName: 'doc.pdf');

      provider.setTitle('Custom Title');

      expect(provider.project!.title, 'Custom Title');
    });

    test('notifies listeners', () {
      provider.initFromImport(fileId: 'f1', fileName: 'doc.pdf');

      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.setTitle('New Title');

      expect(notifyCount, 1);
    });
  });

  group('ProjectDetailProvider loadProject mock mode', () {
    test('loads project in mock mode', () async {
      await provider.loadProject('test_id');

      expect(provider.state, ProjectDetailState.loaded);
      expect(provider.hasProject, isTrue);
      expect(provider.project!.id, 'test_id');
      expect(provider.project!.title, 'Projet test_id');
      expect(provider.project!.status, ProjectStatus.draft);
    });
  });

  group('ProjectDetailProvider saveProject mock mode', () {
    test('returns null when no project', () async {
      final result = await provider.saveProject();
      expect(result, isNull);
    });

    test('saves and returns project id in mock mode', () async {
      provider.initFromImport(fileId: 'f1', fileName: 'doc.pdf');

      final result = await provider.saveProject();

      expect(result, isNotNull);
      expect(result!.startsWith('project_'), isTrue);
      expect(provider.state, ProjectDetailState.loaded);
    });
  });

  group('ProjectDetailProvider generateProject mock mode', () {
    test('generates project in mock mode', () async {
      provider.initFromImport(fileId: 'f1', fileName: 'doc.pdf');

      final result = await provider.generateProject();

      expect(result, isNotNull);
      expect(result!.containsKey('projectId'), isTrue);
      expect(result.containsKey('versionId'), isTrue);
      expect(result.containsKey('executionId'), isTrue);
      expect(result['versionId']!.startsWith('mock_version_'), isTrue);
      expect(result['executionId']!.startsWith('mock_execution_'), isTrue);
      expect(provider.state, ProjectDetailState.loaded);
    });
  });

  group('ProjectDetailProvider reset', () {
    test('clears all state', () {
      provider.initFromImport(
        fileId: 'f1',
        fileName: 'doc.pdf',
        extractedText: 'text',
        wordCount: 1,
      );
      provider.setStyle(VideoStyle.manga);

      provider.reset();

      expect(provider.state, ProjectDetailState.initial);
      expect(provider.project, isNull);
      expect(provider.config.style, VideoStyle.realistic);
      expect(provider.config.language, AudioLanguage.french);
      expect(provider.error, isNull);
      expect(provider.extractedText, isNull);
      expect(provider.wordCount, isNull);
    });

    test('notifies listeners', () {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.reset();

      expect(notifyCount, 1);
    });
  });

  group('ProjectDetailProvider clearError', () {
    test('clears error when no project returns to initial', () {
      provider.clearError();
      expect(provider.error, isNull);
      expect(provider.state, ProjectDetailState.initial);
    });

    test('clears error when project exists returns to loaded', () {
      provider.initFromImport(fileId: 'f1', fileName: 'doc.pdf');
      // Provider is in loaded state, clearError should keep it
      provider.clearError();
      expect(provider.state, ProjectDetailState.loaded);
    });
  });
}
