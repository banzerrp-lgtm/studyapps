import 'dart:ui';

import 'package:uuid/uuid.dart';

enum AttachmentType { image, pdf }

enum AttachmentAnnotationType { draw, highlight, underline }

class AttachmentAnnotation {
  final int page;
  final AttachmentAnnotationType type;
  final List<Offset> points;
  final int color;
  final double width;

  const AttachmentAnnotation({
    required this.page,
    required this.type,
    required this.points,
    required this.color,
    required this.width,
  });

  Map<String, dynamic> toJson() => {
    'page': page,
    'type': type.name,
    'points': points.map((point) => {'x': point.dx, 'y': point.dy}).toList(),
    'color': color,
    'width': width,
  };

  factory AttachmentAnnotation.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['points'] as List<dynamic>? ?? const [];
    return AttachmentAnnotation(
      page: (json['page'] as num?)?.toInt() ?? 1,
      type: AttachmentAnnotationType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => AttachmentAnnotationType.draw,
      ),
      points: rawPoints
          .whereType<Map<String, dynamic>>()
          .map(
            (point) => Offset(
              (point['x'] as num?)?.toDouble() ?? 0,
              (point['y'] as num?)?.toDouble() ?? 0,
            ),
          )
          .toList(),
      color: (json['color'] as num?)?.toInt() ?? 0xFF1565C0,
      width: (json['width'] as num?)?.toDouble() ?? 4,
    );
  }
}

class Attachment {
  final String id;
  final String name;
  final AttachmentType type;
  final String dataBase64;
  final List<AttachmentAnnotation> annotations;
  final String? renderedBase64;

  Attachment({
    String? id,
    required this.name,
    required this.type,
    required this.dataBase64,
    this.annotations = const [],
    this.renderedBase64,
  }) : id = id ?? const Uuid().v4();

  bool get isPdf => type == AttachmentType.pdf;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'dataBase64': dataBase64,
    'annotations': annotations.map((item) => item.toJson()).toList(),
    'renderedBase64': renderedBase64,
  };

  factory Attachment.fromJson(Map<String, dynamic> json) {
    final rawAnnotations = json['annotations'] as List<dynamic>? ?? const [];
    return Attachment(
      id: json['id']?.toString(),
      name: json['name']?.toString() ?? 'Adjunto',
      type: AttachmentType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => AttachmentType.image,
      ),
      dataBase64: json['dataBase64']?.toString() ?? '',
      annotations: rawAnnotations
          .whereType<Map<String, dynamic>>()
          .map(AttachmentAnnotation.fromJson)
          .toList(),
      renderedBase64: json['renderedBase64']?.toString(),
    );
  }

  Attachment copyWith({
    List<AttachmentAnnotation>? annotations,
    String? renderedBase64,
  }) {
    return Attachment(
      id: id,
      name: name,
      type: type,
      dataBase64: dataBase64,
      annotations: annotations ?? this.annotations,
      renderedBase64: renderedBase64 ?? this.renderedBase64,
    );
  }
}
