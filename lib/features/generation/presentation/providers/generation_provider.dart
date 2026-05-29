import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:visiobook_mobile/config/environment.dart';
import 'package:visiobook_mobile/core/services/sse_service.dart';
import 'package:visiobook_mobile/features/generation/data/generation_service.dart';
import 'package:visiobook_mobile/features/generation/data/ingestion_polling_service.dart';
import 'package:visiobook_mobile/features/generation/domain/generation_state.dart';
import 'package:visiobook_mobile/features/generation/domain/ingestion_state.dart';

/// Donnees d'une generation active
class ActiveGeneration {
  final String projectId;
  String versionId;
  String executionId;
  WorkflowState? workflowState;
  Timer? pollingTimer;
  bool isCancelled;
  String? error;

  StreamSubscription? sseSubscription;

  ActiveGeneration({
    required this.projectId,
    required this.versionId,
    required this.executionId,
    this.workflowState,
    this.pollingTimer,
    this.isCancelled = false,
    this.error,
  });
}

/// Callback type pour les notifications de fin de generation
typedef GenerationCallback =
    void Function(String projectId, bool success, String? error);

/// Provider pour gerer l'etat de la generation video et le polling.
/// Supporte plusieurs generations en parallele et continue en arriere-plan.
class GenerationProvider extends ChangeNotifier {
  final GenerationService _generationService;
  final SseService? _sseService;
  final IngestionPollingService? _ingestionPollingService;

  /// Map des generations actives par projectId
  final Map<String, ActiveGeneration> _activeGenerations = {};

  /// Callback appele quand une generation se termine
  GenerationCallback? onGenerationFinished;

  /// Ingestion tracking
  final Map<String, IngestionState> _ingestionStates = {};
  final Map<String, StreamSubscription> _ingestionSubscriptions = {};

  GenerationProvider({
    required GenerationService generationService,
    SseService? sseService,
    IngestionPollingService? ingestionPollingService,
  }) : _generationService = generationService,
       _sseService = sseService,
       _ingestionPollingService = ingestionPollingService;

  /// Liste des generations actives
  Map<String, ActiveGeneration> get activeGenerations =>
      Map.unmodifiable(_activeGenerations);

  /// Verifie si un projet a une generation active
  bool hasActiveGeneration(String projectId) =>
      _activeGenerations.containsKey(projectId);

  /// Recupere l'etat d'une generation pour un projet
  ActiveGeneration? getGeneration(String projectId) =>
      _activeGenerations[projectId];

  /// Progression d'un projet (0.0 a 1.0), 0 si pas de generation
  double getProgress(String projectId) =>
      _activeGenerations[projectId]?.workflowState?.progress ?? 0.0;

  /// Etape courante d'un projet
  GenerationStep getStep(String projectId) =>
      _activeGenerations[projectId]?.workflowState?.currentStep ??
      GenerationStep.analysis;

  /// Statut d'un projet
  WorkflowStatus getStatus(String projectId) =>
      _activeGenerations[projectId]?.workflowState?.status ??
      WorkflowStatus.pending;

  /// Vrai si une generation specifique est terminee
  bool isFinished(String projectId) =>
      _activeGenerations[projectId]?.workflowState?.isFinished ?? false;

  /// Vrai si une generation specifique est en cours
  bool isInProgress(String projectId) =>
      _activeGenerations[projectId]?.workflowState?.isInProgress ?? false;

  /// Vrai si une generation a echoue (status failed/cancelled ou erreur)
  bool isFailed(String projectId) {
    final gen = _activeGenerations[projectId];
    if (gen == null) return false;
    if (gen.error != null) return true;
    if (gen.isCancelled) return true;
    final status = gen.workflowState?.status;
    return status == WorkflowStatus.failed ||
        status == WorkflowStatus.cancelled;
  }

  /// URL de la video generee
  String? getVideoUrl(String projectId) =>
      _activeGenerations[projectId]?.workflowState?.videoUrl;

  /// URL de la miniature
  String? getThumbnailUrl(String projectId) =>
      _activeGenerations[projectId]?.workflowState?.thumbnailUrl;

