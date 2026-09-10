import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../dialogs/evaluation_config_dialog.dart';
import '../dialogs/term_grade_editor_dialog.dart';
import '../models/term_grade.dart';
import '../providers/grades_provider.dart';
import '../services/grade_service.dart';
import '../utils/formatters.dart';
import '../widgets/term_card.dart';

class SubjectGradesScreen extends StatelessWidget {
  final String subject;

  const SubjectGradesScreen({super.key, required this.subject});

  TermGrade? _gradeFor(List<TermGrade> grades, int trimester) {
    for (final grade in grades) {
      if (grade.subject == subject && grade.trimester == trimester) {
        return grade;
      }
    }
    return null;
  }

  Future<void> _edit(BuildContext context, int trimester) async {
    final gradesProvider = context.read<GradesProvider>();
    final config = gradesProvider.configFor(subject);
    final existing = _gradeFor(gradesProvider.grades, trimester);

    final result = await showTermGradeEditor(
      context,
      subject: subject,
      trimester: trimester,
      config: config,
      existing: existing,
    );

    if (result == null) return;

    await gradesProvider.saveGrade(result);
  }

  Future<void> _delete(BuildContext context, int trimester) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar calificación'),
          content: Text('¿Eliminar la calificación del $trimester.º trimestre?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    if (context.mounted) {
      await context.read<GradesProvider>().deleteGrade(subject: subject, trimester: trimester);
    }
  }

  Future<void> _settings(BuildContext context) async {
    final gradesProvider = context.read<GradesProvider>();
    final config = gradesProvider.configFor(subject);

    final updated = await showEvaluationConfigDialog(context, config);

    if (updated == null) return;

    await gradesProvider.saveConfigForSubject(subject, updated);
  }

  @override
  Widget build(BuildContext context) {
    final gradesProvider = context.watch<GradesProvider>();
    final config = gradesProvider.configFor(subject);
    final grades = gradesProvider.grades;

    final t1 = _gradeFor(grades, 1);
    final t2 = _gradeFor(grades, 2);
    final t3 = _gradeFor(grades, 3);

    final annual = gradesProvider.annualScore(subject);

    final required = GradeService.requiredForThirdTerm(
      subject: subject,
      grades: grades,
      config: config,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(subject),
        actions: [IconButton(onPressed: () => _settings(context), icon: const Icon(Icons.settings_outlined))],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF4F46E5)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.analytics_outlined, color: Colors.white, size: 36),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Promedio anual', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 4),
                    Text(
                      annual == null ? '—' : formatNumber(annual),
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Trimestres', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TermCard(
            trimester: 1,
            grade: t1,
            config: config,
            onEdit: () => _edit(context, 1),
            onDelete: t1 == null ? null : () => _delete(context, 1),
          ),
          const SizedBox(height: 10),
          TermCard(
            trimester: 2,
            grade: t2,
            config: config,
            onEdit: () => _edit(context, 2),
            onDelete: t2 == null ? null : () => _delete(context, 2),
          ),
          const SizedBox(height: 10),
          TermCard(
            trimester: 3,
            grade: t3,
            config: config,
            onEdit: () => _edit(context, 3),
            onDelete: t3 == null ? null : () => _delete(context, 3),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🎯 ¿Cuánto necesitas para aprobar?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                const SizedBox(height: 10),
                if (required == null)
                  Text(
                    t3 != null
                        ? 'El 3.º trimestre ya está registrado.'
                        : 'Registra 1.º y 2.º trimestre para calcular cuánto necesitas.',
                    style: TextStyle(color: Colors.grey.shade700),
                  )
                else if (required <= 0)
                  const Text(
                    '✅ Ya alcanzaste el mínimo acumulado.',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                  )
                else if (required <= config.scaleMax)
                  Text(
                    'Necesitas ${formatNumber(required)} / ${formatNumber(config.scaleMax)} en el 3.º trimestre para alcanzar ${formatNumber(config.passingPointsThreeTerms)} puntos acumulados.',
                  )
                else
                  Text(
                    '❌ Necesitarías ${formatNumber(required)} puntos, pero el máximo es ${formatNumber(config.scaleMax)}.',
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Configuración actual', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...config.dimensions.map(
                      (dimension) => Chip(label: Text('${dimension.name}: ${formatNumber(dimension.weight)}')),
                    ),
                    Chip(label: Text('Mínimo: ${formatNumber(config.passingMinimum)}')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}