import 'package:flutter/foundation.dart';
import 'package:visiobook_mobile/features/player/data/player_service.dart';
import 'package:visiobook_mobile/features/player/domain/visiobook_reader_state.dart';

/// Provider pour le lecteur VisioBook style Webtoon
class PlayerProvider extends ChangeNotifier {
  final PlayerService _playerService;

  VisioBookData? _visioBook;
  bool _isLoading = false;
  String? _error;
  int _currentSceneIndex = 0;
  bool _showSubtitles = true;
  bool _isMuted = false;
  bool _isPaused = false;
  bool _hasReachedEnd = false;
  DateTime? _readingStartTime;

  PlayerProvider({required PlayerService playerService})
    : _playerService = playerService;

  // Getters
  VisioBookData? get visioBook => _visioBook;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentSceneIndex => _currentSceneIndex;
  bool get showSubtitles => _showSubtitles;
  bool get isMuted => _isMuted;
  bool get isPaused => _isPaused;
  bool get hasReachedEnd => _hasReachedEnd;

  int get totalScenes => _visioBook?.sceneCount ?? 0;
  String get title => _visioBook?.title ?? '';

  /// Progression de 0.0 a 1.0 basee sur la scene courante
  double get progress {
    if (totalScenes <= 1) return _hasReachedEnd ? 1.0 : 0.0;
    return (_currentSceneIndex + 1) / totalScenes;
  }

  /// Scene courante
  VisioBookScene? get currentScene {
    if (_visioBook == null || _currentSceneIndex >= totalScenes) return null;
    return _visioBook!.scenes[_currentSceneIndex];
  }

  /// Temps de lecture ecoule
  Duration get readingDuration {
    if (_readingStartTime == null) return Duration.zero;
    return DateTime.now().difference(_readingStartTime!);
  }

  /// Charge les scenes du VisioBook
  Future<void> loadVisioBook(String projectId) async {
    _isLoading = true;
    _error = null;
    _hasReachedEnd = false;
    _currentSceneIndex = 0;
    notifyListeners();

    final result = await _playerService.getVisioBook(projectId);

    if (result.success && result.data != null) {
      _visioBook = result.data;
      _readingStartTime = DateTime.now();
    } else {
      _error = result.error ?? 'Impossible de charger le VisioBook';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Met a jour la scene visible (appelee par le scroll)
  void updateCurrentScene(int index) {
    if (index == _currentSceneIndex) return;
    if (index < 0 || index >= totalScenes) return;
    _currentSceneIndex = index;

    // Detecter la fin
    if (index == totalScenes - 1) {
      _hasReachedEnd = true;
    }

    notifyListeners();
  }

  /// Toggle sous-titres
  void toggleSubtitles() {
    _showSubtitles = !_showSubtitles;
    notifyListeners();
  }

  /// Toggle mute
  void toggleMute() {
    _isMuted = !_isMuted;
    notifyListeners();
  }

  /// Toggle pause (arrete audio/video)
  void togglePause() {
    _isPaused = !_isPaused;
    notifyListeners();
  }

  /// Aller a une scene specifique
  void goToScene(int index) {
    if (index < 0 || index >= totalScenes) return;
    _currentSceneIndex = index;
    _hasReachedEnd = index == totalScenes - 1;
    notifyListeners();
  }

  /// Rejouer depuis le debut
  void replay() {
    _currentSceneIndex = 0;
    _hasReachedEnd = false;
    _isPaused = false;
    _readingStartTime = DateTime.now();
    notifyListeners();
  }

  /// Reset complet
  void reset() {
    _visioBook = null;
    _isLoading = false;
    _error = null;
    _currentSceneIndex = 0;
    _showSubtitles = true;
    _isMuted = false;
    _isPaused = false;
    _hasReachedEnd = false;
    _readingStartTime = null;
    notifyListeners();
  }
}
