import 'package:flutter_test/flutter_test.dart';
import 'package:visiobook_mobile/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('returns error for null', () {
      expect(Validators.email(null), 'Email requis');
    });

    test('returns error for empty string', () {
      expect(Validators.email(''), 'Email requis');
    });

    test('returns error for invalid email', () {
      expect(Validators.email('notanemail'), 'Email invalide');
      expect(Validators.email('missing@domain'), 'Email invalide');
      expect(Validators.email('@nodomain.com'), 'Email invalide');
      expect(Validators.email('spaces @mail.com'), 'Email invalide');
    });

    test('returns null for valid email', () {
      expect(Validators.email('test@example.com'), isNull);
      expect(Validators.email('user.name+tag@domain.co'), isNull);
      expect(Validators.email('a@b.cd'), isNull);
    });
  });

  group('Validators.password', () {
    test('returns error for null', () {
      expect(Validators.password(null), 'Mot de passe requis');
    });

    test('returns error for empty string', () {
      expect(Validators.password(''), 'Mot de passe requis');
    });

    test('returns error for short password', () {
      expect(Validators.password('Ab1'), 'Minimum 8 caractères');
      expect(Validators.password('Abcdef1'), 'Minimum 8 caractères');
    });

    test('returns error for missing uppercase', () {
      expect(Validators.password('abcdefg1'), 'Au moins une majuscule');
    });

    test('returns error for missing digit', () {
      expect(Validators.password('Abcdefgh'), 'Au moins un chiffre');
    });

    test('returns null for valid password', () {
      expect(Validators.password('Abcdefg1'), isNull);
      expect(Validators.password('MyP@ss12'), isNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('returns error for null', () {
      expect(
        Validators.confirmPassword(null, 'password'),
        'Confirmation requise',
      );
    });

    test('returns error for empty string', () {
      expect(
        Validators.confirmPassword('', 'password'),
        'Confirmation requise',
      );
    });

    test('returns error when passwords do not match', () {
      expect(
        Validators.confirmPassword('different', 'password'),
        'Les mots de passe ne correspondent pas',
      );
    });

    test('returns null when passwords match', () {
      expect(Validators.confirmPassword('password', 'password'), isNull);
    });
  });

  group('Validators.firstName', () {
    test('returns error for null', () {
      expect(Validators.firstName(null), 'Prénom requis');
    });

    test('returns error for empty string', () {
      expect(Validators.firstName(''), 'Prénom requis');
    });

    test('returns error for too short', () {
      expect(Validators.firstName('A'), 'Minimum 2 caractères');
    });

    test('returns error for too long', () {
      expect(Validators.firstName('A' * 51), 'Maximum 50 caractères');
    });

    test('returns null for valid first name', () {
      expect(Validators.firstName('Jean'), isNull);
      expect(Validators.firstName('AB'), isNull);
    });
  });

  group('Validators.lastName', () {
    test('returns error for null', () {
      expect(Validators.lastName(null), 'Nom requis');
    });

    test('returns error for empty string', () {
      expect(Validators.lastName(''), 'Nom requis');
    });

    test('returns error for too short', () {
      expect(Validators.lastName('A'), 'Minimum 2 caractères');
    });

    test('returns error for too long', () {
      expect(Validators.lastName('A' * 51), 'Maximum 50 caractères');
    });

    test('returns null for valid last name', () {
      expect(Validators.lastName('Dupont'), isNull);
    });
  });

  group('Validators.username', () {
    test('returns error for null', () {
      expect(Validators.username(null), "Nom d'utilisateur requis");
    });

    test('returns error for empty string', () {
      expect(Validators.username(''), "Nom d'utilisateur requis");
    });

    test('returns error for too short', () {
      expect(Validators.username('ab'), 'Minimum 3 caractères');
    });

    test('returns error for too long', () {
      expect(Validators.username('a' * 31), 'Maximum 30 caractères');
    });

    test('returns error for invalid characters', () {
      expect(
        Validators.username('user name'),
        'Lettres, chiffres et underscores uniquement',
      );
      expect(
        Validators.username('user@name'),
        'Lettres, chiffres et underscores uniquement',
      );
      expect(
        Validators.username('user-name'),
        'Lettres, chiffres et underscores uniquement',
      );
    });

    test('returns null for valid username', () {
      expect(Validators.username('abc'), isNull);
      expect(Validators.username('user_123'), isNull);
      expect(Validators.username('JohnDoe'), isNull);
    });
  });

  group('Validators.required', () {
    test('returns error for null', () {
      expect(Validators.required(null), 'Ce champ est requis');
    });

    test('returns error for empty string', () {
      expect(Validators.required(''), 'Ce champ est requis');
    });

    test('returns error with custom field name', () {
      expect(Validators.required(null, 'Titre'), 'Titre est requis');
    });

    test('returns null for non-empty value', () {
      expect(Validators.required('something'), isNull);
    });
  });

  group('Validators.fileSize', () {
    test('returns null for file within limit', () {
      expect(Validators.fileSize(1024), isNull);
      expect(Validators.fileSize(50 * 1024 * 1024), isNull);
    });

    test('returns error for file exceeding default 50MB limit', () {
      expect(
        Validators.fileSize(51 * 1024 * 1024),
        'Fichier trop volumineux (max 50MB)',
      );
    });

    test('returns error for file exceeding custom limit', () {
      expect(
        Validators.fileSize(11 * 1024 * 1024, maxSizeMB: 10),
        'Fichier trop volumineux (max 10MB)',
      );
    });

    test('returns null for file within custom limit', () {
      expect(Validators.fileSize(5 * 1024 * 1024, maxSizeMB: 10), isNull);
    });
  });

  group('Validators.fileExtension', () {
    test('returns null for allowed extension', () {
      expect(Validators.fileExtension('file.pdf'), isNull);
      expect(Validators.fileExtension('file.txt'), isNull);
      expect(Validators.fileExtension('file.docx'), isNull);
      expect(Validators.fileExtension('file.epub'), isNull);
    });

    test('returns error for disallowed extension', () {
      expect(
        Validators.fileExtension('file.exe'),
        'Format non supporté (pdf, txt, docx, epub)',
      );
    });

    test('returns null for custom allowed extensions', () {
      expect(
        Validators.fileExtension(
          'image.png',
          allowedExtensions: ['png', 'jpg'],
        ),
        isNull,
      );
    });

    test('returns error for extension not in custom list', () {
      expect(
        Validators.fileExtension('file.pdf', allowedExtensions: ['png', 'jpg']),
        'Format non supporté (png, jpg)',
      );
    });

    test('is case-insensitive for extension', () {
      expect(Validators.fileExtension('file.PDF'), isNull);
      expect(Validators.fileExtension('file.Txt'), isNull);
    });
  });
}
