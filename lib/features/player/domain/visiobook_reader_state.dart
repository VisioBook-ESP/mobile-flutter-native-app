/// Represents a single scene in the VisioBook
class VisioBookScene {
  final String id;
  final int order; // 0-based order
  final String imageUrl; // main visual
  final String? videoUrl; // optional short video (replaces image)
  final String? audioUrl; // narration audio for this scene
  final String? subtitleText; // text displayed as subtitle
  final Duration? audioDuration; // estimated audio duration

  const VisioBookScene({
    required this.id,
    required this.order,
    required this.imageUrl,
    this.videoUrl,
    this.audioUrl,
    this.subtitleText,
    this.audioDuration,
  });

  factory VisioBookScene.fromJson(Map<String, dynamic> json) {
    return VisioBookScene(
      id: json['id'] as String,
      order: json['order'] as int,
      imageUrl: json['imageUrl'] as String,
      videoUrl: json['videoUrl'] as String?,
      audioUrl: json['audioUrl'] as String?,
      subtitleText: json['subtitleText'] as String?,
      audioDuration: json['audioDurationMs'] != null
          ? Duration(milliseconds: json['audioDurationMs'] as int)
          : null,
    );
  }
}

/// Full VisioBook data (all scenes for a project)
class VisioBookData {
  final String projectId;
  final String title;
  final List<VisioBookScene> scenes;
  final DateTime createdAt;

  const VisioBookData({
    required this.projectId,
    required this.title,
    required this.scenes,
    required this.createdAt,
  });

  int get sceneCount => scenes.length;

  factory VisioBookData.fromJson(Map<String, dynamic> json) {
    return VisioBookData(
      projectId: json['projectId'] as String,
      title: json['title'] as String,
      scenes:
          (json['scenes'] as List)
              .map((s) => VisioBookScene.fromJson(s as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => a.order.compareTo(b.order)),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
