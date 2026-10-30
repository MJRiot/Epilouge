import 'dart:convert';

class Note {
  /// Lets `copyWith` distinguish "argument not provided" from "set to null"
  /// (needed to CLEAR a reminder by passing `reminderAt: null`).
  static const Object _noChange = Object();

  final String id;
  final String title;
  final String content;
  final String category;
  final int color;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> imagePaths;

  /// Whether the note is pinned to the top of the list.
  final bool pinned;

  /// Optional reminder date/time for this note (null = no reminder set).
  final DateTime? reminderAt;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
    this.imagePaths = const [],
    this.pinned = false,
    this.reminderAt,
  });

  Note copyWith({
    String? id,
    String? title,
    String? content,
    String? category,
    int? color,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? imagePaths,
    bool? pinned,
    // Object? instead of DateTime? so we can tell "clear the reminder"
    // (explicit null) apart from "leave it as is" (parameter omitted).
    Object? reminderAt = _noChange,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imagePaths: imagePaths ?? this.imagePaths,
      pinned: pinned ?? this.pinned,
      reminderAt: identical(reminderAt, _noChange)
          ? this.reminderAt
          : reminderAt as DateTime?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'color': color,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'imagePaths': imagePaths.isEmpty ? null : jsonEncode(imagePaths),
      // sqflite has no bool type -> store as 0/1 integer.
      'pinned': pinned ? 1 : 0,
      // Nullable timestamp; null is stored as NULL (no reminder).
      'reminderAt': reminderAt?.millisecondsSinceEpoch,
    };
  }

  static Note fromMap(Map<String, Object?> map) {
    List<String> images = [];
    if (map['imagePaths'] != null) {
      try {
        final decoded = jsonDecode(map['imagePaths'] as String);
        if (decoded is List) {
          images = decoded.map((e) => e.toString()).toList();
        }
      } catch (e) {
        images = [];
      }
    }
    return Note(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      category: map['category'] as String,
      color: map['color'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      imagePaths: images,
      // ?? falls back for rows created before these columns existed.
      pinned: (map['pinned'] as int? ?? 0) != 0,
      reminderAt: map['reminderAt'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['reminderAt'] as int),
    );
  }
}
