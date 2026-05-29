import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:visiobook_mobile/config/environment.dart';
import 'package:visiobook_mobile/core/network/api_client.dart';
import 'package:visiobook_mobile/core/utils/secure_storage.dart';
import 'package:visiobook_mobile/features/generation/domain/generation_state.dart';
import 'package:visiobook_mobile/features/generation/domain/ingestion_state.dart';
import 'package:visiobook_mobile/features/generation/presentation/providers/generation_provider.dart';
import 'package:visiobook_mobile/features/history/presentation/screens/visiobooks_history_screen.dart';
import 'package:visiobook_mobile/features/projects/data/project_service.dart';
import 'package:visiobook_mobile/features/projects/presentation/providers/project_provider.dart';

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

/// Fake GenerationProvider to avoid timers and network calls.
class _FakeGenerationProvider extends ChangeNotifier
    implements GenerationProvider {
  final Map<String, ActiveGeneration> _activeGenerations = {};

  @override
  Map<String, ActiveGeneration> get activeGenerations =>
      Map.unmodifiable(_activeGenerations);

  @override
  bool hasActiveGeneration(String projectId) =>
      _activeGenerations.containsKey(projectId);

  @override
  ActiveGeneration? getGeneration(String projectId) =>
      _activeGenerations[projectId];

  @override
  double getProgress(String projectId) =>
      _activeGenerations[projectId]?.workflowState?.progress ?? 0.0;

  @override
  GenerationStep getStep(String projectId) =>
      _activeGenerations[projectId]?.workflowState?.currentStep ??
      GenerationStep.analysis;

  @override
  WorkflowStatus getStatus(String projectId) =>
      _activeGenerations[projectId]?.workflowState?.status ??
      WorkflowStatus.pending;

  @override
  bool isFinished(String projectId) =>
      _activeGenerations[projectId]?.workflowState?.isFinished ?? false;

  @override
  bool isInProgress(String projectId) =>
      _activeGenerations[projectId]?.workflowState?.isInProgress ?? false;

  @override
  String? getVideoUrl(String projectId) =>
      _activeGenerations[projectId]?.workflowState?.videoUrl;

  @override
  String? getThumbnailUrl(String projectId) =>
      _activeGenerations[projectId]?.workflowState?.thumbnailUrl;

  @override
  Duration? getEstimatedTimeRemaining(String projectId) =>
      _activeGenerations[projectId]?.workflowState?.estimatedTimeRemaining;

  @override
  String getStepLabel(String projectId) => getStep(projectId).label;

  @override
  String getStepDescription(String projectId) => getStep(projectId).description;

  @override
  String? getError(String projectId) =>
      _activeGenerations[projectId]?.error ??
      _activeGenerations[projectId]?.workflowState?.errorMessage;

  @override
  bool isFailed(String projectId) {
    final gen = _activeGenerations[projectId];
    if (gen == null) return false;
    if (gen.error != null) return true;
    if (gen.isCancelled) return true;
    final status = gen.workflowState?.status;
    return status == WorkflowStatus.failed ||
        status == WorkflowStatus.cancelled;
  }

  @override
  void startMockGenerations(List<String> projectIds) {}

  @override
  Future<bool> startGeneration(String projectId) async => true;

  @override
  void startPolling(String projectId, String versionId, String executionId) {}

  @override
  void cancelGeneration(String projectId) {}

  @override
  void clearGeneration(String projectId) {
    _activeGenerations.remove(projectId);
    notifyListeners();
  }

  @override
  void clearError(String projectId) {}

  @override
  void startIngestionTracking(String projectId, String jobId) {}

  @override
  IngestionState? getIngestionState(String projectId) => null;

  @override
  void clearIngestionState(String projectId) {}

  @override
  GenerationCallback? onGenerationFinished;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProjectProvider projectProvider;
  late _FakeGenerationProvider generationProvider;

  setUp(() async {
    EnvironmentConfig.useMockData = true;
    final storage = _FakeStorage();
    final apiClient = ApiClient(storage: storage);
    final projectService = ProjectService(apiClient: apiClient);
    projectProvider = ProjectProvider(projectService: projectService);
    generationProvider = _FakeGenerationProvider();

    // Pre-load mock projects
    await projectProvider.loadProjects();
  });

  tearDown(() {
    EnvironmentConfig.useMockData = false;
    projectProvider.dispose();
    generationProvider.dispose();
  });

  Widget buildWidget() {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<ProjectProvider>.value(value: projectProvider),
          ChangeNotifierProvider<GenerationProvider>.value(
            value: generationProvider,
          ),
        ],
        child: const VisiobooksHistoryScreen(),
      ),
    );
  }

  group('VisiobooksHistoryScreen', () {
    testWidgets('renders Mes VisioBooks title', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Mes VisioBooks'), findsOneWidget);
    });

    testWidgets('shows filter chips', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Tous'), findsOneWidget);
      expect(find.text('Pr\u00eats'), findsOneWidget);
      expect(find.text('En cours'), findsOneWidget);
    });

    testWidgets('shows project grid after loading', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));

      // Mock data has projects - check that the screen renders them
      // At least one project title should be visible (Le Petit Prince is id 1)
      expect(find.text('Le Petit Prince'), findsOneWidget);
    });

    testWidgets('shows project status badges', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));

      // Project status labels from ProjectStatus.label
      // At least one status badge should be present
      final statusLabels = ['Brouillon', 'En cours...', 'Prêt', 'Erreur'];
      bool foundAtLeastOne = false;
      for (final label in statusLabels) {
        if (find.text(label).evaluate().isNotEmpty) {
          foundAtLeastOne = true;
          break;
        }
      }
      expect(foundAtLeastOne, isTrue);
    });

    testWidgets('filter chips are tappable', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));

      // Tap on "Prêts" filter
      await tester.tap(find.text('Prêts'));
      await tester.pump();

      // Tap on "En cours" filter
      await tester.tap(find.text('En cours'));
      await tester.pump();

      // Tap back on "Tous"
      await tester.tap(find.text('Tous'));
      await tester.pump();

      // Screen should still be showing
      expect(find.text('Mes VisioBooks'), findsOneWidget);
    });
  });
}
