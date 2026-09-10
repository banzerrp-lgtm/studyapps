import 'package:flutter/material.dart';

import '../models/evaluation_config.dart';
import '../models/term_grade.dart';
import '../services/grade_service.dart';
import 'home_term.dart';

class AcademicCard extends StatelessWidget {
  final String subject;
  final double? annual;
  final double? current;
  final EvaluationConfig config;
  final List<TermGrade> grades;

  const AcademicCard({
    super.key,
    required this.subject,
    required this.annual,
    required this.current,
    required this.config,
    required this.grades,
  });

  @override
  Widget build(BuildContext context) {
    final subjectGrades = <int, TermGrade>{};

    for (final grade in grades.where((g) => g.subject == subject)) {
      subjectGrades[grade.trimester] = grade;
    }

    final color = annual == null
        ? Colors.orange
        : annual! >= config.passingMinimum
            ? Colors.green
            : Colors.red;

    final status = annual == null
        ? 'En curso'
        : annual! >= config.passingMinimum
            ? 'Aprobada'
            : 'No aprobada';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(subject,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              Text(status,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              HomeTerm(
                label: '1T',
                value: subjectGrades[1] == null
                    ? null
                    : GradeService.calculateTermScore(subjectGrades[1], config),
              ),
              HomeTerm(
                label: '2T',
                value: subjectGrades[2] == null
                    ? null
                    : GradeService.calculateTermScore(subjectGrades[2], config),
              ),
              HomeTerm(
                label: '3T',
                value: subjectGrades[3] == null
                    ? null
                    : GradeService.calculateTermScore(subjectGrades[3], config),
              ),
              HomeTerm(label: 'Final', value: annual, highlight: true),
            ],
          ),
        ],
      ),
    );
  }
}