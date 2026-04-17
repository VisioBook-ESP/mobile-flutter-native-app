import 'package:flutter_test/flutter_test.dart';
import 'package:visiobook_mobile/features/import/domain/import_file.dart';

void main() {
  group('ImportFileType', () {
    test('fromExtension for all types', () {
      expect(ImportFileType.fromExtension('pdf'), ImportFileType.pdf);
      expect(ImportFileType.fromExtension('txt'), ImportFileType.txt);
      expect(ImportFileType.fromExtension('docx'), ImportFileType.docx);
      expect(ImportFileType.fromExtension('epub'), ImportFileType.epub);
      expect(ImportFileType.fromExtension('jpg'), ImportFileType.jpeg);
      expect(ImportFileType.fromExtension('jpeg'), ImportFileType.jpeg);
      expect(ImportFileType.fromExtension('png'), ImportFileType.png);
      expect(ImportFileType.fromExtension('gif'), ImportFileType.gif);
    });

    test('fromExtension case insensitive', () {
      expect(ImportFileType.fromExtension('PDF'), ImportFileType.pdf);
      expect(ImportFileType.fromExtension('Txt'), ImportFileType.txt);
      expect(ImportFileType.fromExtension('DOCX'), ImportFileType.docx);
      expect(ImportFileType.fromExtension('JPG'), ImportFileType.jpeg);
      expect(ImportFileType.fromExtension('Png'), ImportFileType.png);
    });

    test('fromExtension unknown returns unknown', () {
      expect(ImportFileType.fromExtension('mp4'), ImportFileType.unknown);
      expect(ImportFileType.fromExtension('html'), ImportFileType.unknown);
      expect(ImportFileType.fromExtension(''), ImportFileType.unknown);
      expect(ImportFileType.fromExtension('xyz'), ImportFileType.unknown);
    });

    test('label returns correct labels for each type', () {
      expect(ImportFileType.pdf.label, 'PDF');
      expect(ImportFileType.txt.label, 'Texte');
      expect(ImportFileType.docx.label, 'Word');
      expect(ImportFileType.epub.label, 'EPUB');
      expect(ImportFileType.jpeg.label, 'JPEG');
      expect(ImportFileType.png.label, 'PNG');
      expect(ImportFileType.gif.label, 'GIF');
      expect(ImportFileType.unknown.label, 'Inconnu');
    });

    test('mimeType returns correct MIME for each type', () {
      expect(ImportFileType.pdf.mimeType, 'application/pdf');
      expect(ImportFileType.txt.mimeType, 'text/plain');
      expect(
        ImportFileType.docx.mimeType,
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      );
      expect(ImportFileType.epub.mimeType, 'application/epub+zip');
      expect(ImportFileType.jpeg.mimeType, 'image/jpeg');
      expect(ImportFileType.png.mimeType, 'image/png');
      expect(ImportFileType.gif.mimeType, 'image/gif');
    });

    test('mimeType returns null for unknown', () {
      expect(ImportFileType.unknown.mimeType, isNull);
    });

    test('isImage true for jpeg/png/gif, false for others', () {
      expect(ImportFileType.jpeg.isImage, isTrue);
      expect(ImportFileType.png.isImage, isTrue);
      expect(ImportFileType.gif.isImage, isTrue);
      expect(ImportFileType.pdf.isImage, isFalse);
      expect(ImportFileType.txt.isImage, isFalse);
      expect(ImportFileType.docx.isImage, isFalse);
      expect(ImportFileType.epub.isImage, isFalse);
      expect(ImportFileType.unknown.isImage, isFalse);
    });
  });

  group('ImportFile', () {
    ImportFile createFile({
      String name = 'test.pdf',
      int sizeBytes = 1024,
      ImportFileType type = ImportFileType.pdf,
    }) {
      return ImportFile(
        name: name,
        path: '/path/to/$name',
        type: type,
        sizeBytes: sizeBytes,
        selectedAt: DateTime(2026, 1, 1),
      );
    }

    test('formattedSize returns correct format (B, KB, MB)', () {
      expect(createFile(sizeBytes: 500).formattedSize, '500 B');
      expect(createFile(sizeBytes: 1023).formattedSize, '1023 B');
      expect(createFile(sizeBytes: 1024).formattedSize, '1.0 KB');
      expect(createFile(sizeBytes: 2048).formattedSize, '2.0 KB');
      expect(createFile(sizeBytes: 1536).formattedSize, '1.5 KB');
      expect(createFile(sizeBytes: 1048576).formattedSize, '1.0 MB');
      expect(createFile(sizeBytes: 5242880).formattedSize, '5.0 MB');
    });

    test('extension extracts correctly', () {
      expect(createFile(name: 'document.pdf').extension, 'pdf');
      expect(createFile(name: 'photo.PNG').extension, 'png');
      expect(createFile(name: 'archive.tar.gz').extension, 'gz');
      expect(createFile(name: 'file.TXT').extension, 'txt');
    });

    test('isValidSize for files under and over 50MB', () {
      // 50 MB exactly should be valid
      expect(createFile(sizeBytes: 50 * 1024 * 1024).isValidSize, isTrue);
      // Under 50 MB
      expect(createFile(sizeBytes: 1024).isValidSize, isTrue);
      // Over 50 MB
      expect(createFile(sizeBytes: 50 * 1024 * 1024 + 1).isValidSize, isFalse);
    });

    test('isValidFormat for known and unknown types', () {
      expect(createFile(type: ImportFileType.pdf).isValidFormat, isTrue);
      expect(createFile(type: ImportFileType.txt).isValidFormat, isTrue);
      expect(createFile(type: ImportFileType.docx).isValidFormat, isTrue);
      expect(createFile(type: ImportFileType.jpeg).isValidFormat, isTrue);
      expect(createFile(type: ImportFileType.unknown).isValidFormat, isFalse);
    });
  });

  group('UploadResult', () {
    test('success factory creates successful result', () {
      final result = UploadResult.success(
        fileId: 'abc-123',
        fileUrl: 'https://example.com/file.pdf',
        extractedText: 'Hello world',
        wordCount: 2,
      );

      expect(result.success, isTrue);
      expect(result.fileId, 'abc-123');
      expect(result.fileUrl, 'https://example.com/file.pdf');
      expect(result.extractedText, 'Hello world');
      expect(result.wordCount, 2);
      expect(result.error, isNull);
    });

    test('failure factory creates error result', () {
      final result = UploadResult.failure('Upload failed');

      expect(result.success, isFalse);
      expect(result.error, 'Upload failed');
      expect(result.fileId, isNull);
      expect(result.fileUrl, isNull);
      expect(result.extractedText, isNull);
      expect(result.wordCount, isNull);
    });
  });
}
