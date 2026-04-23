/// Une vignette du VisioBook
class VisiobookPanel {
  final String id;
  final int order;
  final String videoUrl;
  final String thumbnailUrl;
  final String? dialogueText;
  final String? narratorText;
  final int videoDurationMs;

  const VisiobookPanel({
    required this.id,
    required this.order,
    required this.videoUrl,
    required this.thumbnailUrl,
    this.dialogueText,
    this.narratorText,
    required this.videoDurationMs,
  });

  factory VisiobookPanel.fromJson(Map<String, dynamic> json) {
    return VisiobookPanel(
      id: json['id'] as String? ?? '',
      order: (json['order'] as num?)?.toInt() ?? 0,
      videoUrl:
          json['videoUrl'] as String? ?? json['video_url'] as String? ?? '',
      thumbnailUrl:
          json['thumbnailUrl'] as String? ??
          json['thumbnail_url'] as String? ??
          '',
      dialogueText:
          json['dialogueText'] as String? ?? json['dialogue_text'] as String?,
      narratorText:
          json['narratorText'] as String? ?? json['narrator_text'] as String?,
      videoDurationMs:
          (json['videoDurationMs'] as num?)?.toInt() ??
          (json['video_duration_ms'] as num?)?.toInt() ??
          0,
    );
  }

  /// Crée un panel depuis une scène du backend (core-project-service).
  /// Format scène: { id, order, text, description, generatedImageUrl,
  ///   duration, narrationText, dialogues: [{ speaker, line }] }
  factory VisiobookPanel.fromScene(Map<String, dynamic> scene) {
    // Construire le texte des dialogues
    final dialogues = scene['dialogues'] as List?;
    String? dialogueText;
    if (dialogues != null && dialogues.isNotEmpty) {
      dialogueText = dialogues
          .map((d) {
            final speaker = d['speaker'] as String? ?? '';
            final line = d['line'] as String? ?? '';
            return speaker.isNotEmpty ? '$speaker : $line' : line;
          })
          .join('\n');
    }

    final durationSec = (scene['duration'] as num?)?.toDouble() ?? 5.0;

    return VisiobookPanel(
      id: scene['id'] as String? ?? '',
      order: (scene['order'] as num?)?.toInt() ?? 0,
      videoUrl: scene['animationUrl'] as String? ?? '',
      thumbnailUrl:
          scene['generatedImageUrl'] as String? ??
          scene['generated_image_url'] as String? ??
          '',
      dialogueText: dialogueText,
      narratorText:
          scene['narrationText'] as String? ??
          scene['narration_text'] as String? ??
          scene['description'] as String?,
      videoDurationMs: (durationSec * 1000).toInt(),
    );
  }
}

/// Une page du VisioBook (contient plusieurs panels)
class VisiobookPage {
  final int pageNumber;
  final List<VisiobookPanel> panels;
  final String? audioUrl;
  final int? audioDurationMs;

  const VisiobookPage({
    required this.pageNumber,
    required this.panels,
    this.audioUrl,
    this.audioDurationMs,
  });

  factory VisiobookPage.fromJson(Map<String, dynamic> json) {
    return VisiobookPage(
      pageNumber:
          (json['pageNumber'] as num?)?.toInt() ??
          (json['page_number'] as num?)?.toInt() ??
          1,
      panels:
          (json['panels'] as List? ?? [])
              .map((p) => VisiobookPanel.fromJson(p as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => a.order.compareTo(b.order)),
      audioUrl: json['audioUrl'] as String? ?? json['audio_url'] as String?,
      audioDurationMs:
          (json['audioDurationMs'] as num?)?.toInt() ??
          (json['audio_duration_ms'] as num?)?.toInt(),
    );
  }
}

/// VisioBook complet
class VisiobookData {
  final String projectId;
  final String title;
  final List<VisiobookPage> pages;
  final String? coverUrl;
  final int totalPages;
  final String? style;
  final String? language;
  final DateTime createdAt;

  const VisiobookData({
    required this.projectId,
    required this.title,
    required this.pages,
    this.coverUrl,
    required this.totalPages,
    this.style,
    this.language,
    required this.createdAt,
  });

  /// All panels flattened in order across all pages
  List<VisiobookPanel> get allPanels {
    final panels = <VisiobookPanel>[];
    for (final page in pages) {
      panels.addAll(page.panels);
    }
    return panels;
  }

  int get totalPanels => allPanels.length;

  /// Construit un VisiobookData à partir des scènes du backend.
  /// [projectJson] : réponse GET /projects/:id (titre, config, etc.)
  /// [scenes] : réponse GET /projects/:id/content/scenes (liste de scènes)
  /// Chaque scène devient un panel, groupées en pages de [scenesPerPage].
  factory VisiobookData.fromScenesResponse({
    required Map<String, dynamic> projectJson,
    required List<dynamic> scenes,
    int scenesPerPage = 4,
  }) {
    // Trier les scènes par order
    final sortedScenes =
        List<Map<String, dynamic>>.from(
          scenes.map((s) => s as Map<String, dynamic>),
        )..sort(
          (a, b) =>
              ((a['order'] as num?) ?? 0).compareTo((b['order'] as num?) ?? 0),
        );

    // Grouper en pages
    final pages = <VisiobookPage>[];
    for (var i = 0; i < sortedScenes.length; i += scenesPerPage) {
      final end = (i + scenesPerPage > sortedScenes.length)
          ? sortedScenes.length
          : i + scenesPerPage;
      final pageScenes = sortedScenes.sublist(i, end);
      pages.add(
        VisiobookPage(
          pageNumber: (i ~/ scenesPerPage) + 1,
          panels: pageScenes.map((s) => VisiobookPanel.fromScene(s)).toList(),
        ),
      );
    }

    final config = projectJson['config'] as Map<String, dynamic>? ?? {};

    return VisiobookData(
      projectId: projectJson['id'] as String? ?? '',
      title: projectJson['title'] as String? ?? 'Sans titre',
      pages: pages,
      coverUrl: pages.isNotEmpty && pages.first.panels.isNotEmpty
          ? pages.first.panels.first.thumbnailUrl
          : null,
      totalPages: pages.length,
      style: config['style'] as String?,
      language: config['language'] as String?,
      createdAt:
          DateTime.tryParse(projectJson['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  factory VisiobookData.fromJson(Map<String, dynamic> json) {
    // Handle wrapper: { "data": { ... } }
    final data =
        json.containsKey('data') && json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final pages =
        (data['pages'] as List? ?? [])
            .map((p) => VisiobookPage.fromJson(p as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.pageNumber.compareTo(b.pageNumber));

    return VisiobookData(
      projectId:
          data['projectId'] as String? ?? data['project_id'] as String? ?? '',
      title: data['title'] as String? ?? 'Sans titre',
      pages: pages,
      coverUrl: data['coverUrl'] as String? ?? data['cover_url'] as String?,
      totalPages:
          (data['totalPages'] as num?)?.toInt() ??
          (data['total_pages'] as num?)?.toInt() ??
          pages.length,
      style: data['style'] as String?,
      language: data['language'] as String?,
      createdAt:
          DateTime.tryParse(
            data['createdAt'] as String? ?? data['created_at'] as String? ?? '',
          ) ??
          DateTime.now(),
    );
  }
}
