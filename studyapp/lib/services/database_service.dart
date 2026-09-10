import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/evaluation_config.dart';
import '../models/note.dart';
import '../models/schedule_item.dart';
import '../models/task.dart';
import '../models/term_grade.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'studyapp.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tasks(
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            subject TEXT NOT NULL,
            date TEXT NOT NULL,
            priority TEXT NOT NULL,
            completed INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE subjects(
            name TEXT PRIMARY KEY,
            position INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE schedule(
            id TEXT PRIMARY KEY,
            day TEXT NOT NULL,
            subject TEXT NOT NULL,
            startHour INTEGER NOT NULL,
            startMinute INTEGER NOT NULL,
            endHour INTEGER NOT NULL,
            endMinute INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE grades(
            id TEXT PRIMARY KEY,
            subject TEXT NOT NULL,
            trimester INTEGER NOT NULL,
            mode TEXT NOT NULL,
            directScore REAL,
            assessments TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE configs(
            subject TEXT PRIMARY KEY,
            configJson TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE notes(
            id TEXT PRIMARY KEY,
            subject TEXT NOT NULL,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            date TEXT NOT NULL,
            files TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // ---------------- TAREAS ----------------

  Future<List<Task>> loadTasks() async {
    final db = await database;
    final rows = await db.query('tasks', orderBy: 'date ASC');
    return rows.map(Task.fromMap).toList();
  }

  Future<void> upsertTask(Task task) async {
    final db = await database;
    await db.insert('tasks', task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteTask(String id) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- MATERIAS ----------------

  Future<List<String>> loadSubjects() async {
    final db = await database;
    final rows = await db.query('subjects', orderBy: 'position ASC');
    return rows.map((row) => row['name'] as String).toList();
  }

  Future<void> addSubject(String name) async {
    final db = await database;
    final existing = await db.query('subjects');
    await db.insert(
      'subjects',
      {'name': name, 'position': existing.length},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteSubject(String name) async {
    final db = await database;
    await db.delete('subjects', where: 'name = ?', whereArgs: [name]);
  }

  // ---------------- HORARIO ----------------

  Future<List<ScheduleItem>> loadSchedule() async {
    final db = await database;
    final rows = await db.query('schedule');
    return rows.map(ScheduleItem.fromMap).toList();
  }

  Future<void> upsertScheduleItem(ScheduleItem item) async {
    final db = await database;
    await db.insert('schedule', item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteScheduleItem(String id) async {
    final db = await database;
    await db.delete('schedule', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- CALIFICACIONES ----------------

  Future<List<TermGrade>> loadGrades() async {
    final db = await database;
    final rows = await db.query('grades');
    return rows.map(TermGrade.fromMap).toList();
  }

  Future<void> upsertGrade(TermGrade grade) async {
    final db = await database;
    await db.insert('grades', grade.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteGrade({
    required String subject,
    required int trimester,
  }) async {
    final db = await database;
    await db.delete(
      'grades',
      where: 'subject = ? AND trimester = ?',
      whereArgs: [subject, trimester],
    );
  }

  // ---------------- CONFIGURACIÓN ----------------

  Future<Map<String, EvaluationConfig>> loadAllConfigs() async {
    final db = await database;
    final rows = await db.query('configs');

    final result = <String, EvaluationConfig>{};

    for (final row in rows) {
      try {
        final decoded =
            jsonDecode(row['configJson'] as String) as Map<String, dynamic>;
        result[row['subject'] as String] = EvaluationConfig.fromMap(decoded);
      } catch (_) {
        // Configuración dañada: se ignora.
      }
    }

    return result;
  }

  Future<EvaluationConfig> loadConfigForSubject(String subject) async {
    final configs = await loadAllConfigs();
    return configs[subject] ?? EvaluationConfig();
  }

  Future<void> saveConfigForSubject(
    String subject,
    EvaluationConfig config,
  ) async {
    final db = await database;
    await db.insert(
      'configs',
      {'subject': subject, 'configJson': jsonEncode(config.toMap())},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ---------------- APUNTES ----------------

  Future<List<Note>> loadNotes() async {
    final db = await database;
    final rows = await db.query('notes', orderBy: 'date DESC');
    return rows.map(Note.fromMap).toList();
  }

  Future<void> upsertNote(Note note) async {
    final db = await database;
    await db.insert('notes', note.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteNote(String id) async {
    final db = await database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }
}