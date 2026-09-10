import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/grades_provider.dart';
import '../providers/subjects_provider.dart';
import '../providers/tasks_provider.dart';
import '../utils/formatters.dart';
import '../widgets/academic_card.dart';
import '../widgets/stat_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tasksProvider = context.watch<TasksProvider>();
    final subjectsProvider = context.watch<SubjectsProvider>();
    final gradesProvider = context.watch<GradesProvider>();

    final subjects = subjectsProvider.subjects;
    final pending = tasksProvider.pendingCount;
    final completed = tasksProvider.completedCount;
    final generalAverage = gradesProvider.generalAverage(subjects);

    Future<void> refresh() async {
      await Future.wait([
        context.read<TasksProvider>().load(),
        context.read<SubjectsProvider>().load(),
        context.read<GradesProvider>().load(),
      ]);
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        children: [
          const Text('¡Hola! 👋', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            'Organiza tu día y mejora tu estudio.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF4F46E5)]),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                const Icon(Icons.school, color: Colors.white, size: 42),
                const SizedBox(width: 18),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Promedio general anual', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 4),
                    Text(
                      generalAverage == null ? 'Aún no disponible' : formatNumber(generalAverage),
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          const Text('Resumen', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: StatCard(icon: Icons.assignment_outlined, number: '$pending', label: 'Pendientes'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(icon: Icons.menu_book_outlined, number: '${subjects.length}', label: 'Materias'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(icon: Icons.check_circle_outline, number: '$completed', label: 'Completadas'),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text('Situación académica', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          if (subjects.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
              child: const Text('Agrega materias para comenzar a registrar calificaciones.'),
            )
          else
            ...subjects.map((subject) {
              final config = gradesProvider.configFor(subject);
              final annual = gradesProvider.annualScore(subject);
              final current = gradesProvider.currentAverage(subject);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AcademicCard(
                  subject: subject,
                  annual: annual,
                  current: current,
                  config: config,
                  grades: gradesProvider.grades,
                ),
              );
            }),
        ],
      ),
    );
  }
}