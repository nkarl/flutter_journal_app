// File: lib/models/journal_entry.dart

class JournalEntry {
  final String entryId;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? userId;
  final bool isSynced;

  // Construct a new entry object.
  JournalEntry({
    required this.entryId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.userId,
    this.isSynced = false,
  });

  // Convert entry DTO to JSON
  Map<String, dynamic> toJson() => {
    'entryId': entryId,
    'title': title,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'userId': userId,
    'isSynced': isSynced,
  };

  // We use the factory pattern to create a single instance from JSON.
  // Because an entries data file can be very large, we want a single
  // object instance that persists throughout the app for more efficient
  // memory use.
  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
    entryId: json['entryId'],
    title: json['title'],
    content: json['content'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
    userId: json['userId'],
    isSynced: json['isSynced'],
  );
}
