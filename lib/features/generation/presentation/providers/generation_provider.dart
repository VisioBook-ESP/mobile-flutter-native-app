import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:visiobook_mobile/features/generation/data/generation_service.dart';
import 'package:visiobook_mobile/features/generation/domain/generation_state.dart';

/// Provider pour gerer l'etat de la generation video et le polling
class GenerationProvider extends ChangeNotifier {
  final GenerationService _generationService;

  WorkflowState? _workflowState;
  bool _isCancelled = false;
  Timer? _pollingTimer;
  String? _projectId;
  String? _versionId;
  String? _executionId;
  String? _error;

  GenerationProvider({required GenerationService generationService})
    : _generationService = generationService;

  // Getters
  WorkflowState? get workflowState => _workflowState;
  bool get isCancelled => _isCancelled;
  String? get projectId => _projectId;
  String? get versionId => _versionId;
  String? get executionId => _executionId;
  String? get error => _error;

  /// Progression de 0.0 a 1.0
  double get progress => _workflowState?.progress ?? 0.0;

  /// Etape courante de la generation
  GenerationStep get currentStep =>
      _workflowState?.currentStep ?? GenerationStep.analysis;

  /// Statut du workflow
  WorkflowStatus get status => _workflowState?.status ?? WorkflowStatus.pending;

  /// Vrai si la generation est terminee (succes ou echec)
  bool get isFinished => _workflowState?.isFinished ?? false;

  /// Vrai si la generation est en cours
  bool get isInProgress => _workflowState?.isInProgress ?? false;

  /// Vrai si la generation a reussi
  bool get isCompleted => _workflowState?.status == WorkflowStatus.completed;

  /// Vrai si la generation a echoue
  bool get isFailed => _workflowState?.status == WorkflowStatus.failed;

  /// URL de la video generee (disponible apres completion)
  String? get videoUrl => _workflowState?.videoUrl;

  /// URL de la miniature (disponible apres completion)
  String? get thumbnailUrl => _workflowState?.thumbnailUrl;

  /// Temps restant estime
  Duration? get estimatedTimeRemaining =>
      _workflowState?.estimatedTimeRemaining;

  /// Label de l'etape courante (ex: "Analyse")
  String get currentStepLabel => currentStep.label;

  /// Description de l'etape courante (ex: "Analyse du document en cours...")
  String get currentStepDescription => currentStep.description;

  /// Demarre la generation et lance le polling
  Future<bool> startGeneration(
    String projectId, {
    Map<String, dynamic>? config,
  }) async {
    _error = null;
    _isCancelled = false;
    _projectId = projectId;
    notifyListeners();

    final result = await _generationService.startGeneration(
      projectId,
      config: config,
    );

    if (!result.success || result.data == null) {
      _error = result.error ?? 'Impossible de lancer la generation';
      notifyListeners();
      return false;
    }

    _versionId = result.data!.versionId;
    _executionId = result.data!.executionId;
    _workflowState = WorkflowState(
      workflowId: _executionId!,
      status: WorkflowStatus.pending,
    );
    notifyListeners();

    // Demarrer le polling du statut
    startPolling(projectId, _versionId!, _executionId!);
    return true;
  }

  /// Demarre le polling du statut toutes les 2 secondes
  void startPolling(String projectId, String versionId, String executionId) {
    _projectId = projectId;
    _versionId = versionId;
    _executionId = executionId;
    _isCancelled = false;

    // Remettre a zero le timer mock pour que la progression reparte de 0
    _generationService.resetMockTimer();

    // Annuler un eventuel polling en cours
    _pollingTimer?.cancel();

    // Premier poll immediat
    _pollStatus();

    // Puis poll toutes les 2 secondes
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _pollStatus(),
    );
  }

  /// Interroge l'API pour obtenir le statut du workflow
  Future<void> _pollStatus() async {
    if (_isCancelled ||
        _projectId == null ||
        _versionId == null ||
        _executionId == null) {
      _pollingTimer?.cancel();
      return;
    }

    final result = await _generationService.getWorkflowStatus(
      _projectId!,
      _versionId!,
      _executionId!,
    );

    // Si annule entre temps, ignorer le resultat
    if (_isCancelled) return;

    if (result.success && result.data != null) {
      _workflowState = result.data;
      _error = result.data!.errorMessage;
      notifyListeners();

      // Arreter le polling si termine
      if (result.data!.isFinished) {
        _pollingTimer?.cancel();
      }
    } else {
      _error = result.error;
      notifyListeners();
    }
  }

  /// Annule la generation en cours
  void cancelGeneration() {
    _isCancelled = true;
    _pollingTimer?.cancel();
    notifyListeners();
  }

  /// Remet le provider a son etat initial
  void reset() {
    _pollingTimer?.cancel();
    _workflowState = null;
    _isCancelled = false;
    _pollingTimer = null;
    _projectId = null;
    _versionId = null;
    _executionId = null;
    _error = null;
    notifyListeners();
  }

  /// Clear l'erreur
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
