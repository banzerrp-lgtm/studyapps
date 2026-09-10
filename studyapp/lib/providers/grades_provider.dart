import 'package:flutter/foundation.dart';

import '../models/evaluation_config.dart';
import '../models/term_grade.dart';
import '../services/database_service.dart';
import '../services/grade_service.dart';

class GradesProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  List<TermGrade> _grades = [];
  Map<String, EvaluationConfig> _configs = {};
  bool _loading = true;

  List<TermGrade> get grades => List.unmodifiable(_grades);
  bool get loading => _loading;

  // Cada materia tiene su propia configuración. Si no existe una
  // guardada, se usa la configuración por defecto — nunca la de
  // otra materia.
  EvaluationConfig configFor(String subject) {
    return _configs[subject] ?? EvaluationConfig();
  }

  Future<void> load() async {
    _grades = await _db.loadGrades();
    _configs = await _db.loadAllConfigs();
    _loading = false;
    notifyListeners();
  }

  Future<void> saveGrade(TermGrade grade) async {
    _grades.removeWhere(
      (item) => item.subject == grade.subject && item.trimester == grade.trimester,
    );
    _grades.add(grade);
    notifyListeners();

    await _db.upsertGrade(grade);
  }

  Future<void> deleteGrade({
    required String subject,
    required int trimester,
  }) async {
    _grades.removeWhere(
      (item) => item.subject == subject && item.trimester == trimester,
    );
    notifyListeners();

    await _db.deleteGrade(subject: subject, trimester: trimester);
  }

  Future<void> saveConfigForSubject(
    String subject,
    EvaluationConfig config,
  ) async {
    _configs[subject] = config;
    notifyListeners();

    await _db.saveConfigForSubject(subject, config);
  }

  double? annualScore(String subject) {
    return GradeService.calculateAnnualScore(
      subject: subject,
      grades: _grades,
      config: configFor(subject),
    );
  }

  double? currentAverage(String subject) {
    return GradeService.calculateCurrentAverage(
      subject: subject,
      grades: _grades,
      config: configFor(subject),
    );
  }

  double? generalAverage(List<String> subjects) {
    final annuals = subjects.map(annualScore).whereType<double>().toList();

    if (annuals.isEmpty) {
      return null;
    }

    return annuals.reduce((a, b) => a + b) / annuals.length;
  }
}