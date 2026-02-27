import 'package:flutter/foundation.dart';
import 'package:visiobook_mobile/config/environment.dart';
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

  /// Les 4 projets les plus recents (tries par updatedAt decroissant)
  List<Project> get recentProjects {
    final sorted = List<Project>.from(_projects)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted.take(4).toList();
  }

  /// Nombre total de projets (pour les stats)
  int get textsCount => _projects.length;

  /// Donnees mock pour tester l'UI
  static final List<Project> _mockProjects = [
    // Projets ready (VisioBooks termines)
    Project(
      id: '1',
      title: 'Le Petit Prince',
      description: 'Un conte poetique et philosophique',
      author: 'Antoine de Saint-Exupery',
      genre: 'Conte',
      status: ProjectStatus.ready,
      coverUrl: 'https://picsum.photos/seed/prince/300/400',
      videoUrl: 'https://example.com/video1.mp4',
      videoDurationSeconds: 150,
      style: 'Manga',
      generations: [
        Generation(
          id: 'gen1-1',
          thumbnailUrl: 'https://picsum.photos/seed/gen1-1/200/150',
          videoUrl: 'https://example.com/video1.mp4',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        Generation(
          id: 'gen1-2',
          thumbnailUrl: 'https://picsum.photos/seed/gen1-2/200/150',
          videoUrl: 'https://example.com/video1-alt.mp4',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Project(
      id: '2',
      title: 'Les Miserables',
      description: 'Le chef-d\'oeuvre de Victor Hugo',
      author: 'Victor Hugo',
      genre: 'Roman historique',
      status: ProjectStatus.ready,
      coverUrl: 'https://picsum.photos/seed/miserables/300/400',
      videoUrl: 'https://example.com/video2.mp4',
      videoDurationSeconds: 320,
      style: 'Realiste',
      generations: [
        Generation(
          id: 'gen2-1',
          thumbnailUrl: 'https://picsum.photos/seed/gen2-1/200/150',
          videoUrl: 'https://example.com/video2.mp4',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Project(
      id: '5',
      title: 'L\'Etranger',
      description: 'Roman d\'Albert Camus',
      author: 'Albert Camus',
      genre: 'Roman',
      status: ProjectStatus.ready,
      coverUrl: 'https://picsum.photos/seed/etranger/300/400',
      videoUrl: 'https://example.com/video5.mp4',
      videoDurationSeconds: 185,
      style: 'Cartoon',
      generations: [
        Generation(
          id: 'gen5-1',
          thumbnailUrl: 'https://picsum.photos/seed/gen5-1/200/150',
          videoUrl: 'https://example.com/video5.mp4',
          createdAt: DateTime.now().subtract(const Duration(days: 8)),
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      updatedAt: DateTime.now().subtract(const Duration(days: 8)),
    ),
    Project(
      id: '6',
      title: 'Madame Bovary',
      description: 'Chef-d\'oeuvre de Flaubert',
      author: 'Gustave Flaubert',
      genre: 'Roman',
      status: ProjectStatus.ready,
      coverUrl: 'https://picsum.photos/seed/bovary/300/400',
      videoUrl: 'https://example.com/video6.mp4',
      videoDurationSeconds: 240,
      style: 'Aquarelle',
      generations: [
        Generation(
          id: 'gen6-1',
          thumbnailUrl: 'https://picsum.photos/seed/gen6-1/200/150',
          videoUrl: 'https://example.com/video6.mp4',
          createdAt: DateTime.now().subtract(const Duration(days: 12)),
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      updatedAt: DateTime.now().subtract(const Duration(days: 12)),
    ),
    Project(
      id: '7',
      title: 'Notre-Dame de Paris',
      description: 'Roman de Victor Hugo',
      author: 'Victor Hugo',
      genre: 'Roman historique',
      status: ProjectStatus.ready,
      coverUrl: 'https://picsum.photos/seed/notredame/300/400',
      videoUrl: 'https://example.com/video7.mp4',
      videoDurationSeconds: 280,
      style: 'Realiste',
      generations: [
        Generation(
          id: 'gen7-1',
          thumbnailUrl: 'https://picsum.photos/seed/gen7-1/200/150',
          videoUrl: 'https://example.com/video7.mp4',
          createdAt: DateTime.now().subtract(const Duration(days: 18)),
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      updatedAt: DateTime.now().subtract(const Duration(days: 18)),
    ),
    // Projets en cours
    Project(
      id: '3',
      title: 'Germinal',
      description: 'Roman de Emile Zola',
      author: 'Emile Zola',
      genre: 'Roman social',
      status: ProjectStatus.processing,
      coverUrl: 'https://picsum.photos/seed/germinal/300/400',
      style: 'Realiste',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      updatedAt: DateTime.now(),
    ),
    Project(
      id: '4',
      title: 'Mon nouveau projet',
      description: 'Brouillon en cours',
      status: ProjectStatus.draft,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Project(
      id: '8',
      title: 'Candide',
      description: 'Conte philosophique de Voltaire',
      author: 'Voltaire',
      genre: 'Conte philosophique',
      status: ProjectStatus.processing,
      coverUrl: 'https://picsum.photos/seed/candide/300/400',
      style: 'Cartoon',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    Project(
      id: '9',
      title: 'Le Rouge et le Noir',
      description: 'Roman de Stendhal',
      author: 'Stendhal',
      genre: 'Roman',
      status: ProjectStatus.draft,
      coverUrl: 'https://picsum.photos/seed/rouge/300/400',
      style: 'Manga',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
  ];

  /// Charge tous les projets
  Future<void> loadProjects() async {
    _state = ProjectsState.loading;
    _error = null;
    notifyListeners();

    // Mode mock: retourner des donnees fictives
    if (EnvironmentConfig.useMockData) {
      _projects = _mockProjects;
      _state = ProjectsState.loaded;
      notifyListeners();
      return;
    }

    final result = await _projectService.getProjects();

    if (result.success && result.data != null) {
      _projects = result.data!;
    } else {
      // Si le service n'est pas disponible, afficher une liste vide
      _projects = [];
    }
    _state = ProjectsState.loaded;
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
