import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/grades_provider.dart';
import '../providers/subjects_provider.dart';
import '../utils/formatters.dart';
import '../widgets/grade_info_card.dart';
import '../widgets/subject_grade_card.dart';
import 'subject_grades_screen.dart';

class GradesScreen extends StatelessWidget {
  const GradesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gradesProvider = context.watch<GradesProvider>();
    final subjects = context.watch<SubjectsProvider>().subjects;

    if (gradesProvider.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final annuals = subjects.map(gradesProvider.annualScore).whereType<double>().toList();
    final general = annuals.isEmpty ? null : annuals.reduce((a, b) => a + b) / annuals.length;

    final approved = subjects.where((subject) {
      final annual = gradesProvider.annualScore(subject);
      if (annual == null) return false;
      return annual >= gradesProvider.configFor(subject).passingMinimum;
    }).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF4F46E5)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.bar_chart, color: Colors.white, size: 34),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Promedio general anual', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        general == null ? 'Aún no disponible' : formatNumber(general),
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: GradeInfoCard(label: 'Aprobadas', value: '$approved', icon: Icons.check_circle_outline, color: Colors.green),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GradeInfoCard(
                  label: 'En curso',
                  value: '${subjects.length - annuals.length}',
                  icon: Icons.hourglass_empty,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GradeInfoCard(
                  label: 'Notas',
                  value: '${gradesProvider.grades.length}',
                  icon: Icons.fact_check_outlined,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: subjects.isEmpty
              ? const Center(child: Text('Primero agrega materias.'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 5, 20, 30),
                  itemCount: subjects.length,
                  itemBuilder: (context, index) {
                    final subject = subjects[index];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SubjectGradeCard(
                        subject: subject,
                        grades: gradesProvider.grades,
                        config: gradesProvider.configFor(subject),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => SubjectGradesScreen(subject: subject)),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}