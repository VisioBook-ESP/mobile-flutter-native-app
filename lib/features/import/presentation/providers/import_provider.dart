import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:visiobook_mobile/config/environment.dart';
import 'package:visiobook_mobile/features/import/data/storage_service.dart';
import 'package:visiobook_mobile/features/import/domain/import_file.dart';

/// Etats possibles de l'import
enum ImportState { initial, selecting, selected, uploading, uploaded, error }

/// Provider pour gerer l'import de fichiers
class ImportProvider extends ChangeNotifier {
  final StorageService _storageService;

  ImportState _state = ImportState.initial;
  ImportFile? _selectedFile;
  UploadResult? _uploadResult;
  String? _error;
  double _uploadProgress = 0;

  ImportProvider({required StorageService storageService})
    : _storageService = storageService;

  // Getters
  ImportState get state => _state;
  ImportFile? get selectedFile => _selectedFile;
  UploadResult? get uploadResult => _uploadResult;
  String? get error => _error;
  double get uploadProgress => _uploadProgress;
  bool get isUploading => _state == ImportState.uploading;
  bool get hasFile => _selectedFile != null;

  /// Formats supportes
  static const List<String> supportedExtensions = [
    'pdf',
    'txt',
    'docx',
    'epub',
  ];
  static const int maxFileSize = 50 * 1024 * 1024; // 50 MB

  /// Ouvre le file picker et selectionne un fichier
  Future<void> pickFile() async {
    _state = ImportState.selecting;
    _error = null;
    notifyListeners();

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: supportedExtensions,
        withData: false,
        withReadStream: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        if (file.path == null) {
          _error = 'Impossible de lire le fichier';
          _state = ImportState.error;
          notifyListeners();
          return;
        }

        final extension = file.extension?.toLowerCase() ?? '';
        final fileType = ImportFileType.fromExtension(extension);

        _selectedFile = ImportFile(
          name: file.name,
          path: file.path!,
          type: fileType,
          sizeBytes: file.size,
          selectedAt: DateTime.now(),
        );

        // Validation
        if (!_selectedFile!.isValidFormat) {
          _error = 'Format non supporte. Utilisez PDF, TXT, DOCX ou EPUB.';
          _state = ImportState.error;
          notifyListeners();
          return;
        }

        if (!_selectedFile!.isValidSize) {
          _error = 'Fichier trop volumineux (max 50 MB)';
          _state = ImportState.error;
          notifyListeners();
          return;
        }

        _state = ImportState.selected;
        notifyListeners();
      } else {
        // User cancelled
        _state = ImportState.initial;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Erreur lors de la selection: $e';
      _state = ImportState.error;
      notifyListeners();
    }
  }

  /// Upload le fichier selectionne
  Future<bool> uploadFile() async {
    if (_selectedFile == null) {
      _error = 'Aucun fichier selectionne';
      _state = ImportState.error;
      notifyListeners();
      return false;
    }

    _state = ImportState.uploading;
    _uploadProgress = 0;
    _error = null;
    notifyListeners();

    // Mode mock: simuler l'upload
    if (EnvironmentConfig.useMockData) {
      await _mockUpload();
      return true;
    }

    final result = await _storageService.uploadFile(
      _selectedFile!,
      onProgress: (progress) {
        _uploadProgress = progress;
        notifyListeners();
      },
    );

    if (result.success && result.data != null) {
      _uploadResult = result.data;
      _uploadProgress = 1.0;
      _state = ImportState.uploaded;
      notifyListeners();
      return true;
    }

    _error = result.error;
    _state = ImportState.error;
    notifyListeners();
    return false;
  }

  /// Simulation d'upload pour le mode mock
  Future<void> _mockUpload() async {
    // Simuler progression
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 150));
      _uploadProgress = i / 10;
      notifyListeners();
    }

    // Generer un texte extrait fictif
    final mockText = _getMockExtractedText();

    _uploadResult = UploadResult.success(
      fileId: 'mock_file_${DateTime.now().millisecondsSinceEpoch}',
      fileUrl: 'https://storage.example.com/files/mock_file.pdf',
      extractedText: mockText,
      wordCount: mockText.split(' ').length,
    );
    _state = ImportState.uploaded;
    notifyListeners();
  }

  String _getMockExtractedText() {
    return '''Il etait une fois, dans un pays lointain, un petit prince qui vivait sur une planete a peine plus grande qu'une maison. Ce petit prince avait une fleur qu'il aimait plus que tout au monde, une rose unique et magnifique.

Chaque matin, il arrosait sa rose avec soin et la protegeait du vent avec un paravent. La rose etait vaniteuse et demandait beaucoup d'attention, mais le petit prince l'aimait tendrement.

Un jour, le petit prince decida de partir explorer d'autres planetes. Il visita plusieurs asteroides, chacun habite par un adulte etrange: un roi sans sujets, un vaniteux qui voulait etre admire, un buveur qui buvait pour oublier qu'il avait honte de boire, un businessman qui comptait les etoiles, un allumeur de reverbereset un geographe qui ne connaissait pas sa propre planete.

Finalement, le petit prince arriva sur Terre, ou il rencontra un renard qui lui enseigna le secret de l'amitie: "On ne voit bien qu'avec le coeur. L'essentiel est invisible pour les yeux."''';
  }

  /// Upload des images scannees (via camera)
  Future<bool> uploadScannedImages(List<String> imagePaths) async {
    if (imagePaths.isEmpty) {
      _error = 'Aucune image capturee';
      _state = ImportState.error;
      notifyListeners();
      return false;
    }

    _state = ImportState.uploading;
    _uploadProgress = 0;
    _error = null;
    notifyListeners();

    try {
      final file = File(imagePaths.first);
      final fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final fileSize = await file.length();

      _selectedFile = ImportFile(
        name: fileName,
        path: imagePaths.first,
        type: ImportFileType.unknown,
        sizeBytes: fileSize,
        selectedAt: DateTime.now(),
      );

      // Mode mock: simuler l'upload
      if (EnvironmentConfig.useMockData) {
        await _mockUpload();
        return true;
      }

      final result = await _storageService.uploadFile(
        _selectedFile!,
        onProgress: (progress) {
          _uploadProgress = progress;
          notifyListeners();
        },
      );

      if (result.success && result.data != null) {
        _uploadResult = result.data;
        _uploadProgress = 1.0;
        _state = ImportState.uploaded;
        notifyListeners();
        return true;
      }

      _error = result.error;
      _state = ImportState.error;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Erreur lors du traitement du scan: $e';
      _state = ImportState.error;
      notifyListeners();
      return false;
    }
  }

  /// Met a jour le texte extrait manuellement
  void updateExtractedText(String newText) {
    if (_uploadResult != null) {
      _uploadResult = UploadResult(
        fileId: _uploadResult!.fileId,
        fileUrl: _uploadResult!.fileUrl,
        extractedText: newText,
        wordCount: newText
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty)
            .length,
        success: _uploadResult!.success,
      );
      notifyListeners();
    }
  }

  /// Reset l'etat pour un nouvel import
  void reset() {
    _state = ImportState.initial;
    _selectedFile = null;
    _uploadResult = null;
    _error = null;
    _uploadProgress = 0;
    notifyListeners();
  }

  /// Clear l'erreur
  void clearError() {
    _error = null;
    if (_state == ImportState.error) {
      _state = _selectedFile != null
          ? ImportState.selected
          : ImportState.initial;
    }
    notifyListeners();
  }
}
