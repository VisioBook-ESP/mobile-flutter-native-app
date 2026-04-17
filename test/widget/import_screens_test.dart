import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:visiobook_mobile/config/environment.dart';
import 'package:visiobook_mobile/core/network/api_client.dart';
import 'package:visiobook_mobile/core/utils/secure_storage.dart';
import 'package:visiobook_mobile/features/generation/domain/ingestion_state.dart';
import 'package:visiobook_mobile/features/history/domain/user_file.dart';
import 'package:visiobook_mobile/features/history/presentation/providers/texts_provider.dart';
import 'package:visiobook_mobile/features/import/data/storage_service.dart';
import 'package:visiobook_mobile/features/import/presentation/providers/import_provider.dart';
import 'package:visiobook_mobile/features/import/presentation/screens/file_import_screen.dart';
import 'package:visiobook_mobile/features/import/presentation/screens/input_mode_screen.dart';
import 'package:visiobook_mobile/features/import/presentation/screens/text_preview_screen.dart';

class _FakeStorage implements SecureStorageService {
  @override
  Future<String?> getAccessToken() async => 'fake-token';
  @override
  Future<String?> getRefreshToken() async => null;
  @override
  Future<void> saveAccessToken(String t) async {}
  @override
  Future<void> saveRefreshToken(String t) async {}
  @override
  Future<void> clearTokens() async {}
  @override
  Future<bool> isLoggedIn() async => true;
  @override
  Future<void> saveUserId(String userId) async {}
  @override
  Future<String?> getUserId() async => 'fake-id';
  @override
  Future<void> saveUserName(String name) async {}
  @override
  Future<String?> getUserName() async => 'Demo';
  @override
  Future<void> setOnboardingComplete(bool complete) async {}
  @override
  Future<bool> isOnboardingComplete() async => true;
  @override
  Future<void> clearAll() async {}
}

/// A safe TextsProvider that avoids platform channels and timers.
class _SafeTextsProvider extends ChangeNotifier implements TextsProvider {
  @override
  TextsState get state => TextsState.loaded;
  @override
  List<UserFile> get files => [];
  @override
  String? get error => null;
  @override
  bool get isLoading => false;

  @override
  Future<void> loadFiles() async {}
  @override
  UserFile? getFileById(String id) => null;
  @override
  void startIngestionTracking(String fileId, String jobId, String fileName) {}
  @override
  IngestionState? getIngestionState(String fileId) => null;
  @override
  bool isIngesting(String fileId) => false;
  @override
  void clearIngestionState(String fileId) {}
}

