/// Style graphique disponible pour la generation
enum VideoStyle {
  realistic,
  cartoon,
  manga,
  watercolor;

  String get label {
    switch (this) {
      case VideoStyle.realistic:
        return 'Realiste';
      case VideoStyle.cartoon:
        return 'Cartoon';
      case VideoStyle.manga:
        return 'Manga';
      case VideoStyle.watercolor:
        return 'Aquarelle';
    }
  }

  String get description {
    switch (this) {
      case VideoStyle.realistic:
        return 'Images photoréalistes';
      case VideoStyle.cartoon:
        return 'Style dessin animé';
      case VideoStyle.manga:
        return 'Style manga japonais';
      case VideoStyle.watercolor:
        return 'Effet peinture aquarelle';
    }
  }

  String get previewUrl {
    switch (this) {
      case VideoStyle.realistic:
        return 'https://picsum.photos/seed/realistic/200/150';
      case VideoStyle.cartoon:
        return 'https://picsum.photos/seed/cartoon/200/150';
      case VideoStyle.manga:
        return 'https://picsum.photos/seed/manga/200/150';
      case VideoStyle.watercolor:
        return 'https://picsum.photos/seed/watercolor/200/150';
    }
  }
}

/// Langue audio disponible
enum AudioLanguage {
  french,
  english,
  spanish,
  german;

  String get label {
    switch (this) {
      case AudioLanguage.french:
        return 'Francais';
      case AudioLanguage.english:
        return 'English';
      case AudioLanguage.spanish:
        return 'Espanol';
      case AudioLanguage.german:
        return 'Deutsch';
    }
  }

  String get code {
    switch (this) {
      case AudioLanguage.french:
        return 'fr';
      case AudioLanguage.english:
        return 'en';
      case AudioLanguage.spanish:
        return 'es';
      case AudioLanguage.german:
        return 'de';
    }
  }

  String get codeUpperCase {
    return code.toUpperCase();
  }
}

/// Ambiance / vibe de la video
enum VideoVibe {
  dramatic,
  calm,
  joyful,
  dark,
  epic,
  romantic,
  mysterious;

  String get label {
    switch (this) {
      case VideoVibe.dramatic:
        return 'Dramatique';
      case VideoVibe.calm:
        return 'Calme';
      case VideoVibe.joyful:
        return 'Joyeux';
      case VideoVibe.dark:
        return 'Sombre';
      case VideoVibe.epic:
        return 'Epique';
      case VideoVibe.romantic:
        return 'Romantique';
      case VideoVibe.mysterious:
        return 'Mysterieux';
    }
  }
}

/// Format video
enum VideoFormat {
  portrait,
  landscape;

  String get label {
    switch (this) {
      case VideoFormat.portrait:
        return 'Portrait';
      case VideoFormat.landscape:
        return 'Paysage';
    }
  }

  String get description {
    switch (this) {
      case VideoFormat.portrait:
        return '9:16';
      case VideoFormat.landscape:
        return '16:9';
    }
  }
}

/// Configuration complete d'un projet
class ProjectConfig {
  final VideoStyle style;
  final AudioLanguage language;
  final VideoVibe vibe;
  final VideoFormat format;

  const ProjectConfig({
    this.style = VideoStyle.realistic,
    this.language = AudioLanguage.french,
    this.vibe = VideoVibe.calm,
    this.format = VideoFormat.portrait,
  });

  ProjectConfig copyWith({
    VideoStyle? style,
    AudioLanguage? language,
    VideoVibe? vibe,
    VideoFormat? format,
  }) {
    return ProjectConfig(
      style: style ?? this.style,
      language: language ?? this.language,
      vibe: vibe ?? this.vibe,
      format: format ?? this.format,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'style': style.name,
      'language': language.code,
      'vibe': vibe.name,
      'format': format.name,
    };
  }
}
