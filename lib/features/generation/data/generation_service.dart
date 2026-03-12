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

  /// Lance la generation d'un projet et retourne le workflowId
  Future<GenerationResult<String>> startGeneration(String projectId) async {
    // Mode mock
    if (EnvironmentConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      _mockStartTime = DateTime.now();
      return GenerationResult(
        success: true,
        data: 'mock_workflow_${DateTime.now().millisecondsSinceEpoch}',
      );
    }

    try {
      final response = await _apiClient.generateProject(projectId);
      final workflowId = response.data['workflowId'] as String?;
      if (workflowId == null) {
        return GenerationResult(
          success: false,
          error: 'Aucun workflowId retourné par le serveur',
        );
      }
      return GenerationResult(success: true, data: workflowId);
    } on DioException catch (e) {
      return GenerationResult(success: false, error: _handleError(e));
    } catch (e) {
      return GenerationResult(success: false, error: 'Erreur inattendue: $e');
    }
  }

  /// Recupere le statut d'un workflow de generation
  Future<GenerationResult<WorkflowState>> getWorkflowStatus(
    String projectId,
    String workflowId,
  ) async {
    // Mode mock : simulation de progression realiste
    if (EnvironmentConfig.useMockData) {
      // Initialiser le timer mock au premier appel
      _mockStartTime ??= DateTime.now();
      await Future.delayed(const Duration(milliseconds: 200));
      final state = _simulateMockProgress(workflowId);
      return GenerationResult(success: true, data: state);
    }

    try {
      final response = await _apiClient.getWorkflowStatus(
        projectId,
        workflowId,
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

  /// Simule une progression realiste pour le mode mock
  /// Duree totale ~15 secondes :
  ///   - analysis   : 0s  -> 3s   (0% -> 20%)
  ///   - images     : 3s  -> 9s   (20% -> 60%)
  ///   - audio      : 9s  -> 12s  (60% -> 80%)
  ///   - assembly   : 12s -> 15s  (80% -> 100%)
  WorkflowState _simulateMockProgress(String workflowId) {
    final startTime = _mockStartTime ?? DateTime.now();
    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    final totalDuration = 15000; // 15 secondes

    // Generation terminee
    if (elapsed >= totalDuration) {
      return WorkflowState(
        workflowId: workflowId,
        status: WorkflowStatus.completed,
        progress: 1.0,
        currentStep: GenerationStep.assembly,
        videoUrl: 'https://example.com/mock-video.mp4',
        thumbnailUrl: 'https://picsum.photos/seed/mock/640/360',
      );
    }

    // Calcul de la progression et de l'etape courante
    final progress = elapsed / totalDuration;
    final GenerationStep step;
    final int remainingMs = totalDuration - elapsed;

    if (elapsed < 3000) {
      step = GenerationStep.analysis;
    } else if (elapsed < 9000) {
      step = GenerationStep.images;
    } else if (elapsed < 12000) {
      step = GenerationStep.audio;
    } else {
      step = GenerationStep.assembly;
    }

    return WorkflowState(
      workflowId: workflowId,
      status: WorkflowStatus.processing,
      progress: progress,
      currentStep: step,
      estimatedTimeRemaining: Duration(milliseconds: remainingMs),
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
