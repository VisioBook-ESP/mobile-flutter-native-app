/// Validators pour les formulaires
class Validators {
  /// Valide un email
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email requis';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Email invalide';
    }

    return null;
  }

  /// Valide un mot de passe (min 8 chars, 1 maj, 1 chiffre)
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mot de passe requis';
    }

    if (value.length < 8) {
      return 'Minimum 8 caracteres';
    }

    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Au moins une majuscule';
    }

    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Au moins un chiffre';
    }

    return null;
  }

  /// Valide la confirmation du mot de passe
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Confirmation requise';
    }

    if (value != password) {
      return 'Les mots de passe ne correspondent pas';
    }

    return null;
  }

  /// Valide un prenom
  static String? firstName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Prenom requis';
    }

    if (value.length < 2) {
      return 'Minimum 2 caracteres';
    }

    if (value.length > 50) {
      return 'Maximum 50 caracteres';
    }

    return null;
  }

  /// Valide un champ requis
  static String? required(String? value, [String fieldName = 'Ce champ']) {
    if (value == null || value.isEmpty) {
      return '$fieldName est requis';
    }
    return null;
  }

  /// Valide une taille de fichier (en bytes)
  static String? fileSize(int sizeInBytes, {int maxSizeMB = 50}) {
    final maxSizeBytes = maxSizeMB * 1024 * 1024;
    if (sizeInBytes > maxSizeBytes) {
      return 'Fichier trop volumineux (max ${maxSizeMB}MB)';
    }
    return null;
  }

  /// Valide une extension de fichier
  static String? fileExtension(
    String fileName, {
    List<String> allowedExtensions = const ['pdf', 'txt', 'docx', 'epub'],
  }) {
    final extension = fileName.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(extension)) {
      return 'Format non supporte (${allowedExtensions.join(', ')})';
    }
    return null;
  }
}
