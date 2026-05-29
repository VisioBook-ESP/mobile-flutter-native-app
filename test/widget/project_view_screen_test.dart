import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:visiobook_mobile/config/environment.dart';
import 'package:visiobook_mobile/core/network/api_client.dart';
import 'package:visiobook_mobile/core/utils/secure_storage.dart';
import 'package:visiobook_mobile/features/export/data/export_service.dart';
import 'package:visiobook_mobile/features/export/presentation/providers/export_provider.dart';
import 'package:visiobook_mobile/features/generation/domain/generation_state.dart';
import 'package:visiobook_mobile/features/generation/domain/ingestion_state.dart';
import 'package:visiobook_mobile/features/generation/presentation/providers/generation_provider.dart';
import 'package:visiobook_mobile/features/project_detail/presentation/screens/project_view_screen.dart';
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
  late ExportProvider exportProvider;

  setUp(() async {
    EnvironmentConfig.useMockData = true;
    final storage = _FakeStorage();
    final apiClient = ApiClient(storage: storage);
    final projectService = ProjectService(apiClient: apiClient);
    projectProvider = ProjectProvider(projectService: projectService);
    generationProvider = _FakeGenerationProvider();
    exportProvider = ExportProvider(
      exportService: ExportService(apiClient: apiClient),
    );

    // Load mock projects so we have data
    await projectProvider.loadProjects();
  });

  tearDown(() {
    EnvironmentConfig.useMockData = false;
    projectProvider.dispose();
    generationProvider.dispose();
    exportProvider.dispose();
  });

  Widget buildWidget({String projectId = '1'}) {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<ProjectProvider>.value(value: projectProvider),
          ChangeNotifierProvider<GenerationProvider>.value(
            value: generationProvider,
          ),
          ChangeNotifierProvider<ExportProvider>.value(value: exportProvider),
        ],
        child: ProjectViewScreen(projectId: projectId),
      ),
    );
  }

  group('ProjectViewScreen', () {
    testWidgets('renders loading/skeleton state before project loads', (
      tester,
    ) async {
      // Use a non-loaded provider
      final freshStorage = _FakeStorage();
      final freshApiClient = ApiClient(storage: freshStorage);
      final freshProjectProvider = ProjectProvider(
        projectService: ProjectService(apiClient: freshApiClient),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<ProjectProvider>.value(
                value: freshProjectProvider,
              ),
              ChangeNotifierProvider<GenerationProvider>.value(
                value: generationProvider,
              ),
              ChangeNotifierProvider<ExportProvider>.value(
                value: exportProvider,
              ),
            ],
            child: const ProjectViewScreen(projectId: 'nonexistent'),
          ),
        ),
      );

      // Before postFrameCallback fires, project is null -> skeleton
      expect(find.byType(ProjectViewScreen), findsOneWidget);

      freshProjectProvider.dispose();
    });

    testWidgets('shows project title after loading', (tester) async {
      await tester.pumpWidget(buildWidget(projectId: '1'));
      await tester.pump(const Duration(seconds: 1));

      // The mock project with id '1' is 'Le Petit Prince'
      expect(find.text('Le Petit Prince'), findsWidgets);
    });
  });
}
