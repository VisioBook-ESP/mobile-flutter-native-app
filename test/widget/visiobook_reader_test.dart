import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:visiobook_mobile/config/environment.dart';
import 'package:visiobook_mobile/features/player/domain/visiobook_reader_state.dart';
import 'package:visiobook_mobile/features/player/presentation/providers/player_provider.dart';
import 'package:visiobook_mobile/features/player/presentation/screens/visiobook_reader_screen.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

/// A controllable PlayerProvider for testing without network or video player.
class _FakePlayerProvider extends ChangeNotifier implements PlayerProvider {
  VisiobookData? _visioBook;
  bool _isLoading = false;
  String? _error;
  int _currentPanelIndex = 0;
  bool _hasReachedEnd = false;
  DateTime? _readingStartTime;

  @override
  VisiobookData? get visioBook => _visioBook;
  @override
  bool get isLoading => _isLoading;
  @override
  String? get error => _error;
  @override
  int get currentPanelIndex => _currentPanelIndex;
  @override
  bool get hasReachedEnd => _hasReachedEnd;
  @override
  int get totalPanels => _visioBook?.totalPanels ?? 0;
  @override
  String get title => _visioBook?.title ?? '';
  @override
  List<VisiobookPanel> get allPanels => _visioBook?.allPanels ?? [];

  @override
  VisiobookPanel? get currentPanel {
    final panels = allPanels;
    if (_currentPanelIndex >= panels.length) return null;
    return panels[_currentPanelIndex];
  }

  @override
  double get progress {
    if (totalPanels <= 1) return _hasReachedEnd ? 1.0 : 0.0;
    return (_currentPanelIndex + 1) / totalPanels;
  }

  @override
  Duration get readingDuration {
    if (_readingStartTime == null) return Duration.zero;
    return DateTime.now().difference(_readingStartTime!);
  }

  @override
  Future<void> loadVisioBook(String projectId) async {
    // no-op for testing; set state manually
  }

  @override
  void onPageChanged(int index) {
    _currentPanelIndex = index;
    if (index == totalPanels - 1) _hasReachedEnd = true;
    notifyListeners();
  }

  @override
  void replay() {
    _currentPanelIndex = 0;
    _hasReachedEnd = false;
    _readingStartTime = DateTime.now();
    notifyListeners();
  }

  @override
  void reset() {
    _visioBook = null;
    _isLoading = false;
    _error = null;
    _currentPanelIndex = 0;
    _hasReachedEnd = false;
    _readingStartTime = null;
    notifyListeners();
  }

  // Helpers for tests to set state
  void setLoading() {
    _isLoading = true;
    _error = null;
    _visioBook = null;
    notifyListeners();
  }

  void setError(String msg) {
    _isLoading = false;
    _error = msg;
    _visioBook = null;
    notifyListeners();
  }

  void setData(VisiobookData data) {
    _isLoading = false;
    _error = null;
    _visioBook = data;
    _readingStartTime = DateTime.now();
    notifyListeners();
  }
}

Widget _wrapWithRouter(Widget screen, _FakePlayerProvider provider) {
  final router = GoRouter(
    initialLocation: '/test',
    routes: [
      GoRoute(path: '/test', builder: (context, state) => screen),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const Scaffold(body: Text('Dashboard')),
      ),
    ],
  );

  return ChangeNotifierProvider<PlayerProvider>.value(
    value: provider,
    child: MaterialApp.router(routerConfig: router),
  );
}

VisiobookData _mockData() {
  return VisiobookData(
    projectId: 'test-proj',
    title: 'Test VisioBook',
    totalPages: 1,
    createdAt: DateTime.now(),
    pages: [
      VisiobookPage(
        pageNumber: 1,
        panels: [
          const VisiobookPanel(
            id: 'p1',
            order: 0,
            videoUrl: '',
            thumbnailUrl: '',
            narratorText: 'Once upon a time...',
            videoDurationMs: 5000,
          ),
          const VisiobookPanel(
            id: 'p2',
            order: 1,
            videoUrl: '',
            thumbnailUrl: '',
            dialogueText: 'Hello world',
            videoDurationMs: 3000,
          ),
        ],
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    EnvironmentConfig.useMockData = true;
  });

  tearDown(() {
    EnvironmentConfig.useMockData = false;
  });

  group('VisioBookReaderScreen', () {
    testWidgets('shows loading indicator when loading', (tester) async {
      final provider = _FakePlayerProvider();
      provider.setLoading();

      await tester.pumpWidget(
        _wrapWithRouter(
          const VisioBookReaderScreen(projectId: 'proj-1'),
          provider,
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message and retry button', (tester) async {
      final provider = _FakePlayerProvider();
      provider.setError('Impossible de charger le VisioBook');

      await tester.pumpWidget(
        _wrapWithRouter(
          const VisioBookReaderScreen(projectId: 'proj-1'),
          provider,
        ),
      );
      await tester.pump();

      expect(find.text('Impossible de charger le VisioBook'), findsOneWidget);
      expect(find.text('Reessayer'), findsOneWidget);
    });

    testWidgets('shows panels when data is loaded', (tester) async {
      final provider = _FakePlayerProvider();
      provider.setData(_mockData());

      await tester.pumpWidget(
        _wrapWithRouter(
          const VisioBookReaderScreen(projectId: 'test-proj'),
          provider,
        ),
      );
      await tester.pump();

      // Title should be visible
      expect(find.text('Test VisioBook'), findsOneWidget);
      // Page counter should show
      expect(find.text('1 / 2'), findsOneWidget);
    });

    testWidgets(
      'shows SizedBox.shrink when visioBook is null and not loading',
      (tester) async {
        final provider = _FakePlayerProvider();
        // Default state: not loading, no error, no data

        await tester.pumpWidget(
          _wrapWithRouter(
            const VisioBookReaderScreen(projectId: 'proj-1'),
            provider,
          ),
        );
        await tester.pump();

        // SizedBox.shrink is rendered, so no CircularProgressIndicator
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );

    testWidgets('has a back button (arrow left icon)', (tester) async {
      final provider = _FakePlayerProvider();
      provider.setData(_mockData());

      await tester.pumpWidget(
        _wrapWithRouter(
          const VisioBookReaderScreen(projectId: 'test-proj'),
          provider,
        ),
      );
      await tester.pump();

      // Should have an IconButton to go back
      expect(find.byType(IconButton), findsWidgets);
    });

    testWidgets('PageView is present when data loaded', (tester) async {
      final provider = _FakePlayerProvider();
      provider.setData(_mockData());

      await tester.pumpWidget(
        _wrapWithRouter(
          const VisioBookReaderScreen(projectId: 'test-proj'),
          provider,
        ),
      );
      await tester.pump();

      expect(find.byType(PageView), findsOneWidget);
    });
  });
}
