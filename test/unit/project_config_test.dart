import 'package:flutter_test/flutter_test.dart';
import 'package:visiobook_mobile/features/project_detail/domain/project_config.dart';

void main() {
  group('VideoStyle', () {
    test('has all expected values', () {
      expect(VideoStyle.values.length, 4);
      expect(VideoStyle.values, contains(VideoStyle.realistic));
      expect(VideoStyle.values, contains(VideoStyle.cartoon));
      expect(VideoStyle.values, contains(VideoStyle.manga));
      expect(VideoStyle.values, contains(VideoStyle.watercolor));
    });

    test('label returns non-empty string for all values', () {
      for (final style in VideoStyle.values) {
        expect(style.label.isNotEmpty, isTrue);
      }
    });

    test('label returns correct values', () {
      expect(VideoStyle.realistic.label, 'Realiste');
      expect(VideoStyle.cartoon.label, 'Cartoon');
      expect(VideoStyle.manga.label, 'Manga');
      expect(VideoStyle.watercolor.label, 'Aquarelle');
    });

    test('description returns non-empty string for all values', () {
      for (final style in VideoStyle.values) {
        expect(style.description.isNotEmpty, isTrue);
      }
    });

    test('previewUrl returns valid URL for all values', () {
      for (final style in VideoStyle.values) {
        expect(style.previewUrl, startsWith('https://'));
      }
    });
  });

  group('AudioLanguage', () {
    test('has all expected values', () {
      expect(AudioLanguage.values.length, 4);
      expect(AudioLanguage.values, contains(AudioLanguage.french));
      expect(AudioLanguage.values, contains(AudioLanguage.english));
      expect(AudioLanguage.values, contains(AudioLanguage.spanish));
      expect(AudioLanguage.values, contains(AudioLanguage.german));
    });

    test('label returns non-empty string for all values', () {
      for (final lang in AudioLanguage.values) {
        expect(lang.label.isNotEmpty, isTrue);
      }
    });

    test('code returns 2-letter code for all values', () {
      for (final lang in AudioLanguage.values) {
        expect(lang.code.length, 2);
      }
    });

    test('code returns correct values', () {
      expect(AudioLanguage.french.code, 'fr');
      expect(AudioLanguage.english.code, 'en');
      expect(AudioLanguage.spanish.code, 'es');
      expect(AudioLanguage.german.code, 'de');
    });

    test('codeUpperCase returns uppercase code', () {
      expect(AudioLanguage.french.codeUpperCase, 'FR');
      expect(AudioLanguage.english.codeUpperCase, 'EN');
      expect(AudioLanguage.spanish.codeUpperCase, 'ES');
      expect(AudioLanguage.german.codeUpperCase, 'DE');
    });
  });

  group('VideoVibe', () {
    test('has all expected values', () {
      expect(VideoVibe.values.length, 7);
    });

    test('label returns non-empty string for all values', () {
      for (final vibe in VideoVibe.values) {
        expect(vibe.label.isNotEmpty, isTrue);
      }
    });

    test('label returns correct values', () {
      expect(VideoVibe.dramatic.label, 'Dramatique');
      expect(VideoVibe.calm.label, 'Calme');
      expect(VideoVibe.joyful.label, 'Joyeux');
      expect(VideoVibe.dark.label, 'Sombre');
      expect(VideoVibe.epic.label, 'Epique');
      expect(VideoVibe.romantic.label, 'Romantique');
      expect(VideoVibe.mysterious.label, 'Mysterieux');
    });
  });

  group('VideoFormat', () {
    test('has all expected values', () {
      expect(VideoFormat.values.length, 2);
      expect(VideoFormat.values, contains(VideoFormat.portrait));
      expect(VideoFormat.values, contains(VideoFormat.landscape));
    });

    test('label returns non-empty string for all values', () {
      for (final format in VideoFormat.values) {
        expect(format.label.isNotEmpty, isTrue);
      }
    });

    test('description returns aspect ratio string', () {
      expect(VideoFormat.portrait.description, '9:16');
      expect(VideoFormat.landscape.description, '16:9');
    });
  });

  group('ProjectConfig', () {
    test('default constructor has expected defaults', () {
      const config = ProjectConfig();
      expect(config.style, VideoStyle.realistic);
      expect(config.language, AudioLanguage.french);
      expect(config.vibe, VideoVibe.calm);
      expect(config.format, VideoFormat.portrait);
    });

    test('constructor accepts all parameters', () {
      const config = ProjectConfig(
        style: VideoStyle.manga,
        language: AudioLanguage.english,
        vibe: VideoVibe.epic,
        format: VideoFormat.landscape,
      );
      expect(config.style, VideoStyle.manga);
      expect(config.language, AudioLanguage.english);
      expect(config.vibe, VideoVibe.epic);
      expect(config.format, VideoFormat.landscape);
    });

    test('copyWith returns new instance with changed fields', () {
      const original = ProjectConfig();
      final copied = original.copyWith(style: VideoStyle.cartoon);

      expect(copied.style, VideoStyle.cartoon);
      expect(copied.language, original.language);
      expect(copied.vibe, original.vibe);
      expect(copied.format, original.format);
    });

    test('copyWith with no arguments returns equivalent instance', () {
      const original = ProjectConfig(
        style: VideoStyle.watercolor,
        language: AudioLanguage.german,
        vibe: VideoVibe.mysterious,
        format: VideoFormat.landscape,
      );
      final copied = original.copyWith();

      expect(copied.style, original.style);
      expect(copied.language, original.language);
      expect(copied.vibe, original.vibe);
      expect(copied.format, original.format);
    });

    test('copyWith can change all fields', () {
      const original = ProjectConfig();
      final copied = original.copyWith(
        style: VideoStyle.manga,
        language: AudioLanguage.spanish,
        vibe: VideoVibe.dark,
        format: VideoFormat.landscape,
      );

      expect(copied.style, VideoStyle.manga);
      expect(copied.language, AudioLanguage.spanish);
      expect(copied.vibe, VideoVibe.dark);
      expect(copied.format, VideoFormat.landscape);
    });

    test('toJson returns correct map', () {
      const config = ProjectConfig(
        style: VideoStyle.cartoon,
        language: AudioLanguage.english,
        vibe: VideoVibe.joyful,
        format: VideoFormat.landscape,
      );

      final json = config.toJson();

      expect(json['style'], 'cartoon');
      expect(json['language'], 'en');
      expect(json['vibe'], 'joyful');
      expect(json['format'], 'landscape');
    });

    test('toJson default config returns correct map', () {
      const config = ProjectConfig();
      final json = config.toJson();

      expect(json['style'], 'realistic');
      expect(json['language'], 'fr');
      expect(json['vibe'], 'calm');
      expect(json['format'], 'portrait');
    });

    test('toJson has exactly 4 keys', () {
      const config = ProjectConfig();
      final json = config.toJson();
      expect(json.keys.length, 4);
    });
  });
}
