import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:visiobook_mobile/config/environment.dart';
import 'package:visiobook_mobile/features/generation/domain/ingestion_state.dart';
import 'package:visiobook_mobile/features/history/domain/user_file.dart';
import 'package:visiobook_mobile/features/history/presentation/providers/texts_provider.dart';
import 'package:visiobook_mobile/features/history/presentation/screens/text_detail_screen.dart';

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
    // No-op: avoids creating timers from mock ingestion
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
      extractedText:
          'Lorsque j\'avais six ans j\'ai vu, une fois, une magnifique image, '
          'dans un livre sur la Foret Vierge qui s\'appelait "Histoires Vecues". '
          'Ca representait un serpent boa qui avalait un fauve. '
          'On disait dans le livre: "Les serpents boas avalent leur proie tout '
          'entiere, sans la macher. Ensuite ils ne peuvent plus bouger et ils '
          'dorment pendant les six mois de leur digestion."',
      wordCount: 1250,
      fileType: 'pdf',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    UserFile(
      id: 'file-2',
      name: 'Les Miserables.txt',
      extractedText: 'Some text content.',
      wordCount: 8500,
      fileType: 'txt',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  setUp(() {
    EnvironmentConfig.useMockData = true;
    textsProvider = _SafeTextsProvider();
    textsProvider.setFilesForTest(mockFiles);
  });

  tearDown(() {
    EnvironmentConfig.useMockData = false;
    textsProvider.dispose();
  });

  Widget buildWidget({String projectId = 'file-1'}) {
    return MaterialApp(
      home: ChangeNotifierProvider<TextsProvider>.value(
        value: textsProvider,
        child: TextDetailScreen(projectId: projectId),
      ),
    );
  }

  group('TextDetailScreen', () {
    testWidgets('renders app bar with title', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Détail du texte'), findsOneWidget);
    });

    testWidgets('shows file name after loading', (tester) async {
      await tester.pumpWidget(buildWidget(projectId: 'file-1'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Le Petit Prince.pdf'), findsOneWidget);
    });

    testWidgets('shows word count after loading', (tester) async {
      await tester.pumpWidget(buildWidget(projectId: 'file-1'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('1250 mots'), findsOneWidget);
    });

    testWidgets('shows not found state for invalid id', (tester) async {
      await tester.pumpWidget(buildWidget(projectId: 'nonexistent'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Texte introuvable'), findsOneWidget);
    });

    testWidgets('shows create project button', (tester) async {
      await tester.pumpWidget(buildWidget(projectId: 'file-1'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Créer un projet'), findsOneWidget);
    });

    testWidgets('shows file type badge', (tester) async {
      await tester.pumpWidget(buildWidget(projectId: 'file-1'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('PDF'), findsOneWidget);
    });

    testWidgets('shows summary section for long text', (tester) async {
      await tester.pumpWidget(buildWidget(projectId: 'file-1'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // The mock text is long enough to generate a summary
      expect(find.text('Résumé'), findsOneWidget);
    });

    testWidgets('shows extracted text content', (tester) async {
      await tester.pumpWidget(buildWidget(projectId: 'file-1'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // The full text should be displayed in the content area
      expect(find.textContaining('serpent boa'), findsWidgets);
    });

    testWidgets('shows Retour button', (tester) async {
      await tester.pumpWidget(buildWidget(projectId: 'file-1'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Retour'), findsOneWidget);
    });

    testWidgets('shows short text without summary for file-2', (tester) async {
      await tester.pumpWidget(buildWidget(projectId: 'file-2'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // file-2 has short extractedText (< 100 chars), no summary
      expect(find.text('Résumé'), findsNothing);
      // But the text content itself should be visible
      expect(find.text('Some text content.'), findsOneWidget);
    });
  });
}
