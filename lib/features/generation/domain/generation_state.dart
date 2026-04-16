/// Etapes de generation video
enum GenerationStep {
  /// Analyse du document (15%)
  analysis,

  /// Generation des references visuelles (10%)
  referenceGeneration,

  /// Generation des images (35%)
  imageGeneration,

  /// Generation de l'audio (18%)
  audioGeneration,

  /// Assemblage final (22%)
  assembly;

  /// Label affiche a l'utilisateur
  String get label {
    switch (this) {
      case GenerationStep.analysis:
        return 'Analyse';
      case GenerationStep.referenceGeneration:
        return 'Références';
      case GenerationStep.imageGeneration:
        return 'Images';
      case GenerationStep.audioGeneration:
        return 'Audio';
      case GenerationStep.assembly:
        return 'Assemblage';
    }
  }

  /// Description detaillee de l'etape
  String get description {
    switch (this) {
      case GenerationStep.analysis:
        return 'Analyse du document en cours...';
      case GenerationStep.referenceGeneration:
        return 'Génération des références visuelles...';
      case GenerationStep.imageGeneration:
        return 'Génération des illustrations...';
      case GenerationStep.audioGeneration:
        return 'Création de la narration audio...';
      case GenerationStep.assembly:
        return 'Assemblage de la vidéo finale...';
    }
  }

  /// Poids de l'etape dans la progression globale (total = 100%)
  double get weight {
    switch (this) {
      case GenerationStep.analysis:
        return 0.15;
      case GenerationStep.referenceGeneration:
        return 0.10;
      case GenerationStep.imageGeneration:
        return 0.35;
      case GenerationStep.audioGeneration:
        return 0.18;
      case GenerationStep.assembly:
        return 0.22;
    }
  }

  /// Cree un GenerationStep a partir d'une chaine (API)
  static GenerationStep fromString(String value) {
    switch (value.toLowerCase()) {
      case 'analysis':
        return GenerationStep.analysis;
      case 'reference_generation':
        return GenerationStep.referenceGeneration;
      case 'image_generation':
      case 'images': // backward compat
        return GenerationStep.imageGeneration;
      case 'audio_generation':
      case 'audio': // backward compat
        return GenerationStep.audioGeneration;
      case 'assembly':
        return GenerationStep.assembly;
      default:
        return GenerationStep.analysis;
    }
  }
}

/// Statut du workflow de generation
enum WorkflowStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
  running;

  /// Cree un WorkflowStatus a partir d'une chaine (API)
  static WorkflowStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return WorkflowStatus.pending;
      case 'processing':
        return WorkflowStatus.processing;
      case 'running':
        return WorkflowStatus.running;
      case 'completed':
        return WorkflowStatus.completed;
      case 'failed':
        return WorkflowStatus.failed;
      case 'cancelled':
        return WorkflowStatus.cancelled;
      default:
        return WorkflowStatus.pending;
    }
  }
}

/// Detail d'une etape individuelle retournee par le SSE
class StepDetail {
  final GenerationStep step;
  final String status; // "pending", "running", "completed", "failed"
  final int progress; // 0-100

  const StepDetail({
    required this.step,
    required this.status,
    this.progress = 0,
  });

  /// Parse un element de la liste steps du SSE
  factory StepDetail.fromJson(Map<String, dynamic> json) {
    return StepDetail(
      step: GenerationStep.fromString(json['step'] as String? ?? 'analysis'),
      status: json['status'] as String? ?? 'pending',
      progress: (json['progress'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Etat du workflow retourne par l'API
class WorkflowState {
  final String workflowId;
  final WorkflowStatus status;
  final double progress;
  final GenerationStep currentStep;
  final String? errorMessage;
  final String? videoUrl;
  final String? thumbnailUrl;
  final Duration? estimatedTimeRemaining;
  final List<StepDetail> steps;

  const WorkflowState({
    required this.workflowId,
    required this.status,
    this.progress = 0.0,
    this.currentStep = GenerationStep.analysis,
    this.errorMessage,
    this.videoUrl,
    this.thumbnailUrl,
    this.estimatedTimeRemaining,
    this.steps = const [],
  });

  /// Parse la reponse JSON de l'API
  factory WorkflowState.fromJson(Map<String, dynamic> json) {
    // Handle progress: SSE sends 0-100 (int), existing format uses 0.0-1.0
    final rawProgress = (json['progress'] as num?)?.toDouble() ?? 0.0;
    final normalizedProgress = rawProgress > 1
        ? rawProgress / 100.0
        : rawProgress;

    // Parse steps list from SSE if present
    final stepsList = <StepDetail>[];
    if (json['steps'] != null && json['steps'] is List) {
      for (final stepJson in json['steps'] as List) {
        if (stepJson is Map<String, dynamic>) {
          stepsList.add(StepDetail.fromJson(stepJson));
        }
      }
    }

    // Support both 'workflowId' and 'executionId' keys
    final id =
        json['workflowId'] as String? ?? json['executionId'] as String? ?? '';

    return WorkflowState(
      workflowId: id,
      status: WorkflowStatus.fromString(json['status'] as String? ?? 'pending'),
      progress: normalizedProgress,
      currentStep: GenerationStep.fromString(
        json['currentStep'] as String? ?? 'analysis',
      ),
      errorMessage: json['errorMessage'] as String?,
      videoUrl: json['videoUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      estimatedTimeRemaining: json['estimatedTimeRemaining'] != null
          ? Duration(seconds: json['estimatedTimeRemaining'] as int)
          : null,
      steps: stepsList,
    );
  }

  /// Indique si la generation est terminee (succes ou echec)
  bool get isFinished =>
      status == WorkflowStatus.completed ||
      status == WorkflowStatus.failed ||
      status == WorkflowStatus.cancelled;

  /// Indique si la generation est en cours
  bool get isInProgress =>
      status == WorkflowStatus.pending ||
      status == WorkflowStatus.processing ||
      status == WorkflowStatus.running;
}
