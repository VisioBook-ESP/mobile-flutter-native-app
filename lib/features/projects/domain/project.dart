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

/// Model d'une generation de video
class Generation {
  final String id;
  final String? thumbnailUrl;
  final String? videoUrl;
  final DateTime createdAt;

  Generation({
    required this.id,
    this.thumbnailUrl,
    this.videoUrl,
    required this.createdAt,
  });

  factory Generation.fromJson(Map<String, dynamic> json) {
    return Generation(
      id: json['id'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      createdAt: DateTime.parse(
        json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

/// Model d'un projet VisioBook
class Project {
  final String id;
  final String title;
  final String? description;
  final String? author;
  final String? genre;
  final ProjectStatus status;
  final String? coverUrl;
  final String? videoUrl;
  final int? videoDurationSeconds;
  final String? style;
  final String? fileId;
  final String? language;
  final String? duration;
  final List<Generation> generations;
  final DateTime createdAt;
  final DateTime updatedAt;

  Project({
    required this.id,
    required this.title,
    this.description,
    this.author,
    this.genre,
    required this.status,
    this.coverUrl,
    this.videoUrl,
    this.videoDurationSeconds,
    this.style,
    this.fileId,
    this.language,
    this.duration,
    this.generations = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Formate la duree en mm:ss
  String get formattedDuration {
    if (videoDurationSeconds == null) return '--:--';
    final minutes = videoDurationSeconds! ~/ 60;
    final seconds = videoDurationSeconds! % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Sans titre',
      description: json['description'] as String?,
      author: json['author'] as String?,
      genre: json['genre'] as String?,
      status: ProjectStatus.fromString(json['status'] as String? ?? 'draft'),
      coverUrl: json['coverUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      videoDurationSeconds: json['videoDurationSeconds'] as int?,
      style: json['style'] as String?,
      fileId: json['fileId'] as String?,
      language: json['language'] as String?,
      duration: json['duration'] as String?,
      generations:
          (json['generations'] as List<dynamic>?)
              ?.map((g) => Generation.fromJson(g as Map<String, dynamic>))
              .toList() ??
          [],
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
      'author': author,
      'genre': genre,
      'status': status.name,
      'coverUrl': coverUrl,
      'videoUrl': videoUrl,
      'videoDurationSeconds': videoDurationSeconds,
      'style': style,
      'fileId': fileId,
      'language': language,
      'duration': duration,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
