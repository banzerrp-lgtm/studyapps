import 'package:flutter/foundation.dart';

import '../services/database_service.dart';

class SubjectsProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  List<String> _subjects = [];
  bool _loading = true;

  List<String> get subjects => List.unmodifiable(_subjects);
  bool get loading => _loading;

  Future<void> load() async {
    try {
      _subjects = await _db.loadSubjects();
    } catch (error, stackTrace) {
      debugPrint('No se pudieron cargar las materias: $error\n$stackTrace');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> addSubject(String name) async {
    final exists = _subjects.any(
      (item) => item.toLowerCase() == name.toLowerCase(),
    );

    if (exists) {
      return false;
    }

    _subjects.add(name);
    notifyListeners();

    await _db.addSubject(name);
    return true;
  }

  Future<void> deleteSubject(String name) async {
    _subjects.remove(name);
    notifyListeners();

    await _db.deleteSubject(name);
  }
}
