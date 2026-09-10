import 'dart:convert';

import 'attachment.dart';

class Note {
  final String id;
  final String subject;
  final String title;
  final String content;
  final DateTime date;
  final List<String> files;
  final String? drawingJson;
  final List<Attachment> attachments;

  const Note({
    required this.id,
    required this.subject,
    required this.title,
    required this.content,
    required this.date,
    this.files = const [],
    this.drawingJson,
    this.attachments = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject': subject,
      'title': title,
      'content': content,
      'date': date.toIso8601String(),
      'files': jsonEncode(files),
      'drawingJson': drawingJson ?? '',
      'attachments': jsonEncode(
        attachments.map((attachment) => attachment.toJson()).toList(),
      ),
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
      drawingJson: (map['drawingJson']?.toString().isEmpty ?? true)
          ? null
          : map['drawingJson'].toString(),
      attachments: _decodeAttachments(map['attachments']),
    );
  }

  static List<Attachment> _decodeAttachments(Object? raw) {
    if (raw is! String || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(Attachment.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Note copyWith({
    String? id,
    String? subject,
    String? title,
    String? content,
    DateTime? date,
    List<String>? files,
    String? drawingJson,
    List<Attachment>? attachments,
  }) {
    return Note(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      files: files ?? this.files,
      drawingJson: drawingJson ?? this.drawingJson,
      attachments: attachments ?? this.attachments,
    );
  }
}
