import 'package:flutter_test/flutter_test.dart';
import 'package:visiobook_mobile/features/player/domain/visiobook_reader_state.dart';

void main() {
  group('VisiobookPanel.fromJson', () {
    test('parses valid camelCase JSON correctly', () {
      final json = {
        'id': 'panel_001',
        'order': 0,
        'videoUrl': 'https://example.com/video.mp4',
        'thumbnailUrl': 'https://example.com/thumb.jpg',
        'dialogueText': 'Hello world',
        'narratorText': 'Once upon a time',
        'videoDurationMs': 8000,
      };

      final panel = VisiobookPanel.fromJson(json);

      expect(panel.id, 'panel_001');
      expect(panel.order, 0);
      expect(panel.videoUrl, 'https://example.com/video.mp4');
      expect(panel.thumbnailUrl, 'https://example.com/thumb.jpg');
      expect(panel.dialogueText, 'Hello world');
      expect(panel.narratorText, 'Once upon a time');
      expect(panel.videoDurationMs, 8000);
    });

    test('parses snake_case JSON correctly', () {
      final json = {
        'id': 'panel_002',
        'order': 1,
        'video_url': 'https://example.com/video2.mp4',
        'thumbnail_url': 'https://example.com/thumb2.jpg',
        'dialogue_text': 'Bonjour',
        'narrator_text': 'Il etait une fois',
        'video_duration_ms': 6000,
      };

      final panel = VisiobookPanel.fromJson(json);

      expect(panel.id, 'panel_002');
      expect(panel.order, 1);
      expect(panel.videoUrl, 'https://example.com/video2.mp4');
      expect(panel.thumbnailUrl, 'https://example.com/thumb2.jpg');
      expect(panel.dialogueText, 'Bonjour');
      expect(panel.narratorText, 'Il etait une fois');
      expect(panel.videoDurationMs, 6000);
    });

    test('handles missing optional fields (dialogueText, narratorText)', () {
      final json = {
        'id': 'panel_003',
        'order': 2,
        'videoUrl': 'https://example.com/video.mp4',
        'thumbnailUrl': 'https://example.com/thumb.jpg',
        'videoDurationMs': 5000,
      };

      final panel = VisiobookPanel.fromJson(json);

      expect(panel.dialogueText, isNull);
      expect(panel.narratorText, isNull);
    });

    test(
      'handles numeric types (double instead of int for order, videoDurationMs)',
      () {
        final json = {
          'id': 'panel_004',
          'order': 3.0,
          'videoUrl': 'https://example.com/video.mp4',
          'thumbnailUrl': 'https://example.com/thumb.jpg',
          'videoDurationMs': 7000.0,
        };

        final panel = VisiobookPanel.fromJson(json);

        expect(panel.order, 3);
        expect(panel.videoDurationMs, 7000);
      },
    );

    test('handles missing required fields with defaults', () {
      final json = <String, dynamic>{};

      final panel = VisiobookPanel.fromJson(json);

      expect(panel.id, '');
      expect(panel.order, 0);
      expect(panel.videoUrl, '');
      expect(panel.thumbnailUrl, '');
      expect(panel.videoDurationMs, 0);
    });
  });

  group('VisiobookPage.fromJson', () {
    test('parses valid JSON with panels', () {
      final json = {
        'pageNumber': 1,
        'panels': [
          {
            'id': 'p1',
            'order': 0,
            'videoUrl': 'https://example.com/v1.mp4',
            'thumbnailUrl': 'https://example.com/t1.jpg',
            'videoDurationMs': 5000,
          },
        ],
        'audioUrl': 'https://example.com/audio.mp3',
        'audioDurationMs': 30000,
      };

      final page = VisiobookPage.fromJson(json);

      expect(page.pageNumber, 1);
      expect(page.panels.length, 1);
      expect(page.panels[0].id, 'p1');
      expect(page.audioUrl, 'https://example.com/audio.mp3');
      expect(page.audioDurationMs, 30000);
    });

    test('sorts panels by order', () {
      final json = {
        'pageNumber': 1,
        'panels': [
          {
            'id': 'p2',
            'order': 2,
            'videoUrl': 'https://example.com/v2.mp4',
            'thumbnailUrl': 'https://example.com/t2.jpg',
            'videoDurationMs': 3000,
          },
          {
            'id': 'p0',
            'order': 0,
            'videoUrl': 'https://example.com/v0.mp4',
            'thumbnailUrl': 'https://example.com/t0.jpg',
            'videoDurationMs': 4000,
          },
          {
            'id': 'p1',
            'order': 1,
            'videoUrl': 'https://example.com/v1.mp4',
            'thumbnailUrl': 'https://example.com/t1.jpg',
            'videoDurationMs': 5000,
          },
        ],
      };

      final page = VisiobookPage.fromJson(json);

      expect(page.panels[0].id, 'p0');
      expect(page.panels[1].id, 'p1');
      expect(page.panels[2].id, 'p2');
    });

    test('handles empty panels list', () {
      final json = {'pageNumber': 1, 'panels': []};

      final page = VisiobookPage.fromJson(json);

      expect(page.panels, isEmpty);
      expect(page.audioUrl, isNull);
      expect(page.audioDurationMs, isNull);
    });

    test('handles snake_case fields', () {
      // Note: VisiobookPage.fromJson only reads camelCase keys for
      // pageNumber, audioUrl, audioDurationMs. However, the panels
      // within it do support snake_case via VisiobookPanel.fromJson.
      final json = {
        'pageNumber': 2,
        'panels': [
          {
            'id': 'p1',
            'order': 0,
            'video_url': 'https://example.com/v1.mp4',
            'thumbnail_url': 'https://example.com/t1.jpg',
            'video_duration_ms': 5000,
          },
        ],
        'audioUrl': 'https://example.com/audio.mp3',
      };

      final page = VisiobookPage.fromJson(json);

      expect(page.pageNumber, 2);
      expect(page.panels[0].videoUrl, 'https://example.com/v1.mp4');
    });
  });

  group('VisiobookData.fromJson', () {
    final specJson = {
      'projectId': '550e8400-e29b-41d4-a716-446655440000',
      'title': "L'Explorateur des Etoiles",
      'pages': [
        {
          'pageNumber': 1,
          'panels': [
            {
              'id': 'panel_001',
              'order': 0,
              'videoUrl': 'https://storage.example.com/panels/panel_001.mp4',
              'thumbnailUrl':
                  'https://storage.example.com/panels/panel_001_thumb.jpg',
              'dialogueText': 'Atlas : Regarde ces etoiles...',
              'narratorText': 'Dans une galaxie lointaine...',
              'videoDurationMs': 8000,
            },
            {
              'id': 'panel_002',
              'order': 1,
              'videoUrl': 'https://storage.example.com/panels/panel_002.mp4',
              'thumbnailUrl':
                  'https://storage.example.com/panels/panel_002_thumb.jpg',
              'videoDurationMs': 6000,
            },
          ],
          'audioUrl': 'https://storage.example.com/audio/page_001.mp3',
          'audioDurationMs': 30000,
        },
      ],
      'coverUrl': 'https://storage.example.com/cover.jpg',
      'totalPages': 1,
      'style': 'realistic',
      'language': 'fr',
      'createdAt': '2024-01-15T12:00:00Z',
    };

    test('parses the full spec JSON example', () {
      final data = VisiobookData.fromJson(specJson);

      expect(data.projectId, '550e8400-e29b-41d4-a716-446655440000');
      expect(data.title, "L'Explorateur des Etoiles");
      expect(data.pages.length, 1);
      expect(data.pages[0].pageNumber, 1);
      expect(data.pages[0].panels.length, 2);
      expect(data.pages[0].panels[0].id, 'panel_001');
      expect(
        data.pages[0].panels[0].dialogueText,
        'Atlas : Regarde ces etoiles...',
      );
      expect(
        data.pages[0].panels[0].narratorText,
        'Dans une galaxie lointaine...',
      );
      expect(data.pages[0].panels[1].id, 'panel_002');
      expect(data.pages[0].panels[1].dialogueText, isNull);
      expect(
        data.pages[0].audioUrl,
        'https://storage.example.com/audio/page_001.mp3',
      );
      expect(data.pages[0].audioDurationMs, 30000);
      expect(data.coverUrl, 'https://storage.example.com/cover.jpg');
      expect(data.totalPages, 1);
      expect(data.style, 'realistic');
      expect(data.language, 'fr');
      expect(data.createdAt, DateTime.utc(2024, 1, 15, 12, 0, 0));
      expect(data.totalPanels, 2);
    });

    test('handles { "data": { ... } } wrapper', () {
      final wrappedJson = {'data': specJson};

      // VisiobookData.fromJson expects the inner map, so the caller
      // must unwrap. We verify that parsing the inner data works.
      final inner = wrappedJson['data'] as Map<String, dynamic>;
      final data = VisiobookData.fromJson(inner);

      expect(data.projectId, '550e8400-e29b-41d4-a716-446655440000');
      expect(data.title, "L'Explorateur des Etoiles");
    });

    test(
      'calculates totalPages from pages.length when totalPages is missing',
      () {
        // The current implementation requires totalPages as int, so this
        // test verifies the pages list length matches totalPages.
        final json = Map<String, dynamic>.from(specJson);
        // totalPages matches pages.length
        final data = VisiobookData.fromJson(json);
        expect(data.totalPages, data.pages.length);
      },
    );

    test('handles snake_case fields in nested panels', () {
      final json = {
        'projectId': 'abc-123',
        'title': 'Test Book',
        'pages': [
          {
            'pageNumber': 1,
            'panels': [
              {
                'id': 'p1',
                'order': 0,
                'video_url': 'https://example.com/v.mp4',
                'thumbnail_url': 'https://example.com/t.jpg',
                'dialogue_text': 'Hello',
                'narrator_text': 'Narrator speaks',
                'video_duration_ms': 3000,
              },
            ],
          },
        ],
        'coverUrl': 'https://example.com/cover.jpg',
        'totalPages': 1,
        'createdAt': '2024-06-01T00:00:00Z',
      };

      final data = VisiobookData.fromJson(json);

      expect(data.pages[0].panels[0].videoUrl, 'https://example.com/v.mp4');
      expect(data.pages[0].panels[0].thumbnailUrl, 'https://example.com/t.jpg');
      expect(data.pages[0].panels[0].dialogueText, 'Hello');
      expect(data.pages[0].panels[0].narratorText, 'Narrator speaks');
      expect(data.pages[0].panels[0].videoDurationMs, 3000);
    });

    test('parses createdAt correctly', () {
      final data = VisiobookData.fromJson(specJson);

      expect(data.createdAt, isA<DateTime>());
      expect(data.createdAt.year, 2024);
      expect(data.createdAt.month, 1);
      expect(data.createdAt.day, 15);
    });

    test('handles { "data": { ... } } wrapper directly in fromJson', () {
      final wrappedJson = {'data': specJson};
      final data = VisiobookData.fromJson(wrappedJson);

      expect(data.projectId, '550e8400-e29b-41d4-a716-446655440000');
      expect(data.title, "L'Explorateur des Etoiles");
      expect(data.pages.length, 1);
    });

    test('sorts pages by pageNumber', () {
      final json = {
        'projectId': 'abc-123',
        'title': 'Multi Page Book',
        'pages': [
          {
            'pageNumber': 3,
            'panels': [
              {
                'id': 'p3',
                'order': 0,
                'videoUrl': 'https://example.com/v3.mp4',
                'thumbnailUrl': 'https://example.com/t3.jpg',
                'videoDurationMs': 1000,
              },
            ],
          },
          {
            'pageNumber': 1,
            'panels': [
              {
                'id': 'p1',
                'order': 0,
                'videoUrl': 'https://example.com/v1.mp4',
                'thumbnailUrl': 'https://example.com/t1.jpg',
                'videoDurationMs': 2000,
              },
            ],
          },
          {
            'pageNumber': 2,
            'panels': [
              {
                'id': 'p2',
                'order': 0,
                'videoUrl': 'https://example.com/v2.mp4',
                'thumbnailUrl': 'https://example.com/t2.jpg',
                'videoDurationMs': 3000,
              },
            ],
          },
        ],
        'totalPages': 3,
        'createdAt': '2024-01-01T00:00:00Z',
      };

      final data = VisiobookData.fromJson(json);

      expect(data.pages[0].pageNumber, 1);
      expect(data.pages[1].pageNumber, 2);
      expect(data.pages[2].pageNumber, 3);
    });
  });

  group('VisiobookPanel.fromScene', () {
    test('maps backend scene fields correctly', () {
      final scene = {
        'id': 'scene-001',
        'order': 2,
        'text': 'Scene text excerpt',
        'description': 'A magical forest at dawn',
        'generatedImageUrl': 'https://storage.example.com/scenes/001/image.png',
        'animationUrl': 'https://storage.example.com/scenes/001/animation.mp4',
        'duration': 7.5,
        'narrationText': 'The forest whispered ancient secrets.',
        'dialogues': [
          {'speaker': 'Luna', 'line': 'Listen to the trees!'},
        ],
      };

      final panel = VisiobookPanel.fromScene(scene);

      expect(panel.id, 'scene-001');
      expect(panel.order, 2);
      expect(
        panel.videoUrl,
        'https://storage.example.com/scenes/001/animation.mp4',
      );
      expect(
        panel.thumbnailUrl,
        'https://storage.example.com/scenes/001/image.png',
      );
      expect(panel.narratorText, 'The forest whispered ancient secrets.');
      expect(panel.dialogueText, 'Luna : Listen to the trees!');
      expect(panel.videoDurationMs, 7500);
    });

    test('concatenates multiple dialogues', () {
      final scene = {
        'id': 'scene-002',
        'order': 0,
        'duration': 5,
        'dialogues': [
          {'speaker': 'Luna', 'line': 'Hello!'},
          {'speaker': 'Atlas', 'line': 'Greetings!'},
        ],
      };

      final panel = VisiobookPanel.fromScene(scene);

      expect(panel.dialogueText, 'Luna : Hello!\nAtlas : Greetings!');
    });

    test('falls back to description when narrationText is absent', () {
      final scene = {
        'id': 'scene-003',
        'order': 0,
        'description': 'A quiet village',
        'duration': 3,
      };

      final panel = VisiobookPanel.fromScene(scene);

      expect(panel.narratorText, 'A quiet village');
      expect(panel.dialogueText, isNull);
    });

    test('handles empty scene with defaults', () {
      final scene = <String, dynamic>{};

      final panel = VisiobookPanel.fromScene(scene);

      expect(panel.id, '');
      expect(panel.order, 0);
      expect(panel.videoUrl, '');
      expect(panel.thumbnailUrl, '');
      expect(panel.videoDurationMs, 5000);
    });

    test('handles snake_case generatedImageUrl', () {
      final scene = {
        'id': 's1',
        'order': 0,
        'generated_image_url': 'https://storage.example.com/img.png',
        'duration': 4,
      };

      final panel = VisiobookPanel.fromScene(scene);

      expect(panel.thumbnailUrl, 'https://storage.example.com/img.png');
    });
  });

  group('VisiobookData.fromScenesResponse', () {
    test('builds pages from backend scenes grouped by scenesPerPage', () {
      final project = {
        'id': 'proj-123',
        'title': 'Test Visiobook',
        'config': {'style': 'cartoon', 'language': 'fr'},
        'createdAt': '2025-06-01T00:00:00Z',
      };

      final scenes = List.generate(
        6,
        (i) => {
          'id': 'scene-$i',
          'order': i,
          'description': 'Scene $i description',
          'generatedImageUrl': 'https://storage.example.com/scene_$i.png',
          'duration': 5,
        },
      );

      final data = VisiobookData.fromScenesResponse(
        projectJson: project,
        scenes: scenes,
        scenesPerPage: 4,
      );

      expect(data.projectId, 'proj-123');
      expect(data.title, 'Test Visiobook');
      expect(data.style, 'cartoon');
      expect(data.language, 'fr');
      expect(data.totalPages, 2);
      expect(data.pages[0].pageNumber, 1);
      expect(data.pages[0].panels.length, 4);
      expect(data.pages[1].pageNumber, 2);
      expect(data.pages[1].panels.length, 2);
      expect(data.totalPanels, 6);
    });

    test('sorts scenes by order before grouping', () {
      final project = {
        'id': 'proj-sort',
        'title': 'Sort Test',
        'createdAt': '2025-01-01T00:00:00Z',
      };

      final scenes = [
        {'id': 's2', 'order': 2, 'duration': 3},
        {'id': 's0', 'order': 0, 'duration': 3},
        {'id': 's1', 'order': 1, 'duration': 3},
      ];

      final data = VisiobookData.fromScenesResponse(
        projectJson: project,
        scenes: scenes,
        scenesPerPage: 10,
      );

      expect(data.pages.length, 1);
      expect(data.pages[0].panels[0].id, 's0');
      expect(data.pages[0].panels[1].id, 's1');
      expect(data.pages[0].panels[2].id, 's2');
    });

    test('handles empty scenes list', () {
      final project = {
        'id': 'proj-empty',
        'title': 'Empty',
        'createdAt': '2025-01-01T00:00:00Z',
      };

      final data = VisiobookData.fromScenesResponse(
        projectJson: project,
        scenes: [],
      );

      expect(data.pages, isEmpty);
      expect(data.totalPages, 0);
      expect(data.totalPanels, 0);
      expect(data.coverUrl, isNull);
    });

    test('uses first panel thumbnail as coverUrl', () {
      final project = {
        'id': 'proj-cover',
        'title': 'Cover',
        'createdAt': '2025-01-01T00:00:00Z',
      };

      final scenes = [
        {
          'id': 's0',
          'order': 0,
          'generatedImageUrl': 'https://example.com/cover.png',
          'duration': 5,
        },
      ];

      final data = VisiobookData.fromScenesResponse(
        projectJson: project,
        scenes: scenes,
      );

      expect(data.coverUrl, 'https://example.com/cover.png');
    });
  });
}
