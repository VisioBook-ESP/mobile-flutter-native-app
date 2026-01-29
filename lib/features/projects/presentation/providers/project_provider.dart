import 'package:flutter/foundation.dart';
import 'package:visiobook_mobile/features/projects/data/project_service.dart';
import 'package:visiobook_mobile/features/projects/domain/project.dart';

/// Etats possibles du chargement des projets
enum ProjectsState { initial, loading, loaded, error }

/// Provider pour gerer l'etat des projets
class ProjectProvider extends ChangeNotifier {
  final ProjectService _projectService;

  ProjectsState _state = ProjectsState.initial;
  List<Project> _projects = [];
  String? _error;

  ProjectProvider({required ProjectService projectService})
    : _projectService = projectService;

  ProjectsState get state => _state;
  List<Project> get projects => _projects;
  String? get error => _error;
  bool get isLoading => _state == ProjectsState.loading;

  /// Projets prets (avec video)
  List<Project> get readyProjects =>
      _projects.where((p) => p.status == ProjectStatus.ready).toList();

  /// Projets en cours ou brouillons
  List<Project> get draftProjects =>
      _projects.where((p) => p.status != ProjectStatus.ready).toList();

  /// Charge tous les projets
  Future<void> loadProjects() async {
    _state = ProjectsState.loading;
    _error = null;
    notifyListeners();

    final result = await _projectService.getProjects();

    if (result.success && result.data != null) {
      _projects = result.data!;
      _state = ProjectsState.loaded;
    } else {
      _error = result.error;
      _state = ProjectsState.error;
    }

    notifyListeners();
  }

  /// Cree un nouveau projet
  Future<Project?> createProject({
    required String title,
    String? description,
  }) async {
    final result = await _projectService.createProject(
      title: title,
      description: description,
    );

    if (result.success && result.data != null) {
      _projects.insert(0, result.data!);
      notifyListeners();
      return result.data;
    }

    _error = result.error;
    notifyListeners();
    return null;
  }

  /// Supprime un projet
  Future<bool> deleteProject(String id) async {
    final result = await _projectService.deleteProject(id);

    if (result.success) {
      _projects.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    }

    _error = result.error;
    notifyListeners();
    return false;
  }

  /// Lance la generation d'un projet
  Future<String?> generateProject(String id) async {
    final result = await _projectService.generateProject(id);

    if (result.success) {
      // Met a jour le statut localement
      final index = _projects.indexWhere((p) => p.id == id);
      if (index != -1) {
        _projects[index] = Project(
          id: _projects[index].id,
          title: _projects[index].title,
          description: _projects[index].description,
          status: ProjectStatus.processing,
          coverUrl: _projects[index].coverUrl,
          videoUrl: _projects[index].videoUrl,
          createdAt: _projects[index].createdAt,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }
      return result.data;
    }

    _error = result.error;
    notifyListeners();
    return null;
  }

  /// Reset l'erreur
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
