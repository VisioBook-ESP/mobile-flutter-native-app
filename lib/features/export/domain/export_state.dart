/// Statut du processus d'export
enum ExportStatus {
  /// Aucune action en cours
  idle,

  /// Telechargement en cours
  downloading,

  /// Telechargement termine avec succes
  completed,

  /// Telechargement echoue
  failed,
}

/// Etat du telechargement (utilise par le widget ExportShareSheet)
enum ExportDownloadState {
  /// Aucun telechargement en cours
  idle,

  /// Telechargement en cours
  downloading,

  /// Telechargement termine avec succes
  completed,

  /// Telechargement echoue
  failed,
}

/// Qualite d'export de la video
enum ExportQuality {
  /// Basse qualite (480p)
  low,

  /// Qualite moyenne (720p)
  medium,

  /// Haute qualite (1080p)
  high;

  /// Label affiche a l'utilisateur
  String get label {
    switch (this) {
      case ExportQuality.low:
        return '480p';
      case ExportQuality.medium:
        return '720p';
      case ExportQuality.high:
        return '1080p';
    }
  }

  /// Description detaillee
  String get description {
    switch (this) {
      case ExportQuality.low:
        return 'Basse qualite - fichier leger';
      case ExportQuality.medium:
        return 'Qualite moyenne - bon compromis';
      case ExportQuality.high:
        return 'Haute qualite - meilleur rendu';
    }
  }

  /// Cree un ExportQuality a partir d'un label string
  static ExportQuality fromLabel(String label) {
    switch (label) {
      case '480p':
        return ExportQuality.low;
      case '720p':
        return ExportQuality.medium;
      case '1080p':
        return ExportQuality.high;
      default:
        return ExportQuality.high;
    }
  }
}
