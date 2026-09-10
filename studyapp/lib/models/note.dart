import 'dart:convert';

class Note {
  final String id;
  final String subject;
  final String title;
  final String content;
  final DateTime date;
  final List<String> files;

  const Note({
    required this.id,
    required this.subject,
    required this.title,
    required this.content,
    required this.date,
    this.files = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject': subject,
      'title': title,
      'content': content,
      'date': date.toIso8601String(),
      'files': jsonEncode(files),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    final raw = map['files'];
    List<dynamic> decoded;

    if (raw is String) {
      try {
        decoded = jsonDecode(raw) as List<dynamic>;
      } catch (_) {
        decoded = [];
      }
    } else if (raw is List) {
      decoded = raw;
    } else {
      decoded = [];
    }

    return Note(
      id: map['id'].toString(),
      subject: map['subject'].toString(),
      title: map['title']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      date: DateTime.parse(map['date'].toString()),
      files: decoded.map((item) => item.toString()).toList(),
    );
  }

  Note copyWith({
    String? id,
    String? subject,
    String? title,
    String? content,
    DateTime? date,
    List<String>? files,
  }) {
    return Note(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      files: files ?? this.files,
    );
  }
}