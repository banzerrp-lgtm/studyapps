import 'assessment.dart';

class TermGrade {
  final String id;
  final String subject;
  final int trimester;

  // direct = nota trimestral colocada directamente
  // detailed = cálculo mediante evaluaciones
  final String mode;

  final double? directScore;

  final List<Assessment> assessments;

  const TermGrade({
    required this.id,
    required this.subject,
    required this.trimester,
    required this.mode,
    this.directScore,
    this.assessments = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject': subject,
      'trimester': trimester,
      'mode': mode,
      'directScore': directScore,
      'assessments': assessments
          .map(
            (assessment) => assessment.toMap(),
          )
          .toList(),
    };
  }

  factory TermGrade.fromMap(
    Map<String, dynamic> map,
  ) {
    final rawAssessments =
        (map['assessments'] as List<dynamic>?) ?? [];

    return TermGrade(
      id: map['id'].toString(),
      subject: map['subject'].toString(),
      trimester:
          (map['trimester'] as num).toInt(),
      mode: map['mode'].toString(),
      directScore:
          map['directScore'] == null
              ? null
              : (map['directScore'] as num)
                  .toDouble(),
      assessments: rawAssessments
          .map(
            (item) => Assessment.fromMap(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }

  TermGrade copyWith({
    String? id,
    String? subject,
    int? trimester,
    String? mode,
    double? directScore,
    List<Assessment>? assessments,
  }) {
    return TermGrade(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      trimester: trimester ?? this.trimester,
      mode: mode ?? this.mode,
      directScore:
          directScore ?? this.directScore,
      assessments:
          assessments ?? this.assessments,
    );
  }
}