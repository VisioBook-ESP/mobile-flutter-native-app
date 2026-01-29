/// Types de fichiers supportes pour l'import
enum ImportFileType {
  pdf,
  txt,
  docx,
  epub,
  unknown;

  static ImportFileType fromExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return ImportFileType.pdf;
      case 'txt':
        return ImportFileType.txt;
      case 'docx':
        return ImportFileType.docx;
      case 'epub':
        return ImportFileType.epub;
      default:
        return ImportFileType.unknown;
    }
  }

  String get label {
    switch (this) {
      case ImportFileType.pdf:
        return 'PDF';
      case ImportFileType.txt:
        return 'Texte';
      case ImportFileType.docx:
        return 'Word';
      case ImportFileType.epub:
        return 'EPUB';
      case ImportFileType.unknown:
        return 'Inconnu';
    }
  }
}

/// Represente un fichier importe
class ImportFile {
  final String name;
  final String path;
  final ImportFileType type;
  final int sizeBytes;
  final DateTime selectedAt;

  ImportFile({
    required this.name,
    required this.path,
    required this.type,
    required this.sizeBytes,
    required this.selectedAt,
  });

  /// Taille formatee (KB, MB)
  String get formattedSize {
    if (sizeBytes < 1024) {
      return '$sizeBytes B';
    } else if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Extension du fichier
  String get extension => name.split('.').last.toLowerCase();

  /// Validation: fichier < 50MB
  bool get isValidSize => sizeBytes <= 50 * 1024 * 1024;

  /// Validation: format supporte
  bool get isValidFormat => type != ImportFileType.unknown;
}

/// Resultat d'un upload
class UploadResult {
  final String? fileId;
  final String? fileUrl;
  final String? extractedText;
  final int? wordCount;
  final String? error;
  final bool success;

  UploadResult({
    this.fileId,
    this.fileUrl,
    this.extractedText,
    this.wordCount,
    this.error,
    this.success = false,
  });

  factory UploadResult.success({
    required String fileId,
    required String fileUrl,
    String? extractedText,
    int? wordCount,
  }) {
    return UploadResult(
      fileId: fileId,
      fileUrl: fileUrl,
      extractedText: extractedText,
      wordCount: wordCount,
      success: true,
    );
  }

  factory UploadResult.failure(String error) {
    return UploadResult(error: error, success: false);
  }
}
