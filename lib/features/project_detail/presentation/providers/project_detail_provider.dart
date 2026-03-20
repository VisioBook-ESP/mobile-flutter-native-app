import 'package:flutter/foundation.dart';
import 'package:visiobook_mobile/config/environment.dart';
import 'package:visiobook_mobile/features/project_detail/domain/project_config.dart';
import 'package:visiobook_mobile/features/projects/data/project_service.dart';
import 'package:visiobook_mobile/features/projects/domain/project.dart';

/// Etats possibles du detail projet
enum ProjectDetailState { initial, loading, loaded, saving, generating, error }

/// Provider pour gerer le detail et la configuration d'un projet
class ProjectDetailProvider extends ChangeNotifier {
  final ProjectService _projectService;

  ProjectDetailState _state = ProjectDetailState.initial;
  Project? _project;
  ProjectConfig _config = const ProjectConfig();
  String? _error;
  String? _extractedText;
  int? _wordCount;
  String? _fileId;

  ProjectDetailProvider({required ProjectService projectService})
    : _projectService = projectService;

  // Getters
  ProjectDetailState get state => _state;
  Project? get project => _project;
  ProjectConfig get config => _config;
  String? get error => _error;
  String? get extractedText => _extractedText;
  int? get wordCount => _wordCount;
  String? get fileId => _fileId;
  bool get isLoading => _state == ProjectDetailState.loading;
  bool get isSaving => _state == ProjectDetailState.saving;
  bool get isGenerating => _state == ProjectDetailState.generating;
  bool get hasProject => _project != null;

  /// Initialise avec les donnees de l'import
  void initFromImport({
    required String fileId,
    required String fileName,
    String? extractedText,
    int? wordCount,
  }) {
    _fileId = fileId;
    _extractedText = extractedText;
    _wordCount = wordCount;

    // Creer un projet temporaire pour l'affichage
    _project = Project(
      id: 'temp_$fileId',
      title: _generateTitleFromFileName(fileName),
      description: extractedText != null
          ? (extractedText.length > 200
                ? '${extractedText.substring(0, 200)}...'
                : extractedText)
          : null,
      status: ProjectStatus.draft,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _state = ProjectDetailState.loaded;
    notifyListeners();
  }

  /// Charge un projet existant par son ID
  Future<void> loadProject(String id) async {
    _state = ProjectDetailState.loading;
    _error = null;
    notifyListeners();

    // Mode mock
    if (EnvironmentConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      _project = Project(
        id: id,
        title: 'Projet $id',
        description: 'Description du projet charge',
        status: ProjectStatus.draft,
        coverUrl: 'https://picsum.photos/seed/$id/300/400',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now(),
      );
      _state = ProjectDetailState.loaded;
      notifyListeners();
      return;
    }

    final result = await _projectService.getProject(id);

    if (result.success && result.data != null) {
      _project = result.data;
      _state = ProjectDetailState.loaded;
    } else {
      _error = result.error;
      _state = ProjectDetailState.error;
    }

    notifyListeners();
  }

  /// Met a jour le style
  void setStyle(VideoStyle style) {
    _config = _config.copyWith(style: style);
    notifyListeners();
  }

  /// Met a jour la langue
  void setLanguage(AudioLanguage language) {
    _config = _config.copyWith(language: language);
    notifyListeners();
  }

  /// Met a jour la duree
  void setDuration(VideoDuration duration) {
    _config = _config.copyWith(duration: duration);
    notifyListeners();
  }

  /// Met a jour le titre du projet
  void setTitle(String title) {
    if (_project != null) {
      _project = Project(
        id: _project!.id,
        title: title,
        description: _project!.description,
        status: _project!.status,
        coverUrl: _project!.coverUrl,
        videoUrl: _project!.videoUrl,
        createdAt: _project!.createdAt,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  /// Sauvegarde le projet (cree ou met a jour)
  Future<String?> saveProject() async {
    if (_project == null) return null;

    _state = ProjectDetailState.saving;
    _error = null;
    notifyListeners();

    // Mode mock
    if (EnvironmentConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      final savedId = 'project_${DateTime.now().millisecondsSinceEpoch}';
      _project = Project(
        id: savedId,
        title: _project!.title,
        description: _project!.description,
        status: ProjectStatus.draft,
        coverUrl: _project!.coverUrl,
        createdAt: _project!.createdAt,
        updatedAt: DateTime.now(),
      );
      _state = ProjectDetailState.loaded;
      notifyListeners();
      return savedId;
    }

    // Determiner si c'est une creation ou une mise a jour
    final isNew = _project!.id.startsWith('temp_');

    if (isNew) {
      final result = await _projectService.createProject(
        title: _project!.title,
        description: _project!.description,
        fileId: _fileId,
        style: _config.style.name,
        language: _config.language.code,
        duration: _config.duration.name,
      );

      if (result.success && result.data != null) {
        _project = result.data;
        _state = ProjectDetailState.loaded;
        notifyListeners();
        return result.data!.id;
      } else {
        _error = result.error;
        _state = ProjectDetailState.error;
        notifyListeners();
        return null;
      }
    }

    // Mise a jour d'un projet existant
    final result = await _projectService.updateProject(
      id: _project!.id,
      title: _project!.title,
      description: _project!.description,
      fileId: _fileId,
      style: _config.style.name,
      language: _config.language.code,
      duration: _config.duration.name,
    );

    if (result.success && result.data != null) {
      _project = result.data;
      _state = ProjectDetailState.loaded;
      notifyListeners();
      return result.data!.id;
    } else {
      _error = result.error;
      _state = ProjectDetailState.error;
      notifyListeners();
      return null;
    }
  }

  /// Lance la generation du projet
  Future<String?> generateProject() async {
    final projectId = await saveProject();
    if (projectId == null) return null;

    _state = ProjectDetailState.generating;
    _error = null;
    notifyListeners();

    // Mode mock
    if (EnvironmentConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      _state = ProjectDetailState.loaded;
      notifyListeners();
      return 'workflow_${DateTime.now().millisecondsSinceEpoch}';
    }

    final result = await _projectService.generateProject(
      projectId,
      config: _config.toJson(),
    );

    if (result.success) {
      _state = ProjectDetailState.loaded;
      notifyListeners();
      return result.data;
    }

    _error = result.error;
    _state = ProjectDetailState.error;
    notifyListeners();
    return null;
  }

  /// Reset l'etat
  void reset() {
    _state = ProjectDetailState.initial;
    _project = null;
    _fileId = null;
    _config = const ProjectConfig();
    _error = null;
    _extractedText = null;
    _wordCount = null;
    notifyListeners();
  }

  /// Clear l'erreur
  void clearError() {
    _error = null;
    if (_state == ProjectDetailState.error) {
      _state = _project != null
          ? ProjectDetailState.loaded
          : ProjectDetailState.initial;
    }
    notifyListeners();
  }

  String _generateTitleFromFileName(String fileName) {
    // Enlever l'extension
    final withoutExt = fileName.replaceAll(RegExp(r'\.[^.]+$'), '');
    // Remplacer les underscores et tirets par des espaces
    final cleaned = withoutExt.replaceAll(RegExp(r'[_-]'), ' ');
    // Capitaliser
    return cleaned
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
              : '',
        )
        .join(' ');
  }
}