Widget _wrapWithRouter(Widget screen) {
  final router = GoRouter(
    initialLocation: '/test',
    routes: [
      GoRoute(path: '/test', builder: (context, state) => screen),
      GoRoute(
        path: '/file-import',
        builder: (context, state) => const Scaffold(body: Text('FileImport')),
      ),
      GoRoute(
        path: '/scan',
        builder: (context, state) => const Scaffold(body: Text('Scan')),
      ),
      GoRoute(
        path: '/text-preview',
        builder: (context, state) => const Scaffold(body: Text('TextPreview')),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const Scaffold(body: Text('Dashboard')),
      ),
      GoRoute(
        path: '/create-project',
        builder: (context, state) =>
            const Scaffold(body: Text('CreateProject')),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => EnvironmentConfig.useMockData = true);
  tearDown(() => EnvironmentConfig.useMockData = false);

  ImportProvider createImportProvider() {
    final storage = _FakeStorage();
    final apiClient = ApiClient(storage: storage);
    final storageService = StorageService(apiClient: apiClient);
    return ImportProvider(storageService: storageService);
  }

  group('InputModeScreen', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(_wrapWithRouter(const InputModeScreen()));
      await tester.pump();

      expect(find.text('Nouveau projet'), findsOneWidget);
    });

    testWidgets('shows two option cards', (tester) async {
      await tester.pumpWidget(_wrapWithRouter(const InputModeScreen()));
      await tester.pump();

      expect(find.text('Importer un fichier'), findsOneWidget);
      expect(find.text('Scanner un document'), findsOneWidget);
      expect(find.text('PDF, TXT, DOCX, EPUB'), findsOneWidget);
      expect(find.text('Appareil photo'), findsOneWidget);
    });

    testWidgets('shows method selection prompt', (tester) async {
      await tester.pumpWidget(_wrapWithRouter(const InputModeScreen()));
      await tester.pump();

      expect(find.textContaining('Comment souhaitez-vous'), findsOneWidget);
    });
  });

  group('FileImportScreen', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ImportProvider>(
              create: (_) => createImportProvider(),
            ),
            ChangeNotifierProvider<TextsProvider>(
              create: (_) => _SafeTextsProvider(),
            ),
          ],
          child: _wrapWithRouter(const FileImportScreen()),
        ),
      );
      await tester.pump();

      expect(find.text('Importer un fichier'), findsOneWidget);
    });

    testWidgets('shows file picker zone', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ImportProvider>(
              create: (_) => createImportProvider(),
            ),
            ChangeNotifierProvider<TextsProvider>(
              create: (_) => _SafeTextsProvider(),
            ),
          ],
          child: _wrapWithRouter(const FileImportScreen()),
        ),
      );
      await tester.pump();

      // Drop zone text
      expect(find.textContaining('Appuyez pour'), findsOneWidget);
      // Format info
      expect(find.textContaining('Formats support'), findsOneWidget);
      // Browse button
      expect(find.text('Parcourir les fichiers'), findsOneWidget);
    });

    testWidgets('shows format and size info', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ImportProvider>(
              create: (_) => createImportProvider(),
            ),
            ChangeNotifierProvider<TextsProvider>(
              create: (_) => _SafeTextsProvider(),
            ),
          ],
          child: _wrapWithRouter(const FileImportScreen()),
        ),
      );
      await tester.pump();

      expect(find.textContaining('50 MB'), findsOneWidget);
    });
  });

  group('TextPreviewScreen', () {
    testWidgets('renders with mock upload result', (tester) async {
      final storage = _FakeStorage();
      final apiClient = ApiClient(storage: storage);
      final storageService = StorageService(apiClient: apiClient);
      final importProvider = ImportProvider(storageService: storageService);

      // We need to set up the provider with uploaded state.
      // Use mock upload flow - pick a file then mock upload.
      // Instead, we directly manipulate via the provider's mock mode.

      await tester.pumpWidget(
        ChangeNotifierProvider<ImportProvider>.value(
          value: importProvider,
          child: _wrapWithRouter(const TextPreviewScreen()),
        ),
      );
      await tester.pump();

      // Without upload result, shows fallback message
      expect(find.text('Aucun texte disponible'), findsOneWidget);
    });

    testWidgets('shows preview UI elements with data', (tester) async {
      final storage = _FakeStorage();
      final apiClient = ApiClient(storage: storage);
      final storageService = StorageService(apiClient: apiClient);
      final importProvider = ImportProvider(storageService: storageService);

      // Simulate that an upload has completed by setting internal state
      // We use the mock data path: set a selected file and upload result
      // through the provider's public API
      importProvider.updateExtractedText(
        'Ceci est un texte de test pour verifier la preview.',
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<ImportProvider>.value(
          value: importProvider,
          child: _wrapWithRouter(const TextPreviewScreen()),
        ),
      );
      await tester.pump();

      // AppBar title should be present
      expect(find.textContaining('Aper'), findsOneWidget);
    });

    testWidgets('shows summary and edit button after mock upload', (
      tester,
    ) async {
      final importProvider = createImportProvider();

      // Use runAsync to execute the real async mock upload
      await tester.runAsync(() async {
        await importProvider.uploadScannedImages(['/tmp/test_scan.jpg']);
      });

      await tester.pumpWidget(
        ChangeNotifierProvider<ImportProvider>.value(
          value: importProvider,
          child: _wrapWithRouter(const TextPreviewScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      // AppBar title
      expect(find.textContaining('Aper'), findsOneWidget);
      // Edit button in app bar
      expect(find.text('Modifier'), findsOneWidget);
    });

    testWidgets('shows word count after upload', (tester) async {
      final importProvider = createImportProvider();

      await tester.runAsync(() async {
        await importProvider.uploadScannedImages(['/tmp/test_scan.jpg']);
      });

      await tester.pumpWidget(
        ChangeNotifierProvider<ImportProvider>.value(
          value: importProvider,
          child: _wrapWithRouter(const TextPreviewScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      // Word count label
      expect(find.textContaining('mots'), findsOneWidget);
    });
  });

  group('FileImportScreen additional', () {
    testWidgets('shows file picker zone in initial state', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ImportProvider>(
              create: (_) => createImportProvider(),
            ),
            ChangeNotifierProvider<TextsProvider>(
              create: (_) => _SafeTextsProvider(),
            ),
          ],
          child: _wrapWithRouter(const FileImportScreen()),
        ),
      );
      await tester.pump();

      // In initial state, the browse button is shown
      expect(find.text('Parcourir les fichiers'), findsOneWidget);
      // File picker zone is shown
      expect(find.textContaining('Appuyez pour'), findsOneWidget);
      // Title
      expect(find.textContaining('lectionnez un fichier'), findsOneWidget);
    });
  });
}
