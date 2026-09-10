import 'package:flutter/material.dart';

import '../models/evaluation_config.dart';
import '../models/term_grade.dart';
import '../services/grade_service.dart';
import '../utils/formatters.dart';
import 'grade_column.dart';

class SubjectGradeCard extends StatelessWidget {
  final String subject;
  final List<TermGrade> grades;
  final EvaluationConfig config;
  final VoidCallback onTap;

  const SubjectGradeCard({
    super.key,
    required this.subject,
    required this.grades,
    required this.config,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final map = <int, TermGrade>{};

    for (final grade in grades.where((g) => g.subject == subject)) {
      map[grade.trimester] = grade;
    }

    final annual = GradeService.calculateAnnualScore(
      subject: subject,
      grades: grades,
      config: config,
    );

    final required = GradeService.requiredForThirdTerm(
      subject: subject,
      grades: grades,
      config: config,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(subject,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                GradeColumn(
                  label: '1.º',
                  value: map[1] == null
                      ? null
                      : GradeService.calculateTermScore(map[1], config),
                ),
                GradeColumn(
                  label: '2.º',
                  value: map[2] == null
                      ? null
                      : GradeService.calculateTermScore(map[2], config),
                ),
                GradeColumn(
                  label: '3.º',
                  value: map[3] == null
                      ? null
                      : GradeService.calculateTermScore(map[3], config),
                ),
                GradeColumn(label: 'FINAL', value: annual, highlight: true),
              ],
            ),
            if (required != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: required <= config.scaleMax
                      ? Colors.orange.withValues(alpha: 0.08)
                      : Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  required <= 0
                      ? '✅ Ya alcanzaste el mínimo.'
                      : required <= config.scaleMax
                          ? '🎯 Necesitas ${formatNumber(required)} en el 3.º trimestre para llegar a ${formatNumber(config.passingPointsThreeTerms)} puntos.'
                          : '❌ Necesitarías ${formatNumber(required)} y el máximo del 3.º es ${formatNumber(config.scaleMax)}.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: required <= config.scaleMax
                        ? Colors.orange.shade800
                        : Colors.red.shade800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}