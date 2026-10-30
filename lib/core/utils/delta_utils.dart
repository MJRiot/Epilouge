import 'dart:convert';

/// Converts a Quill Delta JSON string (as stored in [Note.content])
/// into readable plain text for previews and list views.
///
/// Example:
///   `[{"insert":"Hello dear\n"}]` --> `Hello dear`
///
/// - Embeds (e.g. images) are replaced with a readable placeholder like `[image]`.
/// - If [content] is not valid Delta JSON it is returned trimmed and unchanged,
///   so legacy plain-text notes keep working.
String deltaToPlainText(String content) {
  if (content.trim().isEmpty) return '';

  Object? decoded;
  try {
    decoded = jsonDecode(content);
  } on FormatException {
    // Not JSON at all -> assume it is already plain text.
    return content.trim();
  }

  if (decoded is! List) return content.trim();

  final buffer = StringBuffer();
  for (final op in decoded) {
    if (op is! Map || !op.containsKey('insert')) continue;
    final insert = op['insert'];
    if (insert is String) {
      buffer.write(insert);
    } else if (insert is Map) {
      // Embed (image, video, ...) - show a readable placeholder.
      final kind = insert.keys.isNotEmpty ? insert.keys.first : 'content';
      buffer.write('[$kind]');
    }
  }

  // Collapse 3+ consecutive newlines into a single blank line, then trim.
  return buffer.toString().replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
}
