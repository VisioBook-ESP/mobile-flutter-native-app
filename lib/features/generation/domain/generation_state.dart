/// Etapes de generation video
enum GenerationStep {
  /// Analyse du document (0-20%)
  analysis,

  /// Generation des images (20-60%)
  images,

  /// Generation de l'audio (60-80%)
  audio,

  /// Assemblage final (80-100%)
  assembly;

  /// Label affiche a l'utilisateur
  String get label {
    switch (this) {
      case GenerationStep.analysis:
        return 'Analyse';
      case GenerationStep.images:
        return 'Images';
      case GenerationStep.audio:
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
      case GenerationStep.images:
        return 'Generation des illustrations...';
      case GenerationStep.audio:
        return 'Creation de la narration audio...';
      case GenerationStep.assembly:
        return 'Assemblage de la video finale...';
    }
  }

  /// Cree un GenerationStep a partir d'une chaine (API)
  static GenerationStep fromString(String value) {
    switch (value.toLowerCase()) {
      case 'analysis':
        return GenerationStep.analysis;
      case 'images':
        return GenerationStep.images;
      case 'audio':
        return GenerationStep.audio;
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
  failed;

  /// Cree un WorkflowStatus a partir d'une chaine (API)
  static WorkflowStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return WorkflowStatus.pending;
      case 'processing':
        return WorkflowStatus.processing;
      case 'completed':
        return WorkflowStatus.completed;
      case 'failed':
        return WorkflowStatus.failed;
      default:
        return WorkflowStatus.pending;
    }
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

  const WorkflowState({
    required this.workflowId,
    required this.status,
    this.progress = 0.0,
    this.currentStep = GenerationStep.analysis,
    this.errorMessage,
    this.videoUrl,
    this.thumbnailUrl,
    this.estimatedTimeRemaining,
  });

  /// Parse la reponse JSON de l'API
  factory WorkflowState.fromJson(Map<String, dynamic> json) {
    return WorkflowState(
      workflowId: json['workflowId'] as String? ?? '',
      status: WorkflowStatus.fromString(json['status'] as String? ?? 'pending'),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      currentStep: GenerationStep.fromString(
        json['currentStep'] as String? ?? 'analysis',
      ),
      errorMessage: json['errorMessage'] as String?,
      videoUrl: json['videoUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      estimatedTimeRemaining: json['estimatedTimeRemaining'] != null
          ? Duration(seconds: json['estimatedTimeRemaining'] as int)
          : null,
    );
  }

  /// Indique si la generation est terminee (succes ou echec)
  bool get isFinished =>
      status == WorkflowStatus.completed || status == WorkflowStatus.failed;

  /// Indique si la generation est en cours
  bool get isInProgress =>
      status == WorkflowStatus.pending || status == WorkflowStatus.processing;
}
