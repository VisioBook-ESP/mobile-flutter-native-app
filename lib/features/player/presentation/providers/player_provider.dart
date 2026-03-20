import 'package:flutter/foundation.dart';
import 'package:visiobook_mobile/features/player/data/player_service.dart';
import 'package:visiobook_mobile/features/player/domain/visiobook_reader_state.dart';

/// Provider pour le lecteur VisioBook (PageView snap vertical)
class PlayerProvider extends ChangeNotifier {
  final PlayerService _playerService;

  VisiobookData? _visioBook;
  bool _isLoading = false;
  String? _error;
  int _currentPanelIndex = 0;
  bool _hasReachedEnd = false;
  DateTime? _readingStartTime;

  PlayerProvider({required PlayerService playerService})
    : _playerService = playerService;

  // Getters
  VisiobookData? get visioBook => _visioBook;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPanelIndex => _currentPanelIndex;
  bool get hasReachedEnd => _hasReachedEnd;

  int get totalPanels => _visioBook?.totalPanels ?? 0;
  String get title => _visioBook?.title ?? '';

  List<VisiobookPanel> get allPanels => _visioBook?.allPanels ?? [];

  /// Panel actuellement visible
  VisiobookPanel? get currentPanel {
    final panels = allPanels;
    if (_currentPanelIndex >= panels.length) return null;
    return panels[_currentPanelIndex];
  }

  /// Progression de 0.0 a 1.0
  double get progress {
    if (totalPanels <= 1) return _hasReachedEnd ? 1.0 : 0.0;
    return (_currentPanelIndex + 1) / totalPanels;
  }

  /// Temps de lecture ecoule
  Duration get readingDuration {
    if (_readingStartTime == null) return Duration.zero;
    return DateTime.now().difference(_readingStartTime!);
  }

  /// Charge le VisioBook
  Future<void> loadVisioBook(String projectId) async {
    _isLoading = true;
    _error = null;
    _hasReachedEnd = false;
    _currentPanelIndex = 0;
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

  /// Appele par PageView.onPageChanged
  void onPageChanged(int index) {
    if (index == _currentPanelIndex) return;
    _currentPanelIndex = index;

    if (index == totalPanels - 1) {
      _hasReachedEnd = true;
    }

    notifyListeners();
  }

  /// Rejouer depuis le debut
  void replay() {
    _currentPanelIndex = 0;
    _hasReachedEnd = false;
    _readingStartTime = DateTime.now();
    notifyListeners();
  }

  /// Reset complet
  void reset() {
    _visioBook = null;
    _isLoading = false;
    _error = null;
    _currentPanelIndex = 0;
    _hasReachedEnd = false;
    _readingStartTime = null;
    notifyListeners();
  }
}
