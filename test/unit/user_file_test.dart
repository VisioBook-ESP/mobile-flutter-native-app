import 'package:flutter_test/flutter_test.dart';
import 'package:visiobook_mobile/features/history/domain/user_file.dart';

void main() {
  group('UserFile.fromJson', () {
    test(
      'parses standard API response with fileId, fileName, fileType, chunks',
      () {
        final json = {
          'fileId': 'abc-123',
          'fileName': 'document.pdf',
          'fileType': 'pdf',
          'chunks': [
            {'content': 'Hello world', 'wordCount': 2},
            {'content': 'Second chunk', 'wordCount': 2},
          ],
          'metadata': {'wordCount': 4},
          'processedAt': '2025-01-15T10:30:00Z',
        };

        final file = UserFile.fromJson(json);

        expect(file.id, 'abc-123');
        expect(file.name, 'document.pdf');
        expect(file.fileType, 'pdf');
      },
    );

    test('extracts text from chunks correctly (joins with newline)', () {
      final json = {
        'fileId': 'abc-123',
        'fileName': 'doc.pdf',
        'chunks': [
          {'content': 'First paragraph'},
          {'content': 'Second paragraph'},
          {'content': 'Third paragraph'},
        ],
        'processedAt': '2025-01-15T10:30:00Z',
      };

      final file = UserFile.fromJson(json);

      expect(
        file.extractedText,
        'First paragraph\nSecond paragraph\nThird paragraph',
      );
    });

    test('falls back to extractedText field when no chunks', () {
      final json = {
        'fileId': 'abc-123',
        'fileName': 'doc.pdf',
        'extractedText': 'Some extracted text here',
        'processedAt': '2025-01-15T10:30:00Z',
      };

      final file = UserFile.fromJson(json);

      expect(file.extractedText, 'Some extracted text here');
    });

    test('falls back to text field when no extractedText', () {
      final json = {
        'fileId': 'abc-123',
        'fileName': 'doc.pdf',
        'text': 'Fallback text content',
        'processedAt': '2025-01-15T10:30:00Z',
      };

      final file = UserFile.fromJson(json);

      expect(file.extractedText, 'Fallback text content');
    });

    test('computes wordCount from metadata', () {
      final json = {
        'fileId': 'abc-123',
        'fileName': 'doc.pdf',
        'metadata': {'wordCount': 42},
        'processedAt': '2025-01-15T10:30:00Z',
      };

      final file = UserFile.fromJson(json);

      expect(file.wordCount, 42);
    });

    test('falls back to computed wordCount from text', () {
      final json = {
        'fileId': 'abc-123',
        'fileName': 'doc.pdf',
        'text': 'one two three four five',
        'processedAt': '2025-01-15T10:30:00Z',
      };

      final file = UserFile.fromJson(json);

      expect(file.wordCount, 5);
    });

    test('parses processedAt date', () {
      final json = {
        'fileId': 'abc-123',
        'fileName': 'doc.pdf',
        'processedAt': '2025-06-15T12:00:00Z',
      };

      final file = UserFile.fromJson(json);

      expect(file.createdAt, DateTime.utc(2025, 6, 15, 12, 0, 0));
    });

    test('falls back to createdAt date', () {
      final json = {
        'fileId': 'abc-123',
        'fileName': 'doc.pdf',
        'createdAt': '2025-03-20T08:00:00Z',
      };

      final file = UserFile.fromJson(json);

      expect(file.createdAt, DateTime.utc(2025, 3, 20, 8, 0, 0));
    });

    test('handles minimal JSON (missing optional fields)', () {
      final json = <String, dynamic>{
        'fileId': 'minimal-id',
        'fileName': 'minimal.txt',
      };

      final file = UserFile.fromJson(json);

      expect(file.id, 'minimal-id');
      expect(file.name, 'minimal.txt');
      expect(file.extractedText, isNull);
      expect(file.fileType, isNull);
      // wordCount is null when there is no text to count
      expect(file.wordCount, isNull);
      // createdAt falls back to DateTime.now() so just check it's recent
      expect(
        file.createdAt.difference(DateTime.now()).inSeconds.abs(),
        lessThan(5),
      );
    });
  });
}
