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
