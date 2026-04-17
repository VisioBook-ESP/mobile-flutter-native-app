import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:visiobook_mobile/config/environment.dart';
import 'package:visiobook_mobile/features/generation/domain/generation_state.dart';
import 'package:visiobook_mobile/features/generation/domain/ingestion_state.dart';
import 'package:visiobook_mobile/features/generation/presentation/providers/generation_provider.dart';
import 'package:visiobook_mobile/features/generation/presentation/screens/generation_screen.dart';

/// A fake GenerationProvider that does not create any timers or
/// network calls. It allows us to pre-set generation state for tests.
class _FakeGenerationProvider extends ChangeNotifier
    implements GenerationProvider {
  final Map<String, ActiveGeneration> _activeGenerations = {};

  void setGeneration(String projectId, ActiveGeneration generation) {
    _activeGenerations[projectId] = generation;
    notifyListeners();
  }

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
  void startMockGenerations(List<String> projectIds) {}

  @override
  Future<bool> startGeneration(String projectId) async => true;

  @override
  void startPolling(String projectId, String versionId, String executionId) {
    // No-op: do not create timers
  }

  @override
  void cancelGeneration(String projectId) {
    final gen = _activeGenerations[projectId];
    if (gen != null) {
      gen.isCancelled = true;
      notifyListeners();
    }
  }

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

  late _FakeGenerationProvider generationProvider;

  setUp(() {
    EnvironmentConfig.useMockData = true;
    generationProvider = _FakeGenerationProvider();
  });

  tearDown(() {
    EnvironmentConfig.useMockData = false;
    generationProvider.dispose();
  });

  Widget buildWidget() {
    return MaterialApp(
      home: ChangeNotifierProvider<GenerationProvider>.value(
        value: generationProvider,
        child: const GenerationScreen(
          projectId: 'test-project',
          versionId: 'test-version',
          executionId: 'test-execution',
        ),
      ),
    );
  }

  group('GenerationScreen', () {
    testWidgets('renders loading state when no generation data', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders generating state with step labels', (tester) async {
      generationProvider.setGeneration(
        'test-project',
        ActiveGeneration(
          projectId: 'test-project',
          versionId: 'test-version',
          executionId: 'test-execution',
          workflowState: const WorkflowState(
            workflowId: 'test-execution',
            status: WorkflowStatus.running,
            progress: 0.3,
            currentStep: GenerationStep.analysis,
          ),
        ),
      );

      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(milliseconds: 100));

      // Should show step labels
      expect(find.text('Analyse'), findsWidgets);
      // Should show the background button
      expect(find.textContaining('arrière-plan'), findsOneWidget);
      // Should show cancel text
      expect(find.textContaining('Annuler'), findsOneWidget);
      // Should show percentage
      expect(find.text('30%'), findsOneWidget);
    });

    testWidgets('renders completed state', (tester) async {
      generationProvider.setGeneration(
        'test-project',
        ActiveGeneration(
          projectId: 'test-project',
          versionId: 'test-version',
          executionId: 'test-execution',
          workflowState: const WorkflowState(
            workflowId: 'test-execution',
            status: WorkflowStatus.completed,
            progress: 1.0,
            currentStep: GenerationStep.assembly,
          ),
        ),
      );

      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('prêt'), findsOneWidget);
      expect(find.text('Voir le résultat'), findsOneWidget);
    });

    testWidgets('renders error state', (tester) async {
      generationProvider.setGeneration(
        'test-project',
        ActiveGeneration(
          projectId: 'test-project',
          versionId: 'test-version',
          executionId: 'test-execution',
          workflowState: const WorkflowState(
            workflowId: 'test-execution',
            status: WorkflowStatus.failed,
            errorMessage: 'Something went wrong',
          ),
        ),
      );

      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Échec'), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
    });

    testWidgets('renders cancelled state', (tester) async {
      generationProvider.setGeneration(
        'test-project',
        ActiveGeneration(
          projectId: 'test-project',
          versionId: 'test-version',
          executionId: 'test-execution',
          isCancelled: true,
        ),
      );

      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Génération annulée'), findsOneWidget);
    });

    testWidgets('renders all 5 step indicator labels in generating state', (
      tester,
    ) async {
      generationProvider.setGeneration(
        'test-project',
        ActiveGeneration(
          projectId: 'test-project',
          versionId: 'test-version',
          executionId: 'test-execution',
          workflowState: const WorkflowState(
            workflowId: 'test-execution',
            status: WorkflowStatus.running,
            progress: 0.5,
            currentStep: GenerationStep.imageGeneration,
          ),
        ),
      );

      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(milliseconds: 100));

      // The step indicators show these labels
      expect(find.text('Analyse'), findsWidgets);
      expect(find.text('Réfs'), findsOneWidget);
      expect(find.text('Images'), findsWidgets);
      expect(find.text('Audio'), findsOneWidget);
      expect(find.text('Montage'), findsOneWidget);
    });

    testWidgets('renders progress bar in generating state', (tester) async {
      generationProvider.setGeneration(
        'test-project',
        ActiveGeneration(
          projectId: 'test-project',
          versionId: 'test-version',
          executionId: 'test-execution',
          workflowState: const WorkflowState(
            workflowId: 'test-execution',
            status: WorkflowStatus.running,
            progress: 0.45,
            currentStep: GenerationStep.imageGeneration,
          ),
        ),
      );

      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('45%'), findsOneWidget);
    });

    testWidgets('renders estimated time remaining when provided', (
      tester,
    ) async {
      generationProvider.setGeneration(
        'test-project',
        ActiveGeneration(
          projectId: 'test-project',
          versionId: 'test-version',
          executionId: 'test-execution',
          workflowState: const WorkflowState(
            workflowId: 'test-execution',
            status: WorkflowStatus.running,
            progress: 0.6,
            currentStep: GenerationStep.audioGeneration,
            estimatedTimeRemaining: Duration(minutes: 3),
          ),
        ),
      );

      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('min restante'), findsOneWidget);
    });

    testWidgets('does not show estimated time when null', (tester) async {
      generationProvider.setGeneration(
        'test-project',
        ActiveGeneration(
          projectId: 'test-project',
          versionId: 'test-version',
          executionId: 'test-execution',
          workflowState: const WorkflowState(
            workflowId: 'test-execution',
            status: WorkflowStatus.running,
            progress: 0.2,
            currentStep: GenerationStep.analysis,
          ),
        ),
      );

      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('restante'), findsNothing);
    });
  });
}
