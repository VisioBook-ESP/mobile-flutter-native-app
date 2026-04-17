import 'package:flutter_test/flutter_test.dart';
import 'package:visiobook_mobile/features/projects/domain/project.dart';

void main() {
  group('ProjectStatus', () {
    test('fromString returns correct status for valid values', () {
      expect(ProjectStatus.fromString('draft'), ProjectStatus.draft);
      expect(ProjectStatus.fromString('processing'), ProjectStatus.processing);
      expect(ProjectStatus.fromString('ready'), ProjectStatus.ready);
      expect(ProjectStatus.fromString('error'), ProjectStatus.error);
    });

    test('fromString is case-insensitive', () {
      expect(ProjectStatus.fromString('DRAFT'), ProjectStatus.draft);
      expect(ProjectStatus.fromString('Processing'), ProjectStatus.processing);
      expect(ProjectStatus.fromString('READY'), ProjectStatus.ready);
    });

    test('fromString defaults to draft for unknown values', () {
      expect(ProjectStatus.fromString('unknown'), ProjectStatus.draft);
      expect(ProjectStatus.fromString(''), ProjectStatus.draft);
      expect(ProjectStatus.fromString('foo'), ProjectStatus.draft);
    });

    test('label returns correct French labels', () {
      expect(ProjectStatus.draft.label, 'Brouillon');
      expect(ProjectStatus.processing.label, 'En cours...');
      expect(ProjectStatus.ready.label, 'Pret');
      expect(ProjectStatus.error.label, 'Erreur');
    });
  });

  group('Generation', () {
    test('fromJson parses valid JSON', () {
      final json = {
        'id': 'gen-123',
        'thumbnailUrl': 'https://example.com/thumb.jpg',
        'videoUrl': 'https://example.com/video.mp4',
        'createdAt': '2025-01-15T10:30:00.000Z',
      };

      final generation = Generation.fromJson(json);

      expect(generation.id, 'gen-123');
      expect(generation.thumbnailUrl, 'https://example.com/thumb.jpg');
      expect(generation.videoUrl, 'https://example.com/video.mp4');
      expect(generation.createdAt, DateTime.parse('2025-01-15T10:30:00.000Z'));
    });

    test('fromJson handles null optional fields', () {
      final json = {'id': 'gen-456', 'createdAt': '2025-06-01T00:00:00.000Z'};

      final generation = Generation.fromJson(json);

      expect(generation.id, 'gen-456');
      expect(generation.thumbnailUrl, isNull);
      expect(generation.videoUrl, isNull);
    });
  });

  group('Project', () {
    test('fromJson parses valid full JSON', () {
      final json = {
        'id': 'proj-001',
        'title': 'My Book',
        'description': 'A great book',
        'author': 'John Doe',
        'genre': 'Fantasy',
        'status': 'ready',
        'coverUrl': 'https://example.com/cover.jpg',
        'videoUrl': 'https://example.com/video.mp4',
        'videoDurationSeconds': 150,
        'style': 'anime',
        'generations': [
          {
            'id': 'gen-1',
            'thumbnailUrl': 'https://example.com/t.jpg',
            'videoUrl': 'https://example.com/v.mp4',
            'createdAt': '2025-01-01T00:00:00.000Z',
          },
        ],
        'createdAt': '2025-01-01T00:00:00.000Z',
        'updatedAt': '2025-01-02T00:00:00.000Z',
      };

      final project = Project.fromJson(json);

      expect(project.id, 'proj-001');
      expect(project.title, 'My Book');
      expect(project.description, 'A great book');
      expect(project.author, 'John Doe');
      expect(project.genre, 'Fantasy');
      expect(project.status, ProjectStatus.ready);
      expect(project.coverUrl, 'https://example.com/cover.jpg');
      expect(project.videoUrl, 'https://example.com/video.mp4');
      expect(project.videoDurationSeconds, 150);
      expect(project.style, 'anime');
      expect(project.generations, hasLength(1));
      expect(project.generations.first.id, 'gen-1');
      expect(project.createdAt, DateTime.parse('2025-01-01T00:00:00.000Z'));
      expect(project.updatedAt, DateTime.parse('2025-01-02T00:00:00.000Z'));
    });

    test('fromJson handles minimal JSON (missing optional fields)', () {
      final json = {
        'id': 'proj-002',
        'createdAt': '2025-01-01T00:00:00.000Z',
        'updatedAt': '2025-01-01T00:00:00.000Z',
      };

      final project = Project.fromJson(json);

      expect(project.id, 'proj-002');
      expect(project.title, 'Sans titre');
      expect(project.description, isNull);
      expect(project.author, isNull);
      expect(project.genre, isNull);
      expect(project.status, ProjectStatus.draft);
      expect(project.coverUrl, isNull);
      expect(project.videoUrl, isNull);
      expect(project.videoDurationSeconds, isNull);
      expect(project.style, isNull);
      expect(project.generations, isEmpty);
    });

    test('toJson roundtrip preserves data', () {
      final json = {
        'id': 'proj-003',
        'title': 'Roundtrip Test',
        'description': 'Testing roundtrip',
        'author': 'Author',
        'genre': 'Sci-Fi',
        'status': 'processing',
        'coverUrl': 'https://example.com/cover.jpg',
        'videoUrl': null,
        'videoDurationSeconds': 300,
        'style': 'realistic',
        'createdAt': '2025-06-01T12:00:00.000Z',
        'updatedAt': '2025-06-02T12:00:00.000Z',
      };

      final project = Project.fromJson(json);
      final outputJson = project.toJson();

      expect(outputJson['id'], json['id']);
      expect(outputJson['title'], json['title']);
      expect(outputJson['description'], json['description']);
      expect(outputJson['author'], json['author']);
      expect(outputJson['genre'], json['genre']);
      expect(outputJson['status'], 'processing');
      expect(outputJson['coverUrl'], json['coverUrl']);
      expect(outputJson['videoDurationSeconds'], json['videoDurationSeconds']);
      expect(outputJson['style'], json['style']);
    });

    group('formattedDuration', () {
      test('formats 150 seconds as 2:30', () {
        final project = Project(
          id: '1',
          title: 'Test',
          status: ProjectStatus.draft,
          videoDurationSeconds: 150,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(project.formattedDuration, '2:30');
      });

      test('formats 0 seconds as 0:00', () {
        final project = Project(
          id: '1',
          title: 'Test',
          status: ProjectStatus.draft,
          videoDurationSeconds: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(project.formattedDuration, '0:00');
      });

      test('formats 65 seconds as 1:05', () {
        final project = Project(
          id: '1',
          title: 'Test',
          status: ProjectStatus.draft,
          videoDurationSeconds: 65,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(project.formattedDuration, '1:05');
      });

      test('returns --:-- when duration is null', () {
        final project = Project(
          id: '1',
          title: 'Test',
          status: ProjectStatus.draft,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(project.formattedDuration, '--:--');
      });

      test('formats exactly 60 seconds as 1:00', () {
        final project = Project(
          id: '1',
          title: 'Test',
          status: ProjectStatus.draft,
          videoDurationSeconds: 60,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(project.formattedDuration, '1:00');
      });

      test('formats large duration 3661 seconds as 61:01', () {
        final project = Project(
          id: '1',
          title: 'Test',
          status: ProjectStatus.draft,
          videoDurationSeconds: 3661,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(project.formattedDuration, '61:01');
      });

      test('formats single-digit seconds with leading zero', () {
        final project = Project(
          id: '1',
          title: 'Test',
          status: ProjectStatus.draft,
          videoDurationSeconds: 9,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(project.formattedDuration, '0:09');
      });
    });

    test('fromJson with multiple generations', () {
      final json = {
        'id': 'proj-multi',
        'title': 'Multi Gen',
        'status': 'ready',
        'generations': [
          {
            'id': 'gen-a',
            'thumbnailUrl': 'https://example.com/a.jpg',
            'createdAt': '2025-01-01T00:00:00.000Z',
          },
          {
            'id': 'gen-b',
            'videoUrl': 'https://example.com/b.mp4',
            'createdAt': '2025-02-01T00:00:00.000Z',
          },
          {'id': 'gen-c', 'createdAt': '2025-03-01T00:00:00.000Z'},
        ],
        'createdAt': '2025-01-01T00:00:00.000Z',
        'updatedAt': '2025-03-01T00:00:00.000Z',
      };

      final project = Project.fromJson(json);

      expect(project.generations, hasLength(3));
      expect(project.generations[0].id, 'gen-a');
      expect(project.generations[0].thumbnailUrl, 'https://example.com/a.jpg');
      expect(project.generations[0].videoUrl, isNull);
      expect(project.generations[1].id, 'gen-b');
      expect(project.generations[1].thumbnailUrl, isNull);
      expect(project.generations[1].videoUrl, 'https://example.com/b.mp4');
      expect(project.generations[2].id, 'gen-c');
      expect(project.generations[2].thumbnailUrl, isNull);
      expect(project.generations[2].videoUrl, isNull);
    });

    test('fromJson defaults status to draft when status field is missing', () {
      final json = {
        'id': 'proj-no-status',
        'title': 'No Status',
        'createdAt': '2025-01-01T00:00:00.000Z',
        'updatedAt': '2025-01-01T00:00:00.000Z',
      };

      final project = Project.fromJson(json);

      expect(project.status, ProjectStatus.draft);
    });

    test('toJson does not include generations', () {
      final project = Project(
        id: 'proj-tojson',
        title: 'ToJson Test',
        status: ProjectStatus.ready,
        generations: [
          Generation(
            id: 'gen-1',
            createdAt: DateTime.parse('2025-01-01T00:00:00.000Z'),
          ),
        ],
        createdAt: DateTime.parse('2025-01-01T00:00:00.000Z'),
        updatedAt: DateTime.parse('2025-01-01T00:00:00.000Z'),
      );

      final json = project.toJson();

      expect(json.containsKey('generations'), isFalse);
      expect(json['id'], 'proj-tojson');
      expect(json['status'], 'ready');
    });

    test('toJson includes createdAt and updatedAt as ISO strings', () {
      final created = DateTime.parse('2025-06-15T08:30:00.000Z');
      final updated = DateTime.parse('2025-06-16T10:00:00.000Z');
      final project = Project(
        id: 'proj-dates',
        title: 'Dates Test',
        status: ProjectStatus.draft,
        createdAt: created,
        updatedAt: updated,
      );

      final json = project.toJson();

      expect(json['createdAt'], created.toIso8601String());
      expect(json['updatedAt'], updated.toIso8601String());
    });

    test('constructor defaults generations to empty list', () {
      final project = Project(
        id: 'proj-default',
        title: 'Default Gens',
        status: ProjectStatus.draft,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(project.generations, isEmpty);
      expect(project.generations, isA<List<Generation>>());
    });
  });
}
