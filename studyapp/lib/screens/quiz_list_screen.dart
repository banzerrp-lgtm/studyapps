import 'package:flutter/material.dart';

import '../models/quiz.dart';
import '../services/database_service.dart';
import 'quiz_builder_screen.dart';

class QuizListScreen extends StatefulWidget {
  const QuizListScreen({super.key});

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  late Future<List<Quiz>> _quizzesFuture;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  void _loadQuizzes() {
    _quizzesFuture = DatabaseService.instance.loadQuizzes();
  }

  Future<void> _openBuilder() async {
    final result = await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const QuizBuilderScreen()));

    if (!mounted) return;
    if (result != null) {
      setState(() {
        _loadQuizzes();
      });
    }
  }

  Future<void> _deleteQuiz(String quizId) async {
    await DatabaseService.instance.deleteQuiz(quizId);
    if (!mounted) return;
    setState(() {
      _loadQuizzes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
        actions: [
          IconButton(
            tooltip: 'Crear quiz',
            onPressed: _openBuilder,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: FutureBuilder<List<Quiz>>(
        future: _quizzesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'No se pudieron cargar los quizzes.\n${snapshot.error}',
              ),
            );
          }

          final quizzes = snapshot.data ?? const <Quiz>[];

          if (quizzes.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No hay quizzes creados aún.\nPulsa “Crear quiz” para empezar.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: quizzes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final quiz = quizzes[index];

              return Card(
                child: ListTile(
                  title: Text(quiz.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text('Materia: ${quiz.subject}'),
                      Text('Preguntas: ${quiz.questions.length}'),
                    ],
                  ),
                  trailing: IconButton(
                    tooltip: 'Eliminar quiz',
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteQuiz(quiz.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
