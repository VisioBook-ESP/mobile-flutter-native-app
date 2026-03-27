import 'package:flutter/foundation.dart';
import 'package:visiobook_mobile/config/environment.dart';
import 'package:visiobook_mobile/features/history/domain/user_file.dart';
import 'package:visiobook_mobile/features/import/data/storage_service.dart';

enum TextsState { initial, loading, loaded, error }

/// Provider pour gerer la liste des textes/fichiers de l'utilisateur
class TextsProvider extends ChangeNotifier {
  final StorageService _storageService;

  TextsState _state = TextsState.initial;
  List<UserFile> _files = [];
  String? _error;

  TextsProvider({required StorageService storageService})
    : _storageService = storageService;

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
      _files = _mockFiles;
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
}
