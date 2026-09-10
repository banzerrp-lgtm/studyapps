import 'package:flutter/foundation.dart';

import '../models/task.dart';
import '../services/database_service.dart';
import '../utils/id_generator.dart';

class TasksProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  List<Task> _tasks = [];
  bool _loading = true;

  List<Task> get tasks => List.unmodifiable(_tasks);
  bool get loading => _loading;

  int get pendingCount => _tasks.where((task) => !task.completed).length;
  int get completedCount => _tasks.where((task) => task.completed).length;

  Future<void> load() async {
    _tasks = await _db.loadTasks();
    _loading = false;
    notifyListeners();
  }

  Future<void> addTask({
    required String title,
    required String subject,
    required DateTime date,
    required String priority,
  }) async {
    final task = Task(
      id: generateId(),
      title: title,
      subject: subject,
      date: date,
      priority: priority,
    );

    _tasks.add(task);
    notifyListeners();

    await _db.upsertTask(task);
  }

  Future<void> toggleTask(Task task) async {
    task.completed = !task.completed;
    notifyListeners();

    await _db.upsertTask(task);
  }

  Future<void> deleteTask(Task task) async {
    _tasks.removeWhere((item) => item.id == task.id);
    notifyListeners();

    await _db.deleteTask(task.id);
  }
}