  /// Temps restant estime
  Duration? getEstimatedTimeRemaining(String projectId) =>
      _activeGenerations[projectId]?.workflowState?.estimatedTimeRemaining;

  /// Label de l'etape courante
  String getStepLabel(String projectId) => getStep(projectId).label;

  /// Description de l'etape courante
  String getStepDescription(String projectId) => getStep(projectId).description;

  /// Erreur d'un projet
  String? getError(String projectId) =>
      _activeGenerations[projectId]?.error ??
      _activeGenerations[projectId]?.workflowState?.errorMessage;

  /// Demarre des mock generations pour des projets en processing.
  /// A appeler depuis le dashboard en mode mock.
  void startMockGenerations(List<String> projectIds) {
    for (final projectId in projectIds) {
      if (_activeGenerations.containsKey(projectId)) continue;
      final ts = DateTime.now().millisecondsSinceEpoch;
      startPolling(projectId, 'mock_version_$ts', 'mock_execution_$ts');
    }
  }

  /// Demarre la generation et lance le polling
  Future<bool> startGeneration(String projectId) async {
    // Annuler une eventuelle generation precedente pour ce projet
    _stopGeneration(projectId);

    final generation = ActiveGeneration(
      projectId: projectId,
      versionId: '',
      executionId: '',
    );
    _activeGenerations[projectId] = generation;
    notifyListeners();

    final result = await _generationService.startGeneration(projectId);

    if (!result.success || result.data == null) {
      generation.error = result.error ?? 'Impossible de lancer la generation';
      notifyListeners();
      return false;
    }

    generation.versionId = result.data!.versionId;
    generation.executionId = result.data!.executionId;
    generation.workflowState = WorkflowState(
      workflowId: generation.executionId,
      status: WorkflowStatus.pending,
    );
    notifyListeners();

    _startTrackingForProject(projectId);
    return true;
  }

  /// Demarre le polling du statut pour une generation deja lancee
  void startPolling(String projectId, String versionId, String executionId) {
    final existing = _activeGenerations[projectId];
    if (existing != null && existing.workflowState?.isFinished == true) {
      // Generation deja terminee, pas besoin de re-polluer
      return;
    }

    final generation = ActiveGeneration(
      projectId: projectId,
      versionId: versionId,
      executionId: executionId,
    );
    // Initialiser le workflowState pour que isInProgress soit vrai tout de suite
    generation.workflowState = WorkflowState(
      workflowId: executionId,
      status: WorkflowStatus.pending,
    );
    _activeGenerations[projectId] = generation;

    _generationService.resetMockTimer();
    _startTrackingForProject(projectId);
  }

  /// Demarre le tracking SSE (si disponible) ou polling pour un projet
  void _startTrackingForProject(String projectId) {
    final generation = _activeGenerations[projectId];
    if (generation == null) return;

    // Skip SSE in mock mode — go straight to polling
    if (EnvironmentConfig.useMockData) {
      _startPollingForProject(projectId);
      return;
    }

    // Try SSE first
    if (_sseService != null) {
      _startSseForProject(projectId);
    } else {
      _startPollingForProject(projectId);
    }
  }

  void _startSseForProject(String projectId) {
    final generation = _activeGenerations[projectId];
    if (generation == null || _sseService == null) return;

    generation.sseSubscription?.cancel();

    final stream = _sseService.connectToWorkflowProgress(
      projectId: projectId,
      versionId: generation.versionId,
    );

    generation.sseSubscription = stream.listen(
      (event) {
        if (generation.isCancelled) {
          generation.sseSubscription?.cancel();
          return;
        }

        // Convert SSE event to WorkflowState
        generation.workflowState = WorkflowState(
          workflowId: event.executionId,
          status: WorkflowStatus.fromString(event.status),
          progress: event.progress / 100.0,
          currentStep: GenerationStep.fromString(
            event.currentStep ?? 'analysis',
          ),
          steps: event.steps
              .map(
                (s) => StepDetail(
                  step: GenerationStep.fromString(s.step),
                  status: s.status,
                  progress: s.progress,
                ),
              )
              .toList(),
        );
        notifyListeners();

        // Check if finished
        if (event.isTerminal) {
          generation.sseSubscription?.cancel();
          final success = event.status == 'completed';
          onGenerationFinished?.call(
            projectId,
            success,
            generation.workflowState?.errorMessage,
          );
        }
      },
      onError: (error) {
        // Fall back to polling on SSE error
        _startPollingForProject(projectId);
      },
    );
  }

