import '../models/evaluation_config.dart';
import '../models/term_grade.dart';

class GradeService {
  static double calculateTermScore(
    TermGrade? grade,
    EvaluationConfig config,
  ) {
    if (grade == null) {
      return 0;
    }

    // --------------------------------------------------------
    // NOTA DIRECTA
    // --------------------------------------------------------

    if (grade.mode == 'direct') {
      return _clamp(
        grade.directScore ?? 0,
        0,
        config.scaleMax,
      );
    }

    // --------------------------------------------------------
    // EVALUACIÓN DETALLADA
    // --------------------------------------------------------

    double total = 0;

    for (final dimension in config.dimensions) {
      if (dimension.weight <= 0) {
        continue;
      }

      final assessments = grade.assessments
          .where(
            (item) =>
                item.dimension == dimension.name ||
                item.dimension == dimension.id,
          )
          .toList();

      if (assessments.isEmpty) {
        continue;
      }

      final maximum = assessments.fold<double>(
        0,
        (sum, item) => sum + item.maximum,
      );

      final obtained = assessments.fold<double>(
        0,
        (sum, item) => sum + item.obtained,
      );

      if (maximum <= 0) {
        continue;
      }

      final percentage = obtained / maximum;

      final dimensionScore =
          percentage * dimension.weight;

      total += _clamp(
        dimensionScore,
        0,
        dimension.weight,
      );
    }

    return _clamp(
      total,
      0,
      config.scaleMax,
    );
  }

  static double? calculateAnnualScore({
    required String subject,
    required List<TermGrade> grades,
    required EvaluationConfig config,
  }) {
    final subjectGrades = <int, TermGrade>{};

    for (final grade in grades) {
      if (grade.subject == subject) {
        subjectGrades[grade.trimester] = grade;
      }
    }

    if (!subjectGrades.containsKey(1) ||
        !subjectGrades.containsKey(2) ||
        !subjectGrades.containsKey(3)) {
      return null;
    }

    final total =
        calculateTermScore(
          subjectGrades[1],
          config,
        ) +
        calculateTermScore(
          subjectGrades[2],
          config,
        ) +
        calculateTermScore(
          subjectGrades[3],
          config,
        );

    return total / 3;
  }

  static double? calculateCurrentAverage({
    required String subject,
    required List<TermGrade> grades,
    required EvaluationConfig config,
  }) {
    final scores = grades
        .where(
          (grade) => grade.subject == subject,
        )
        .map(
          (grade) => calculateTermScore(
            grade,
            config,
          ),
        )
        .toList();

    if (scores.isEmpty) {
      return null;
    }

    final total = scores.fold<double>(
      0,
      (sum, value) => sum + value,
    );

    return total / scores.length;
  }

  static double? requiredForThirdTerm({
    required String subject,
    required List<TermGrade> grades,
    required EvaluationConfig config,
  }) {
    final subjectGrades = <int, TermGrade>{};

    for (final grade in grades) {
      if (grade.subject == subject) {
        subjectGrades[grade.trimester] = grade;
      }
    }

    if (!subjectGrades.containsKey(1) ||
        !subjectGrades.containsKey(2) ||
        subjectGrades.containsKey(3)) {
      return null;
    }

    final first = calculateTermScore(
      subjectGrades[1],
      config,
    );

    final second = calculateTermScore(
      subjectGrades[2],
      config,
    );

    return config.passingPointsThreeTerms -
        first -
        second;
  }

  static double calculateGeneralAverage({
    required List<String> subjects,
    required List<TermGrade> grades,
    required EvaluationConfig Function(
      String subject,
    ) configForSubject,
  }) {
    final annualScores = <double>[];

    for (final subject in subjects) {
      final config = configForSubject(subject);

      final annual = calculateAnnualScore(
        subject: subject,
        grades: grades,
        config: config,
      );

      if (annual != null) {
        annualScores.add(annual);
      }
    }

    if (annualScores.isEmpty) {
      return 0;
    }

    final total = annualScores.fold<double>(
      0,
      (sum, value) => sum + value,
    );

    return total / annualScores.length;
  }

  static String academicStatus({
    required double score,
    required EvaluationConfig config,
  }) {
    if (score >= config.passingMinimum) {
      return 'Aprobada';
    }

    return 'No aprobada';
  }

  static bool canReachPassingScore({
    required double required,
    required EvaluationConfig config,
  }) {
    return required <= config.scaleMax;
  }

  static double _clamp(
    double value,
    double minimum,
    double maximum,
  ) {
    if (value < minimum) {
      return minimum;
    }

    if (value > maximum) {
      return maximum;
    }

    return value;
  }
}