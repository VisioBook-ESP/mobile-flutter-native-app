import 'package:visiobook_mobile/features/visiobook_grid/domain/visiobook_models.dart';

class MockVisiobookData {
  static VisiobookData getMockVisiobook() {
    return VisiobookData(
      projectId: 'mock-001',
      title: "L'Explorateur des Étoiles",
      coverUrl: 'https://placeholder.com/cover.jpg',
      totalPages: 3,
      style: 'realistic',
      language: 'fr',
      createdAt: DateTime(2026, 3, 19),
      pages: [
        // Page 1 - "Grande + 2 petites + bandeau"
        VisiobookPage(
          pageNumber: 1,
          panels: [
            VisiobookPanel(
              id: 'panel_001',
              order: 0,
              videoUrl: 'https://placeholder.com/videos/panel_001.mp4',
              thumbnailUrl: 'https://placeholder.com/thumbnails/panel_001.jpg',
              layout: const PanelLayout(row: 0, col: 0, rowSpan: 2, colSpan: 1),
              narratorText:
                  'Dans une galaxie lointaine, un explorateur nommé Atlas préparait son voyage.',
              videoDurationMs: 10000,
            ),
            VisiobookPanel(
              id: 'panel_002',
              order: 1,
              videoUrl: 'https://placeholder.com/videos/panel_002.mp4',
              thumbnailUrl: 'https://placeholder.com/thumbnails/panel_002.jpg',
              layout: const PanelLayout(row: 0, col: 1, rowSpan: 1, colSpan: 1),
              dialogueText: 'Atlas : Les étoiles m\'appellent...',
              videoDurationMs: 7000,
            ),
            VisiobookPanel(
              id: 'panel_003',
              order: 2,
              videoUrl: 'https://placeholder.com/videos/panel_003.mp4',
              thumbnailUrl: 'https://placeholder.com/thumbnails/panel_003.jpg',
              layout: const PanelLayout(row: 1, col: 1, rowSpan: 1, colSpan: 1),
              dialogueText: 'Luna : Tu ne peux pas partir seul !',
              videoDurationMs: 8000,
            ),
            VisiobookPanel(
              id: 'panel_004',
              order: 3,
              videoUrl: 'https://placeholder.com/videos/panel_004.mp4',
              thumbnailUrl: 'https://placeholder.com/thumbnails/panel_004.jpg',
              layout: const PanelLayout(row: 2, col: 0, rowSpan: 1, colSpan: 2),
              narratorText:
                  'Mais rien ne pouvait arrêter Atlas. Il embarqua à bord du Nebula.',
              videoDurationMs: 9000,
            ),
          ],
        ),
        // Page 2 - "Bandeau + 2 égales + grande"
        VisiobookPage(
          pageNumber: 2,
          panels: [
            VisiobookPanel(
              id: 'panel_005',
              order: 0,
              videoUrl: 'https://placeholder.com/videos/panel_005.mp4',
              thumbnailUrl: 'https://placeholder.com/thumbnails/panel_005.jpg',
              layout: const PanelLayout(row: 0, col: 0, rowSpan: 1, colSpan: 2),
              narratorText:
                  'L\'espace s\'étendait devant lui, infini et silencieux.',
              videoDurationMs: 9000,
            ),
            VisiobookPanel(
              id: 'panel_006',
              order: 1,
              videoUrl: 'https://placeholder.com/videos/panel_006.mp4',
              thumbnailUrl: 'https://placeholder.com/thumbnails/panel_006.jpg',
              layout: const PanelLayout(row: 1, col: 0, rowSpan: 1, colSpan: 1),
              dialogueText: 'Atlas : C\'est... magnifique.',
              videoDurationMs: 7000,
            ),
            VisiobookPanel(
              id: 'panel_007',
              order: 2,
              videoUrl: 'https://placeholder.com/videos/panel_007.mp4',
              thumbnailUrl: 'https://placeholder.com/thumbnails/panel_007.jpg',
              layout: const PanelLayout(row: 1, col: 1, rowSpan: 1, colSpan: 1),
              narratorText:
                  'Des forêts cristallines brillaient sous un ciel violet.',
              videoDurationMs: 8000,
            ),
            VisiobookPanel(
              id: 'panel_008',
              order: 3,
              videoUrl: 'https://placeholder.com/videos/panel_008.mp4',
              thumbnailUrl: 'https://placeholder.com/thumbnails/panel_008.jpg',
              layout: const PanelLayout(row: 2, col: 0, rowSpan: 2, colSpan: 2),
              dialogueText: 'Atlas : Je vais explorer cette planète !',
              videoDurationMs: 12000,
            ),
          ],
        ),
        // Page 3 - "Mosaïque"
        VisiobookPage(
          pageNumber: 3,
          panels: [
            VisiobookPanel(
              id: 'panel_009',
              order: 0,
              videoUrl: 'https://placeholder.com/videos/panel_009.mp4',
              thumbnailUrl: 'https://placeholder.com/thumbnails/panel_009.jpg',
              layout: const PanelLayout(row: 0, col: 0, rowSpan: 1, colSpan: 1),
              dialogueText: 'Luna : Atlas, tu me reçois ?',
              videoDurationMs: 7000,
            ),
            VisiobookPanel(
              id: 'panel_010',
              order: 1,
              videoUrl: 'https://placeholder.com/videos/panel_010.mp4',
              thumbnailUrl: 'https://placeholder.com/thumbnails/panel_010.jpg',
              layout: const PanelLayout(row: 0, col: 1, rowSpan: 1, colSpan: 1),
              dialogueText: 'Atlas : Fort et clair !',
              videoDurationMs: 7000,
            ),
            VisiobookPanel(
              id: 'panel_011',
              order: 2,
              videoUrl: 'https://placeholder.com/videos/panel_011.mp4',
              thumbnailUrl: 'https://placeholder.com/thumbnails/panel_011.jpg',
              layout: const PanelLayout(row: 1, col: 0, rowSpan: 1, colSpan: 2),
              narratorText: 'La transmission se coupa brusquement.',
              videoDurationMs: 8000,
            ),
            VisiobookPanel(
              id: 'panel_012',
              order: 3,
              videoUrl: 'https://placeholder.com/videos/panel_012.mp4',
              thumbnailUrl: 'https://placeholder.com/thumbnails/panel_012.jpg',
              layout: const PanelLayout(row: 2, col: 0, rowSpan: 1, colSpan: 1),
              narratorText: 'Le silence envahit le cockpit.',
              videoDurationMs: 9000,
            ),
            VisiobookPanel(
              id: 'panel_013',
              order: 4,
              videoUrl: 'https://placeholder.com/videos/panel_013.mp4',
              thumbnailUrl: 'https://placeholder.com/thumbnails/panel_013.jpg',
              layout: const PanelLayout(row: 2, col: 1, rowSpan: 2, colSpan: 1),
              dialogueText: 'Atlas : Qu\'est-ce que... ?',
              videoDurationMs: 10000,
            ),
            VisiobookPanel(
              id: 'panel_014',
              order: 5,
              videoUrl: 'https://placeholder.com/videos/panel_014.mp4',
              thumbnailUrl: 'https://placeholder.com/thumbnails/panel_014.jpg',
              layout: const PanelLayout(row: 3, col: 0, rowSpan: 1, colSpan: 1),
              narratorText: 'Une lumière étrange apparut à l\'horizon.',
              videoDurationMs: 11000,
            ),
          ],
        ),
      ],
    );
  }
}