  void _startPollingForProject(String projectId) {
    final generation = _activeGenerations[projectId];
    if (generation == null) return;

    generation.pollingTimer?.cancel();

    // Premier poll immediat
    _pollStatus(projectId);

    // Puis poll toutes les 2 secondes
    generation.pollingTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _pollStatus(projectId),
    );
  }

  Future<void> _pollStatus(String projectId) async {
    final generation = _activeGenerations[projectId];
    if (generation == null || generation.isCancelled) {
      generation?.pollingTimer?.cancel();
      return;
    }

    final result = await _generationService.getWorkflowStatus(
      generation.projectId,
      generation.versionId,
      generation.executionId,
    );

    // Verifier que la generation n'a pas ete annulee entre temps
    if (generation.isCancelled) return;

    if (result.success && result.data != null) {
      generation.workflowState = result.data;
      generation.error = result.data!.errorMessage;
      notifyListeners();

      if (result.data!.isFinished) {
        generation.pollingTimer?.cancel();
        final success = result.data!.status == WorkflowStatus.completed;
        onGenerationFinished?.call(
          projectId,
          success,
          result.data!.errorMessage,
        );
      }
    } else {
      generation.error = result.error;
      notifyListeners();
    }
  }

  /// Annule la generation en cours pour un projet
  void cancelGeneration(String projectId) {
    final generation = _activeGenerations[projectId];
    if (generation == null) return;

    generation.isCancelled = true;
    generation.pollingTimer?.cancel();
    generation.sseSubscription?.cancel();
    notifyListeners();
  }

  /// Supprime une generation terminee ou annulee du tracking
  void clearGeneration(String projectId) {
    final generation = _activeGenerations.remove(projectId);
    generation?.pollingTimer?.cancel();
    generation?.sseSubscription?.cancel();
    notifyListeners();
  }

  /// Clear l'erreur d'un projet
  void clearError(String projectId) {
    final generation = _activeGenerations[projectId];
    if (generation != null) {
      generation.error = null;
      notifyListeners();
    }
  }

  // -------------------------------------------------------------------------
  // Ingestion tracking
  // -------------------------------------------------------------------------

  /// Start tracking ingestion status for a project
  void startIngestionTracking(String projectId, String jobId) {
    if (_ingestionPollingService == null) return;

    _ingestionSubscriptions[projectId]?.cancel();
    final stream = _ingestionPollingService.pollIngestionStatus(jobId);
    _ingestionSubscriptions[projectId] = stream.listen((state) {
      _ingestionStates[projectId] = state;
      notifyListeners();
      if (state.isFinished) {
        _ingestionSubscriptions[projectId]?.cancel();
      }
    });
  }

  /// Get the current ingestion state for a project
  IngestionState? getIngestionState(String projectId) =>
      _ingestionStates[projectId];

  /// Clear ingestion state and stop tracking for a project
  void clearIngestionState(String projectId) {
    _ingestionSubscriptions[projectId]?.cancel();
    _ingestionSubscriptions.remove(projectId);
    _ingestionStates.remove(projectId);
    notifyListeners();
  }

  void _stopGeneration(String projectId) {
    final generation = _activeGenerations.remove(projectId);
    generation?.pollingTimer?.cancel();
    generation?.sseSubscription?.cancel();
  }

  @override
  void dispose() {
    for (final generation in _activeGenerations.values) {
      generation.pollingTimer?.cancel();
      generation.sseSubscription?.cancel();
    }
    _activeGenerations.clear();
    for (final sub in _ingestionSubscriptions.values) {
      sub.cancel();
    }
    _ingestionSubscriptions.clear();
    _ingestionStates.clear();
    super.dispose();
  }
}
