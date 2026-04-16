import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:visiobook_mobile/config/environment.dart';
import 'package:visiobook_mobile/core/services/notification_service.dart';
import 'package:visiobook_mobile/features/generation/data/ingestion_polling_service.dart';
import 'package:visiobook_mobile/features/generation/domain/ingestion_state.dart';
import 'package:visiobook_mobile/features/history/domain/user_file.dart';
import 'package:visiobook_mobile/features/import/data/storage_service.dart';

enum TextsState { initial, loading, loaded, error }

/// Provider pour gerer la liste des textes/fichiers de l'utilisateur
class TextsProvider extends ChangeNotifier {
  final StorageService _storageService;
  final IngestionPollingService? _ingestionPollingService;

  TextsState _state = TextsState.initial;
  List<UserFile> _files = [];
  String? _error;

  // Ingestion tracking: fileId -> IngestionState
  final Map<String, IngestionState> _ingestionStates = {};
  final Map<String, StreamSubscription<IngestionState>>
  _ingestionSubscriptions = {};
  // Map fileId -> fileName for notifications
  final Map<String, String> _ingestionFileNames = {};

  TextsProvider({
    required StorageService storageService,
    IngestionPollingService? ingestionPollingService,
  }) : _storageService = storageService,
       _ingestionPollingService = ingestionPollingService;

  TextsState get state => _state;
  List<UserFile> get files => _files;
  String? get error => _error;
  bool get isLoading => _state == TextsState.loading;

  /// Donnees mock
  static final List<UserFile> _mockFiles = [
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
      extractedText:
          'En 1815, M. Charles-Francois-Bienvenu Myriel etait eveque de Digne. '
          'C\'etait un vieillard d\'environ soixante-quinze ans; il occupait le '
          'siege de Digne depuis 1806.',
      wordCount: 8500,
      fileType: 'txt',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    UserFile(
      id: 'file-3',
      name: 'Germinal.docx',
      extractedText:
          'Dans la plaine rase, sous la nuit sans etoiles, d\'une obscurite et '
          'd\'une epaisseur d\'encre, un homme suivait seul la grande route de '
          'Marchiennes a Montsou.',
      wordCount: 4200,
      fileType: 'docx',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    UserFile(
      id: 'file-4',
      name: 'L\'Etranger.pdf',
      extractedText:
          'Aujourd\'hui, maman est morte. Ou peut-etre hier, je ne sais pas. '
          'J\'ai recu un telegramme de l\'asile: "Mere decedee. Enterrement '
          'demain. Sentiments distingues." Cela ne veut rien dire. '
          'C\'etait peut-etre hier.',
      wordCount: 3100,
      fileType: 'pdf',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
  ];

  /// Charge les fichiers de l'utilisateur
  Future<void> loadFiles() async {
    _state = TextsState.loading;
    _error = null;
    notifyListeners();

    if (EnvironmentConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      _files = List.from(_mockFiles);

      // Simulate one file currently being ingested
      _files.insert(
        0,
        UserFile(
          id: 'file-ingesting',
          name: 'Nouveau_document.pdf',
          extractedText: null,
          wordCount: null,
          fileType: 'pdf',
          createdAt: DateTime.now(),
        ),
      );

      // Start mock ingestion for this file
      if (!_ingestionStates.containsKey('file-ingesting')) {
        _ingestionStates['file-ingesting'] = IngestionState(
          jobId: 'mock_job_auto',
          status: IngestionStatus.processing,
        );
        _ingestionFileNames['file-ingesting'] = 'Nouveau_document.pdf';
        _simulateMockIngestion(
          'file-ingesting',
          'mock_job_auto',
          'Nouveau_document.pdf',
        );
      }

      _state = TextsState.loaded;
      notifyListeners();
      return;
    }

    final result = await _storageService.getFiles();

    if (result.success && result.data != null) {
      _files = result.data!.map((json) => UserFile.fromJson(json)).toList();
      _files.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      _files = [];
      _error = result.error;
    }
    _state = TextsState.loaded;
    notifyListeners();
  }

  /// Trouve un fichier par son ID
  UserFile? getFileById(String id) {
    try {
      return _files.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Start tracking ingestion for a file
  void startIngestionTracking(String fileId, String jobId, String fileName) {
    _ingestionFileNames[fileId] = fileName;

    // Set initial state
    _ingestionStates[fileId] = IngestionState(
      jobId: jobId,
      status: IngestionStatus.queued,
    );
    notifyListeners();

    // Mock mode: simulate ingestion progression
    if (EnvironmentConfig.useMockData) {
      _simulateMockIngestion(fileId, jobId, fileName);
      return;
    }

    if (_ingestionPollingService == null) return;

    _ingestionSubscriptions[fileId]?.cancel();

    final stream = _ingestionPollingService.pollIngestionStatus(jobId);
    _ingestionSubscriptions[fileId] = stream.listen((state) {
      _ingestionStates[fileId] = state;
      notifyListeners();

      if (state.isFinished) {
        _ingestionSubscriptions[fileId]?.cancel();
        _ingestionSubscriptions.remove(fileId);

        final name = _ingestionFileNames[fileId] ?? 'Fichier';
        if (state.status == IngestionStatus.completed) {
          NotificationService.instance.showIngestionComplete(name);
          loadFiles();
        } else if (state.status == IngestionStatus.failed) {
          NotificationService.instance.showIngestionFailed(name);
        }
        _ingestionFileNames.remove(fileId);
      }
    });
  }

  /// Simulates ingestion in mock mode:
  /// - 0s: queued
  /// - 1s: processing
  /// - 8s: completed (with notification)
  void _simulateMockIngestion(String fileId, String jobId, String fileName) {
    // After 1 second: switch to processing
    Timer(const Duration(seconds: 1), () {
      if (_ingestionStates.containsKey(fileId)) {
        _ingestionStates[fileId] = IngestionState(
          jobId: jobId,
          status: IngestionStatus.processing,
        );
        notifyListeners();
      }
    });

    // After 8 seconds: switch to completed
    Timer(const Duration(seconds: 8), () {
      if (_ingestionStates.containsKey(fileId)) {
        _ingestionStates[fileId] = IngestionState(
          jobId: jobId,
          status: IngestionStatus.completed,
          totalChunks: 5,
        );
        notifyListeners();

        NotificationService.instance.showIngestionComplete(fileName);
        _ingestionFileNames.remove(fileId);

        // Refresh to update the file list
        loadFiles();
      }
    });
  }

  /// Get ingestion state for a file
  IngestionState? getIngestionState(String fileId) => _ingestionStates[fileId];

  /// Check if a file is currently being ingested
  bool isIngesting(String fileId) {
    final state = _ingestionStates[fileId];
    return state != null && state.isInProgress;
  }

  /// Clear ingestion state for a file
  void clearIngestionState(String fileId) {
    _ingestionSubscriptions[fileId]?.cancel();
    _ingestionSubscriptions.remove(fileId);
    _ingestionStates.remove(fileId);
    _ingestionFileNames.remove(fileId);
    notifyListeners();
  }

  @override
  void dispose() {
    for (final sub in _ingestionSubscriptions.values) {
      sub.cancel();
    }
    _ingestionSubscriptions.clear();
    super.dispose();
  }
}
