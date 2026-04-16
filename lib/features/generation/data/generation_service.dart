import 'package:dio/dio.dart';
import 'package:visiobook_mobile/config/environment.dart';
import 'package:visiobook_mobile/core/network/api_client.dart';
import 'package:visiobook_mobile/features/generation/domain/generation_state.dart';

/// Resultat d'operation sur la generation
class GenerationResult<T> {
  final bool success;
  final T? data;
  final String? error;

  GenerationResult({required this.success, this.data, this.error});
}

/// Donnees retournees apres le demarrage d'une generation
class StartGenerationData {
  final String versionId;
  final String executionId;

  StartGenerationData({required this.versionId, required this.executionId});
}

/// Service pour les operations de generation video
class GenerationService {
  final ApiClient _apiClient;

  /// Timestamp du debut de la generation mock (pour simuler la progression)
  DateTime? _mockStartTime;

  GenerationService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Remet le timer mock a zero pour permettre une nouvelle generation
  void resetMockTimer() {
    _mockStartTime = null;
  }

  /// Lance la generation d'un projet via la creation d'une version puis le
  /// demarrage du workflow
  Future<GenerationResult<StartGenerationData>> startGeneration(
    String projectId,
  ) async {
    // Mode mock
    if (EnvironmentConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      _mockStartTime = DateTime.now();
      final ts = DateTime.now().millisecondsSinceEpoch;
      return GenerationResult(
        success: true,
        data: StartGenerationData(
          versionId: 'mock_version_$ts',
          executionId: 'mock_execution_$ts',
        ),
      );
    }

    try {
      // Step 1: create a version
      final versionResponse = await _apiClient.createVersion(projectId);
      final versionId = versionResponse.data['id'] as String?;
      if (versionId == null) {
        return GenerationResult(
          success: false,
          error: 'Aucun versionId retourné par le serveur',
        );
      }

      // Step 2: start the workflow
      final workflowResponse = await _apiClient.startWorkflow(
        projectId,
        versionId,
      );
      final executionId = workflowResponse.data['executionId'] as String?;
      if (executionId == null) {
        return GenerationResult(
          success: false,
          error: 'Aucun executionId retourné par le serveur',
        );
      }

      return GenerationResult(
        success: true,
        data: StartGenerationData(
          versionId: versionId,
          executionId: executionId,
        ),
      );
    } on DioException catch (e) {
      return GenerationResult(success: false, error: _handleError(e));
    } catch (e) {
      return GenerationResult(success: false, error: 'Erreur inattendue: $e');
    }
  }

  /// Recupere le statut d'un workflow de generation
  Future<GenerationResult<WorkflowState>> getWorkflowStatus(
    String projectId,
    String versionId,
    String executionId,
  ) async {
    // Mode mock : simulation de progression realiste
    if (EnvironmentConfig.useMockData) {
      // Initialiser le timer mock au premier appel
      _mockStartTime ??= DateTime.now();
      await Future.delayed(const Duration(milliseconds: 200));
      final state = _simulateMockProgress(executionId);
      return GenerationResult(success: true, data: state);
    }

    try {
      final response = await _apiClient.getWorkflowStatus(
        projectId,
        versionId,
        executionId,
      );
      final state = WorkflowState.fromJson(
        response.data as Map<String, dynamic>,
      );
      return GenerationResult(success: true, data: state);
    } on DioException catch (e) {
      return GenerationResult(success: false, error: _handleError(e));
    } catch (e) {
      return GenerationResult(success: false, error: 'Erreur inattendue: $e');
    }
  }

  /// Definit les etapes du pipeline mock avec les memes poids que le backend.
  /// Duree totale ~20 secondes pour laisser le temps de voir chaque etape.
  static const _mockTotalDuration = 20000; // 20 secondes

  /// Simule une progression realiste pour le mode mock.
  /// Reproduit exactement le format SSE du core-project-service :
  /// - status: running | completed
  /// - currentStep: analysis | reference_generation | image_generation | ...
  /// - progress: 0-100 (normalisé en 0.0-1.0)
  /// - steps: liste detaillee avec status + progress par etape
  WorkflowState _simulateMockProgress(String workflowId) {
    final startTime = _mockStartTime ?? DateTime.now();
    final elapsed = DateTime.now().difference(startTime).inMilliseconds;

    // Bornes cumulees de chaque etape (en ms)
    // analysis:              0 ->  3000  (15%)
    // reference_generation:  3000 ->  5000  (10%)
    // image_generation:      5000 -> 12000  (35%)
    // audio_generation:      12000 -> 15600  (18%)
    // assembly:              15600 -> 20000  (22%)
    const stepBounds = [
      (GenerationStep.analysis, 0, 3000),
      (GenerationStep.referenceGeneration, 3000, 5000),
      (GenerationStep.imageGeneration, 5000, 12000),
      (GenerationStep.audioGeneration, 12000, 15600),
      (GenerationStep.assembly, 15600, 20000),
    ];

    // Generation terminee
    if (elapsed >= _mockTotalDuration) {
      return WorkflowState(
        workflowId: workflowId,
        status: WorkflowStatus.completed,
        progress: 1.0,
        currentStep: GenerationStep.assembly,
        videoUrl: 'https://example.com/mock-video.mp4',
        thumbnailUrl: 'https://picsum.photos/seed/mock/640/360',
        steps: stepBounds
            .map(
              (b) => StepDetail(step: b.$1, status: 'completed', progress: 100),
            )
            .toList(),
      );
    }

    // Progression globale 0.0-1.0
    final progress = elapsed / _mockTotalDuration;
    final remainingMs = _mockTotalDuration - elapsed;

    // Determiner l'etape courante et construire la liste steps
    GenerationStep currentStep = GenerationStep.analysis;
    final steps = <StepDetail>[];

    for (final (step, startMs, endMs) in stepBounds) {
      if (elapsed >= endMs) {
        // Etape terminee
        steps.add(StepDetail(step: step, status: 'completed', progress: 100));
      } else if (elapsed >= startMs) {
        // Etape en cours
        currentStep = step;
        final stepProgress = ((elapsed - startMs) / (endMs - startMs) * 100)
            .round();
        steps.add(
          StepDetail(step: step, status: 'running', progress: stepProgress),
        );
      } else {
        // Etape pas encore commencee
        steps.add(StepDetail(step: step, status: 'pending', progress: 0));
      }
    }

    return WorkflowState(
      workflowId: workflowId,
      status: WorkflowStatus.running,
      progress: progress,
      currentStep: currentStep,
      estimatedTimeRemaining: Duration(milliseconds: remainingMs),
      steps: steps,
    );
  }

  /// Gestion des erreurs Dio
  String _handleError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;

      String message = 'Erreur serveur';
      if (data is Map && data['message'] != null) {
        message = data['message'] as String;
      }

      switch (statusCode) {
        case 404:
          return 'Projet ou workflow non trouvé';
        case 403:
          return 'Accès refusé';
        case 409:
          return 'Une génération est déjà en cours';
        default:
          return message;
      }
    }

    if (e.type == DioExceptionType.connectionError) {
      return 'Pas de connexion internet';
    }

    return 'Erreur réseau';
  }
}
