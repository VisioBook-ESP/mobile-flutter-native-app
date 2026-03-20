/// Position et taille d'un panel dans la grille 2 colonnes
class PanelLayout {
  final int row;
  final int col;
  final int rowSpan;
  final int colSpan;

  const PanelLayout({
    required this.row,
    required this.col,
    required this.rowSpan,
    required this.colSpan,
  });

  factory PanelLayout.fromJson(Map<String, dynamic> json) {
    return PanelLayout(
      row: json['row'] as int,
      col: json['col'] as int,
      rowSpan: json['rowSpan'] as int,
      colSpan: json['colSpan'] as int,
    );
  }
}

/// Une vignette/case de la BD animee
class VisiobookPanel {
  final String id;
  final int order;
  final String videoUrl;
  final String thumbnailUrl;
  final PanelLayout layout;
  final String? dialogueText;
  final String? narratorText;
  final int videoDurationMs;

  const VisiobookPanel({
    required this.id,
    required this.order,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.layout,
    this.dialogueText,
    this.narratorText,
    required this.videoDurationMs,
  });

  factory VisiobookPanel.fromJson(Map<String, dynamic> json) {
    return VisiobookPanel(
      id: json['id'] as String,
      order: json['order'] as int,
      videoUrl: json['videoUrl'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String,
      layout: PanelLayout.fromJson(json['layout'] as Map<String, dynamic>),
      dialogueText: json['dialogueText'] as String?,
      narratorText: json['narratorText'] as String?,
      videoDurationMs: json['videoDurationMs'] as int,
    );
  }
}

/// Une page du VisioBook (contient plusieurs panels en grille)
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

  /// Nombre de lignes dans la grille de cette page
  int get totalRows {
    int maxRow = 0;
    for (final panel in panels) {
      final endRow = panel.layout.row + panel.layout.rowSpan;
      if (endRow > maxRow) maxRow = endRow;
    }
    return maxRow;
  }

  factory VisiobookPage.fromJson(Map<String, dynamic> json) {
    return VisiobookPage(
      pageNumber: json['pageNumber'] as int,
      panels:
          (json['panels'] as List)
              .map((p) => VisiobookPanel.fromJson(p as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => a.order.compareTo(b.order)),
      audioUrl: json['audioUrl'] as String?,
      audioDurationMs: json['audioDurationMs'] as int?,
    );
  }
}

/// VisioBook complet
class VisiobookData {
  final String projectId;
  final String title;
  final List<VisiobookPage> pages;
  final String coverUrl;
  final int totalPages;
  final String style;
  final String language;
  final DateTime createdAt;

  const VisiobookData({
    required this.projectId,
    required this.title,
    required this.pages,
    required this.coverUrl,
    required this.totalPages,
    required this.style,
    required this.language,
    required this.createdAt,
  });

  factory VisiobookData.fromJson(Map<String, dynamic> json) {
    return VisiobookData(
      projectId: json['projectId'] as String,
      title: json['title'] as String,
      pages:
          (json['pages'] as List)
              .map((p) => VisiobookPage.fromJson(p as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => a.pageNumber.compareTo(b.pageNumber)),
      coverUrl: json['coverUrl'] as String,
      totalPages: json['totalPages'] as int,
      style: json['style'] as String,
      language: json['language'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
