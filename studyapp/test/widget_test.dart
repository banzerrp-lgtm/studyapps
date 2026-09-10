import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:studyapp/main.dart';
import 'package:studyapp/models/quiz.dart';
import 'package:studyapp/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  testWidgets('StudyApp inicia correctamente', (tester) async {
    await tester.pumpWidget(const StudyApp());

    expect(find.text('¡Hola! 👋'), findsOneWidget);
    expect(find.text('Resumen'), findsOneWidget);
  });

  test('loadQuizzes ignora filas corruptas y devuelve los válidos', () async {
    final dbPath = join(await getDatabasesPath(), 'studyapp.db');
    await deleteDatabase(dbPath);

    final db = await DatabaseService.instance.database;
    await db.delete('quizzes');

    final validQuiz = Quiz(
      id: 'valid-1',
      subject: 'Matemáticas',
      title: 'Quiz válido',
      description: 'Descripción',
      questions: [
        MultipleChoiceQuestion(
          id: 'q-1',
          statement: '¿2 + 2?',
          options: const [
            ChoiceOption(id: 'a', text: '3'),
            ChoiceOption(id: 'b', text: '4'),
            ChoiceOption(id: 'c', text: '5'),
          ],
          correctOptionId: 'b',
        ),
      ],
    );

    await db.insert('quizzes', {
      'id': validQuiz.id,
      'title': validQuiz.title,
      'subject': validQuiz.subject,
      'description': validQuiz.description,
      'quizJson': jsonEncode(validQuiz.toJson()),
      'createdAt': DateTime.now().toIso8601String(),
    });

    await db.insert('quizzes', {
      'id': 'broken-1',
      'title': 'Quiz roto',
      'subject': 'Biología',
      'description': 'Roto',
      'quizJson': '{not valid json',
      'createdAt': DateTime.now().toIso8601String(),
    });

    final quizzes = await DatabaseService.instance.loadQuizzes();

    expect(quizzes, hasLength(1));
    expect(quizzes.first.id, validQuiz.id);
    expect(quizzes.first.title, 'Quiz válido');
  });
}
