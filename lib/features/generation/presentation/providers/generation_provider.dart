import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:visiobook_mobile/features/generation/data/generation_service.dart';
import 'package:visiobook_mobile/features/generation/domain/generation_state.dart';

/// Donnees d'une generation active
class ActiveGeneration {
  final String projectId;
  String versionId;
  String executionId;
  WorkflowState? workflowState;
  Timer? pollingTimer;
  bool isCancelled;
  String? error;

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

  /// Map des generations actives par projectId
  final Map<String, ActiveGeneration> _activeGenerations = {};

  /// Callback appele quand une generation se termine
  GenerationCallback? onGenerationFinished;

  GenerationProvider({required GenerationService generationService})
    : _generationService = generationService;

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

    _startPollingForProject(projectId);
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
    _activeGenerations[projectId] = generation;

    _generationService.resetMockTimer();
    _startPollingForProject(projectId);
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
    notifyListeners();
  }

  /// Supprime une generation terminee ou annulee du tracking
  void clearGeneration(String projectId) {
    final generation = _activeGenerations.remove(projectId);
    generation?.pollingTimer?.cancel();
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

  void _stopGeneration(String projectId) {
    final generation = _activeGenerations.remove(projectId);
    generation?.pollingTimer?.cancel();
  }

  @override
  void dispose() {
    for (final generation in _activeGenerations.values) {
      generation.pollingTimer?.cancel();
    }
    _activeGenerations.clear();
    super.dispose();
  }
}
