import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:visiobook_mobile/config/environment.dart';
import 'package:visiobook_mobile/features/generation/domain/ingestion_state.dart';
import 'package:visiobook_mobile/features/history/domain/user_file.dart';
import 'package:visiobook_mobile/features/history/presentation/providers/texts_provider.dart';
import 'package:visiobook_mobile/features/history/presentation/screens/texts_history_screen.dart';

/// A TextsProvider subclass that avoids platform channels and timers.
class _SafeTextsProvider extends ChangeNotifier implements TextsProvider {
  TextsState _state = TextsState.loaded;
  List<UserFile> _files = [];
  String? _error;

  void setFilesForTest(List<UserFile> files) {
    _files = files;
    _state = TextsState.loaded;
    notifyListeners();
  }

  @override
  TextsState get state => _state;
  @override
  List<UserFile> get files => _files;
  @override
  String? get error => _error;
  @override
  bool get isLoading => _state == TextsState.loading;

  @override
  Future<void> loadFiles() async {
    // No-op: avoids creating timers
  }

  @override
  UserFile? getFileById(String id) {
    try {
      return _files.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  void startIngestionTracking(String fileId, String jobId, String fileName) {}

  @override
  IngestionState? getIngestionState(String fileId) => null;

  @override
  bool isIngesting(String fileId) => false;

  @override
  void clearIngestionState(String fileId) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _SafeTextsProvider textsProvider;

  final mockFiles = [
    UserFile(
      id: 'file-1',
      name: 'Le Petit Prince.pdf',
      extractedText: 'Some text here',
      wordCount: 1250,
      fileType: 'pdf',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    UserFile(
      id: 'file-2',
      name: 'Les Miserables.txt',
      extractedText: 'Another text',
      wordCount: 8500,
      fileType: 'txt',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    UserFile(
      id: 'file-3',
      name: 'Germinal.docx',
      extractedText: 'Yet another text',
      wordCount: 4200,
      fileType: 'docx',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  setUp(() {
    EnvironmentConfig.useMockData = true;
    textsProvider = _SafeTextsProvider();
  });

  tearDown(() {
    EnvironmentConfig.useMockData = false;
    textsProvider.dispose();
  });

  Widget buildWidget() {
    return MaterialApp(
      home: ChangeNotifierProvider<TextsProvider>.value(
        value: textsProvider,
        child: const TextsHistoryScreen(),
      ),
    );
  }

  group('TextsHistoryScreen', () {
    testWidgets('renders app bar with Mes Textes title', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.text('Mes Textes'), findsOneWidget);
    });

    testWidgets('shows search field', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows filter chips', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.text('Tous'), findsOneWidget);
    });

    testWidgets('shows empty state when no files', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.text('Aucun texte'), findsOneWidget);
    });

    testWidgets('shows file list when files are loaded', (tester) async {
      textsProvider.setFilesForTest(mockFiles);

      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.text('Le Petit Prince.pdf'), findsOneWidget);
      expect(find.text('Les Miserables.txt'), findsOneWidget);
    });

    testWidgets('search field filters results', (tester) async {
      textsProvider.setFilesForTest(mockFiles);

      await tester.pumpWidget(buildWidget());
      await tester.pump();

      // Type in search field
      await tester.enterText(find.byType(TextField), 'Prince');
      await tester.pump();

      // Should still show matching file
      expect(find.text('Le Petit Prince.pdf'), findsOneWidget);
      // Should not show non-matching file
      expect(find.text('Les Miserables.txt'), findsNothing);
    });

    testWidgets('shows Récents filter chip', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.text('Récents'), findsOneWidget);
    });

    testWidgets('tapping Récents filter chip changes filter', (tester) async {
      textsProvider.setFilesForTest(mockFiles);

      await tester.pumpWidget(buildWidget());
      await tester.pump();

      // Tap on "Récents" filter
      await tester.tap(find.text('Récents'));
      await tester.pump();

      // Germinal was created 5 hours ago, should still be visible
      expect(find.text('Germinal.docx'), findsOneWidget);
    });

    testWidgets('empty state shows import message', (tester) async {
      // No files set - provider has empty list
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.text('Aucun texte'), findsOneWidget);
      expect(
        find.text('Importez votre premier texte pour commencer'),
        findsOneWidget,
      );
    });

    testWidgets('filter chips toggle between Tous and Récents', (tester) async {
      textsProvider.setFilesForTest(mockFiles);

      await tester.pumpWidget(buildWidget());
      await tester.pump();

      // Initially Tous is selected, all files visible
      expect(find.text('Le Petit Prince.pdf'), findsOneWidget);

      // Tap Récents
      await tester.tap(find.text('Récents'));
      await tester.pump();

      // Tap back to Tous
      await tester.tap(find.text('Tous'));
      await tester.pump();

      // All files visible again
      expect(find.text('Le Petit Prince.pdf'), findsOneWidget);
    });
  });
}
