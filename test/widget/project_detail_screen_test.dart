import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:visiobook_mobile/config/environment.dart';
import 'package:visiobook_mobile/core/utils/secure_storage.dart';
import 'package:visiobook_mobile/features/project_detail/presentation/providers/project_detail_provider.dart';
import 'package:visiobook_mobile/features/project_detail/presentation/screens/project_detail_screen.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProjectDetailProvider detailProvider;

  setUp(() {
    EnvironmentConfig.useMockData = true;
    final storage = _FakeStorage();
    final apiClient = ApiClient(storage: storage);
    final projectService = ProjectService(apiClient: apiClient);
    detailProvider = ProjectDetailProvider(projectService: projectService);
  });

  tearDown(() {
    EnvironmentConfig.useMockData = false;
    detailProvider.dispose();
  });

  Widget buildWidget({String? projectId}) {
    return MaterialApp(
      home: ChangeNotifierProvider<ProjectDetailProvider>.value(
        value: detailProvider,
        child: ProjectDetailScreen(projectId: projectId),
      ),
    );
  }

  group('ProjectDetailScreen', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(ProjectDetailScreen), findsOneWidget);
    });

    testWidgets('shows configuration title in app bar', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Configuration'), findsOneWidget);
    });

    testWidgets('shows configuration options after loading project', (
      tester,
    ) async {
      // Suppress overflow errors from StyleSelector
      final origHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.toString().contains('overflowed')) return;
        origHandler?.call(details);
      };
      addTearDown(() => FlutterError.onError = origHandler);

      // Init with mock import data so provider has a project
      detailProvider.initFromImport(
        fileId: 'test-file',
        fileName: 'test.txt',
        extractedText: 'Some sample text for testing purposes.',
        wordCount: 7,
      );

      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));

      // Should show the title field
      expect(find.text('Titre du projet'), findsOneWidget);

      // Should show generate button
      expect(find.text('Générer le VisioBook'), findsOneWidget);
    });
  });
}
