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
import 'package:visiobook_mobile/features/import/presentation/screens/scanner_screen.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------
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
        path: '/dashboard',
        builder: (context, state) => const Scaffold(body: Text('Dashboard')),
      ),
    ],
  );

  final fakeStorage = _FakeStorage();
  final apiClient = ApiClient(storage: fakeStorage);
  final storageService = StorageService(apiClient: apiClient);

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ImportProvider>(
        create: (_) => ImportProvider(storageService: storageService),
      ),
      ChangeNotifierProvider<TextsProvider>(
        create: (_) => _SafeTextsProvider(),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    EnvironmentConfig.useMockData = true;
  });

  tearDown(() {
    EnvironmentConfig.useMockData = false;
  });

  group('ScannerScreen', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_wrapWithRouter(const ScannerScreen()));
      // Use pump instead of pumpAndSettle because camera init triggers
      // async work and possibly timers that never complete in test.
      await tester.pump(const Duration(seconds: 1));

      // The screen should render a Scaffold regardless of camera state
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('shows loading indicator when camera not ready', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapWithRouter(const ScannerScreen()));
      // On initial pump, camera is not yet initialised, so loading screen shows
      await tester.pump();

      // The loading screen contains a CircularProgressIndicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows initialisation text while loading', (tester) async {
      await tester.pumpWidget(_wrapWithRouter(const ScannerScreen()));
      await tester.pump();

      expect(find.textContaining('Initialisation'), findsOneWidget);
    });

    testWidgets('renders Scaffold after waiting for camera init attempt', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapWithRouter(const ScannerScreen()));
      // Pump a few frames to let async permission/camera calls fail
      await tester.pump(const Duration(seconds: 2));

      // Still has a scaffold
      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}
