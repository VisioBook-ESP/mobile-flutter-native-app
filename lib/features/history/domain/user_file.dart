/// Represente un fichier uploade dans le folder de l'utilisateur
class UserFile {
  final String id;
  final String name;
  final String? extractedText;
  final int? wordCount;
  final String? fileType;
  final DateTime createdAt;

  UserFile({
    required this.id,
    required this.name,
    this.extractedText,
    this.wordCount,
    this.fileType,
    required this.createdAt,
  });

  /// Parse depuis la reponse API /folders/files
  /// Format: {fileId, fileName, fileType, chunks: [{content, wordCount}], metadata: {wordCount}, processedAt}
  factory UserFile.fromJson(Map<String, dynamic> json) {
    // Extraire le texte depuis les chunks
    String? extractedText;
    final chunks = json['chunks'] as List<dynamic>?;
    if (chunks != null && chunks.isNotEmpty) {
      final buffer = StringBuffer();
      for (final chunk in chunks) {
        if (chunk is Map && chunk['content'] != null) {
          if (buffer.isNotEmpty) buffer.write('\n');
          buffer.write(chunk['content']);
        }
      }
      extractedText = buffer.toString();
    }

    // Fallback: texte directement dans le json
    extractedText ??=
        json['extractedText'] as String? ?? json['text'] as String?;

    // Word count depuis metadata ou calcul
    int? wordCount;
    final metadata = json['metadata'] as Map<String, dynamic>?;
    if (metadata != null) {
      wordCount = metadata['wordCount'] as int?;
    }
    wordCount ??= json['wordCount'] as int? ?? _countWords(extractedText);

    // Date depuis processedAt ou createdAt
    final dateStr =
        json['processedAt'] as String? ??
        json['createdAt'] as String? ??
        json['created_at'] as String?;

    return UserFile(
      id: (json['fileId'] ?? json['id'] ?? '').toString(),
      name:
          json['fileName'] as String? ??
          json['name'] as String? ??
          json['filename'] as String? ??
          'Sans nom',
      extractedText: extractedText,
      wordCount: wordCount,
      fileType: json['fileType'] as String? ?? json['type'] as String?,
      createdAt: DateTime.tryParse(dateStr ?? '') ?? DateTime.now(),
    );
  }

  static int? _countWords(String? text) {
    if (text == null || text.isEmpty) return null;
    return text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }
}
