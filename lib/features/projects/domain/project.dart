/// Statut d'un projet
enum ProjectStatus {
  draft,
  processing,
  ready,
  error;

  String get label {
    switch (this) {
      case ProjectStatus.draft:
        return 'Brouillon';
      case ProjectStatus.processing:
        return 'En cours...';
      case ProjectStatus.ready:
        return 'Pret';
      case ProjectStatus.error:
        return 'Erreur';
    }
  }

  static ProjectStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'draft':
        return ProjectStatus.draft;
      case 'processing':
        return ProjectStatus.processing;
      case 'ready':
        return ProjectStatus.ready;
      case 'error':
        return ProjectStatus.error;
      default:
        return ProjectStatus.draft;
    }
  }
}

/// Model d'un projet VisioBook
class Project {
  final String id;
  final String title;
  final String? description;
  final ProjectStatus status;
  final String? coverUrl;
  final String? videoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Project({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    this.coverUrl,
    this.videoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Sans titre',
      description: json['description'] as String?,
      status: ProjectStatus.fromString(json['status'] as String? ?? 'draft'),
      coverUrl: json['coverUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      createdAt: DateTime.parse(
        json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.name,
      'coverUrl': coverUrl,
      'videoUrl': videoUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
