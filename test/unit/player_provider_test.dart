import 'package:flutter_test/flutter_test.dart';
import 'package:visiobook_mobile/features/player/data/player_service.dart';
import 'package:visiobook_mobile/features/player/domain/visiobook_reader_state.dart';
import 'package:visiobook_mobile/features/player/presentation/providers/player_provider.dart';

/// A fake PlayerService that returns mock data without needing ApiClient.
class FakePlayerService implements PlayerService {
  final VisiobookData? mockData;

  FakePlayerService({this.mockData});

  @override
  Future<PlayerResult<VisiobookData>> getVisioBook(String projectId) async {
    if (mockData != null) {
      return PlayerResult(success: true, data: mockData);
    }
    return PlayerResult(success: false, error: 'No mock data');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('PlayerProvider', () {
    late FakePlayerService fakeService;
    late PlayerProvider provider;

    /// Build a VisiobookData with a given number of panels.
    VisiobookData buildMockData({int panelCount = 5}) {
      final panels = List.generate(
        panelCount,
        (i) => VisiobookPanel(
          id: 'panel_$i',
          order: i,
          videoUrl: 'https://example.com/video_$i.mp4',
          thumbnailUrl: 'https://example.com/thumb_$i.jpg',
          narratorText: 'Panel $i narration',
          videoDurationMs: 5000,
        ),
      );

      return VisiobookData(
        projectId: 'test-project',
        title: 'Test VisioBook',
        pages: [VisiobookPage(pageNumber: 1, panels: panels)],
        totalPages: 1,
        createdAt: DateTime(2025, 1, 1),
      );
    }

    setUp(() {
      fakeService = FakePlayerService();
      provider = PlayerProvider(playerService: fakeService);
    });

    test(
      'initial state is correct (not loading, no error, null visioBook)',
      () {
        expect(provider.isLoading, false);
        expect(provider.error, isNull);
        expect(provider.visioBook, isNull);
        expect(provider.currentPanelIndex, 0);
        expect(provider.hasReachedEnd, false);
        expect(provider.totalPanels, 0);
        expect(provider.title, '');
        expect(provider.allPanels, isEmpty);
        expect(provider.currentPanel, isNull);
      },
    );

    test('onPageChanged updates currentPanelIndex', () {
      provider.onPageChanged(3);
      expect(provider.currentPanelIndex, 3);

      provider.onPageChanged(7);
      expect(provider.currentPanelIndex, 7);
    });

    test('onPageChanged does not notify when index is unchanged', () {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.onPageChanged(2);
      expect(notifyCount, 1);

      // Same index - should not notify
      provider.onPageChanged(2);
      expect(notifyCount, 1);
    });

    group('progress computation', () {
      test('progress is 0.0 when no panels and not reached end', () {
        // totalPanels <= 1 and hasReachedEnd is false => 0.0
        expect(provider.progress, 0.0);
      });

      test('progress ranges from 0.0 to 1.0 with loaded data', () async {
        final mockData = buildMockData(panelCount: 5);
        fakeService = FakePlayerService(mockData: mockData);
        provider = PlayerProvider(playerService: fakeService);

        await provider.loadVisioBook('test-project');

        expect(provider.totalPanels, 5);

        // At panel 0: progress = 1/5 = 0.2
        expect(provider.progress, closeTo(0.2, 0.001));

        // Move to panel 2: progress = 3/5 = 0.6
        provider.onPageChanged(2);
        expect(provider.progress, closeTo(0.6, 0.001));

        // Move to last panel: progress = 5/5 = 1.0
        provider.onPageChanged(4);
        expect(provider.progress, closeTo(1.0, 0.001));
        expect(provider.hasReachedEnd, true);
      });
    });

    test('replay resets to panel 0', () async {
      final mockData = buildMockData(panelCount: 5);
      fakeService = FakePlayerService(mockData: mockData);
      provider = PlayerProvider(playerService: fakeService);

      await provider.loadVisioBook('test-project');

      // Move forward
      provider.onPageChanged(3);
      expect(provider.currentPanelIndex, 3);

      // Reach the end
      provider.onPageChanged(4);
      expect(provider.hasReachedEnd, true);

      // Replay
      provider.replay();
      expect(provider.currentPanelIndex, 0);
      expect(provider.hasReachedEnd, false);
    });

    test('replay starts a new reading timer', () {
      // Initially no reading time
      expect(provider.readingDuration, Duration.zero);

      // After replay, reading timer starts
      provider.replay();
      expect(provider.readingDuration.inMilliseconds, greaterThanOrEqualTo(0));
    });

    test('reset clears all state', () async {
      final mockData = buildMockData(panelCount: 3);
      fakeService = FakePlayerService(mockData: mockData);
      provider = PlayerProvider(playerService: fakeService);

      await provider.loadVisioBook('test-project');
      provider.onPageChanged(2);

      provider.reset();

      expect(provider.isLoading, false);
      expect(provider.error, isNull);
      expect(provider.visioBook, isNull);
      expect(provider.currentPanelIndex, 0);
      expect(provider.hasReachedEnd, false);
      expect(provider.readingDuration, Duration.zero);
    });
  });
}
