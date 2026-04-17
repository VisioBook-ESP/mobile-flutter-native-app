import 'package:flutter_test/flutter_test.dart';
import 'package:visiobook_mobile/config/environment.dart';
import 'package:visiobook_mobile/core/network/api_client.dart';
import 'package:visiobook_mobile/core/utils/secure_storage.dart';
import 'package:visiobook_mobile/features/generation/domain/ingestion_state.dart';
import 'package:visiobook_mobile/features/history/presentation/providers/texts_provider.dart';
import 'package:visiobook_mobile/features/import/data/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TextsProvider provider;

  setUp(() {
    EnvironmentConfig.useMockData = true;
    final storage = SecureStorageService();
    final apiClient = ApiClient(storage: storage);
    final storageService = StorageService(apiClient: apiClient);
    provider = TextsProvider(storageService: storageService);
  });

  tearDown(() {
    // Clear ingestion states before dispose to cancel pending mock timers
    provider.clearIngestionState('file-ingesting');
    provider.clearIngestionState('test-file');
    provider.clearIngestionState('mock-f');
    provider.clearIngestionState('f1');
    provider.clearIngestionState('f2');
    EnvironmentConfig.useMockData = false;
    provider.dispose();
  });

  group('TextsProvider', () {
    test('initial state is correct', () {
      expect(provider.state, TextsState.initial);
      expect(provider.files, isEmpty);
      expect(provider.error, isNull);
      expect(provider.isLoading, isFalse);
    });

    test('loadFiles in mock mode returns mock files', () async {
      await provider.loadFiles();

      expect(provider.files, isNotEmpty);
      // Mock data includes 4 static files + 1 ingesting file
      expect(provider.files.length, 5);
    });

    test('loadFiles sets state to loaded', () async {
      await provider.loadFiles();

      expect(provider.state, TextsState.loaded);
      expect(provider.error, isNull);
    });

    test('getFileById returns correct file', () async {
      await provider.loadFiles();

      final file = provider.getFileById('file-1');
      expect(file, isNotNull);
      expect(file!.id, 'file-1');
      expect(file.name, 'Le Petit Prince.pdf');
    });

    test('getFileById returns null for unknown id', () async {
      await provider.loadFiles();

      final file = provider.getFileById('nonexistent-id');
      expect(file, isNull);
    });

    test('isIngesting returns false when no tracking', () {
      expect(provider.isIngesting('some-file-id'), isFalse);
    });

    test('getIngestionState returns null when no tracking', () {
      expect(provider.getIngestionState('some-file-id'), isNull);
    });

    test('startIngestionTracking sets initial state in mock mode', () {
      provider.startIngestionTracking('test-file', 'test-job', 'test.pdf');

      final state = provider.getIngestionState('test-file');
      expect(state, isNotNull);
      expect(state!.jobId, 'test-job');
      expect(state.status, IngestionStatus.queued);
      expect(provider.isIngesting('test-file'), isTrue);
    });

    test('clearIngestionState removes state', () {
      provider.startIngestionTracking('test-file', 'test-job', 'test.pdf');
      expect(provider.getIngestionState('test-file'), isNotNull);

      provider.clearIngestionState('test-file');
      expect(provider.getIngestionState('test-file'), isNull);
      expect(provider.isIngesting('test-file'), isFalse);
    });

    test('clearIngestionState notifies listeners', () {
      provider.startIngestionTracking('test-file', 'test-job', 'test.pdf');

      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.clearIngestionState('test-file');
      expect(notifyCount, 1);
    });

    test(
      'loadFiles mock mode returns files with ingesting file first',
      () async {
        // Pre-set ingestion state to prevent _simulateMockIngestion timer
        provider.startIngestionTracking(
          'file-ingesting',
          'mock_job_auto',
          'Nouveau_document.pdf',
        );
        await provider.loadFiles();

        // The first file should be the ingesting file
        expect(provider.files.first.id, 'file-ingesting');
        expect(provider.files.first.name, 'Nouveau_document.pdf');
        expect(provider.files.first.extractedText, isNull);
      },
    );

    test('loadFiles mock mode includes 4 static + 1 ingesting file', () async {
      // Pre-set ingestion state to prevent _simulateMockIngestion timer
      provider.startIngestionTracking(
        'file-ingesting',
        'mock_job_auto',
        'Nouveau_document.pdf',
      );
      await provider.loadFiles();

      expect(provider.files.length, 5);
      final ids = provider.files.map((f) => f.id).toList();
      expect(ids, contains('file-1'));
      expect(ids, contains('file-2'));
      expect(ids, contains('file-3'));
      expect(ids, contains('file-4'));
      expect(ids, contains('file-ingesting'));
    });

    test(
      'startIngestionTracking mock mode simulates processing after start',
      () async {
        provider.startIngestionTracking('mock-f', 'mock-j', 'mock.pdf');

        // Initially queued
        final state = provider.getIngestionState('mock-f');
        expect(state, isNotNull);
        expect(state!.status, IngestionStatus.queued);
        expect(provider.isIngesting('mock-f'), isTrue);
      },
    );

    test('clearIngestionState cleans up multiple fields', () {
      provider.startIngestionTracking('f1', 'j1', 'a.pdf');
      provider.startIngestionTracking('f2', 'j2', 'b.pdf');

      provider.clearIngestionState('f1');

      expect(provider.getIngestionState('f1'), isNull);
      expect(provider.isIngesting('f1'), isFalse);
      // f2 should still be tracked
      expect(provider.getIngestionState('f2'), isNotNull);
      expect(provider.isIngesting('f2'), isTrue);
    });

    test('clearIngestionState on unknown file does not throw', () {
      provider.clearIngestionState('nonexistent');
      expect(provider.getIngestionState('nonexistent'), isNull);
    });
  });
}
