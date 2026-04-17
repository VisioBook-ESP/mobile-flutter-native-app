import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:visiobook_mobile/config/environment.dart';
import 'package:visiobook_mobile/core/utils/secure_storage.dart';
import 'package:visiobook_mobile/features/project_creation/presentation/screens/create_project_screen.dart';
import 'package:visiobook_mobile/features/projects/presentation/providers/project_provider.dart';
import 'package:visiobook_mobile/features/projects/data/project_service.dart';
import 'package:visiobook_mobile/core/network/api_client.dart';

class _FakeStorage implements SecureStorageService {
  @override
  Future<String?> getAccessToken() async => 'fake';
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
  Future<String?> getUserId() async => null;
  @override
  Future<void> saveUserName(String name) async {}
  @override
  Future<String?> getUserName() async => null;
  @override
  Future<void> setOnboardingComplete(bool complete) async {}
  @override
  Future<bool> isOnboardingComplete() async => false;
  @override
  Future<void> clearAll() async {}
}

void _suppressOverflowErrors() {
  final origHandler = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.toString().contains('overflowed')) return;
    origHandler?.call(details);
  };
  addTearDown(() => FlutterError.onError = origHandler);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProjectProvider projectProvider;

  setUp(() {
    EnvironmentConfig.useMockData = true;
    final storage = _FakeStorage();
    final apiClient = ApiClient(storage: storage);
    final projectService = ProjectService(apiClient: apiClient);
    projectProvider = ProjectProvider(projectService: projectService);
  });

  tearDown(() {
    EnvironmentConfig.useMockData = false;
    projectProvider.dispose();
  });

  Widget buildWidget() {
    return MaterialApp(
      home: ChangeNotifierProvider<ProjectProvider>.value(
        value: projectProvider,
        child: const CreateProjectScreen(),
      ),
    );
  }

  group('CreateProjectScreen', () {
    testWidgets('renders without error', (tester) async {
      _suppressOverflowErrors();
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(CreateProjectScreen), findsOneWidget);
    });

    testWidgets('shows title input', (tester) async {
      _suppressOverflowErrors();
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Mon VisioBook...'), findsOneWidget);
    });

    testWidgets('shows style and config sections', (tester) async {
      _suppressOverflowErrors();
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));

      // Section labels
      expect(find.text('Titre du projet'), findsOneWidget);
      expect(find.text('Source du texte'), findsOneWidget);

      // Source options
      expect(find.text('Choisir un texte existant'), findsOneWidget);
      expect(find.text('Importer un fichier'), findsOneWidget);
      expect(find.text('Scanner un document'), findsOneWidget);

      // Generate button
      expect(find.text('Generer le VisioBook'), findsOneWidget);
    });

    testWidgets('shows source text options render', (tester) async {
      _suppressOverflowErrors();
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));

      // All three source options should be present
      expect(find.text('Choisir un texte existant'), findsOneWidget);
      expect(find.text('Importer un fichier'), findsOneWidget);
      expect(find.text('Scanner un document'), findsOneWidget);

      // Source section label
      expect(find.text('Source du texte'), findsOneWidget);
    });

    testWidgets('shows generate button', (tester) async {
      _suppressOverflowErrors();
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));

      // Generate button should exist
      final generateButton = find.text('Generer le VisioBook');
      expect(generateButton, findsOneWidget);
    });
  });
}
