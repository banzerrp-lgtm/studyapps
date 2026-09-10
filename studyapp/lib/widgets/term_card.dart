import 'package:flutter/material.dart';

import '../models/evaluation_config.dart';
import '../models/term_grade.dart';
import '../services/grade_service.dart';
import '../utils/formatters.dart';

class TermCard extends StatelessWidget {
  final int trimester;
  final TermGrade? grade;
  final EvaluationConfig config;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const TermCard({
    super.key,
    required this.trimester,
    required this.grade,
    required this.config,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final score =
        grade == null ? null : GradeService.calculateTermScore(grade, config);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                '${trimester}T',
                style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  score == null ? 'Sin calificación' : formatNumber(score),
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  grade == null
                      ? 'Agrega la nota.'
                      : grade!.mode == 'direct'
                          ? 'Nota trimestral directa'
                          : '${grade!.assessments.length} evaluaciones detalladas',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          if (onDelete != null)
            IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline)),
          FilledButton.tonal(
            onPressed: onEdit,
            child: Text(grade == null ? 'Agregar' : 'Editar'),
          ),
        ],
      ),
    );
  }
}