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

  String get flag {
    switch (this) {
      case AudioLanguage.french:
        return '🇫🇷';
      case AudioLanguage.english:
        return '🇬🇧';
      case AudioLanguage.spanish:
        return '🇪🇸';
      case AudioLanguage.german:
        return '🇩🇪';
    }
  }
}

/// Duree de la video
enum VideoDuration {
  short,
  medium,
  long,
  auto;

  String get label {
    switch (this) {
      case VideoDuration.short:
        return 'Courte';
      case VideoDuration.medium:
        return 'Moyenne';
      case VideoDuration.long:
        return 'Longue';
      case VideoDuration.auto:
        return 'Automatique';
    }
  }

  String get description {
    switch (this) {
      case VideoDuration.short:
        return '1-2 minutes';
      case VideoDuration.medium:
        return '3-5 minutes';
      case VideoDuration.long:
        return '6-10 minutes';
      case VideoDuration.auto:
        return 'Selon le texte';
    }
  }
}

/// Configuration complete d'un projet
class ProjectConfig {
  final VideoStyle style;
  final AudioLanguage language;
  final VideoDuration duration;

  const ProjectConfig({
    this.style = VideoStyle.realistic,
    this.language = AudioLanguage.french,
    this.duration = VideoDuration.auto,
  });

  ProjectConfig copyWith({
    VideoStyle? style,
    AudioLanguage? language,
    VideoDuration? duration,
  }) {
    return ProjectConfig(
      style: style ?? this.style,
      language: language ?? this.language,
      duration: duration ?? this.duration,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'style': style.name,
      'language': language.code,
      'duration': duration.name,
    };
  }
}
