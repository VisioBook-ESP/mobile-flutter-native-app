import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:visiobook_mobile/features/export/data/export_service.dart';
import 'package:visiobook_mobile/features/export/domain/export_state.dart';

class ExportProvider extends ChangeNotifier {
  final ExportService _exportService;

  ExportStatus _status = ExportStatus.idle;
  double _downloadProgress = 0.0;
  String? _downloadedFilePath;
  String? _shareLink;
  String? _error;
  ExportQuality _selectedQuality = ExportQuality.high;

  ExportProvider({required ExportService exportService})
    : _exportService = exportService;

  // Getters
  ExportStatus get status => _status;
  double get downloadProgress => _downloadProgress;
  String? get downloadedFilePath => _downloadedFilePath;
  String? get shareLink => _shareLink;
  String? get error => _error;
  ExportQuality get selectedQuality => _selectedQuality;
  bool get isDownloading => _status == ExportStatus.downloading;
  bool get isCompleted => _status == ExportStatus.completed;

  /// Etat du telechargement (utilise par ExportShareSheet)
  ExportDownloadState get downloadState {
    switch (_status) {
      case ExportStatus.idle:
        return ExportDownloadState.idle;
      case ExportStatus.downloading:
        return ExportDownloadState.downloading;
      case ExportStatus.completed:
        return ExportDownloadState.completed;
      case ExportStatus.failed:
        return ExportDownloadState.failed;
    }
  }

  /// Erreur de telechargement (alias pour error, utilise par ExportShareSheet)
  String? get downloadError => _error;

  /// Change la qualite selectionnee (accepte ExportQuality ou String label)
  void setQuality(dynamic quality) {
    if (quality is ExportQuality) {
      _selectedQuality = quality;
    } else if (quality is String) {
      _selectedQuality = ExportQuality.fromLabel(quality);
    }
    notifyListeners();
  }

  /// Lance le telechargement avec qualite optionnelle
  Future<void> startDownload(String projectId, [dynamic quality]) async {
    if (quality != null) {
      if (quality is ExportQuality) {
        _selectedQuality = quality;
      } else if (quality is String) {
        _selectedQuality = ExportQuality.fromLabel(quality);
      }
    }
    await downloadVideo(projectId);
  }

  /// Lance le telechargement
  Future<void> downloadVideo(String projectId) async {
    _status = ExportStatus.downloading;
    _downloadProgress = 0.0;
    _error = null;
    notifyListeners();

    final savePath = await _buildSavePath(projectId);

    final result = await _exportService.downloadVideo(
      projectId: projectId,
      savePath: savePath,
      quality: _selectedQuality,
      onProgress: (progress) {
        _downloadProgress = progress;
        notifyListeners();
      },
    );

    if (result.success) {
      _status = ExportStatus.completed;
      _downloadedFilePath = result.data;
    } else {
      _status = ExportStatus.failed;
      _error = result.error;
    }
    notifyListeners();
  }

  /// Genere et copie le lien de partage
  Future<void> generateAndCopyShareLink(String projectId) async {
    _error = null;
    notifyListeners();

    final result = await _exportService.generateShareLink(projectId);

    if (result.success && result.data != null) {
      _shareLink = result.data;
      await Clipboard.setData(ClipboardData(text: result.data!));
      notifyListeners();
    } else {
      _error = result.error;
      notifyListeners();
    }
  }

  /// Lance le share sheet natif
  Future<void> shareNative(String projectId, String title) async {
    // If we already have a share link, use it. Otherwise generate one.
    String? link = _shareLink;
    if (link == null) {
      final result = await _exportService.generateShareLink(projectId);
      if (result.success && result.data != null) {
        link = result.data;
        _shareLink = link;
        notifyListeners();
      } else {
        _error = result.error;
        notifyListeners();
        return;
      }
    }

    await SharePlus.instance.share(
      ShareParams(text: 'Decouvre mon VisioBook "$title" !\n$link'),
    );
  }

  /// Construit le chemin de sauvegarde selon la plateforme
  Future<String> _buildSavePath(String projectId) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'VisioBook_${projectId}_$timestamp.mp4';
    try {
      final dir = await getApplicationDocumentsDirectory();
      return '${dir.path}/$fileName';
    } catch (_) {
      // Fallback (tests ou plateforme non supportee)
      return '/tmp/$fileName';
    }
  }

  /// Reset
  void reset() {
    _status = ExportStatus.idle;
    _downloadProgress = 0.0;
    _downloadedFilePath = null;
    _shareLink = null;
    _error = null;
    _selectedQuality = ExportQuality.high;
    notifyListeners();
  }
}
