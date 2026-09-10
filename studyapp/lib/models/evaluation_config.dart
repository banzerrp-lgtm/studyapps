class EvaluationDimension {
  final String id;
  final String name;
  final double weight;

  const EvaluationDimension({
    required this.id,
    required this.name,
    required this.weight,
  });

  EvaluationDimension copyWith({
    String? id,
    String? name,
    double? weight,
  }) {
    return EvaluationDimension(
      id: id ?? this.id,
      name: name ?? this.name,
      weight: weight ?? this.weight,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'weight': weight,
    };
  }

  factory EvaluationDimension.fromMap(
    Map<String, dynamic> map,
  ) {
    return EvaluationDimension(
      id: map['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: map['name']?.toString() ?? 'Dimensión',
      weight: (map['weight'] as num?)?.toDouble() ?? 0,
    );
  }
}

class EvaluationConfig {
  final String mode;
  final double scaleMax;
  final List<EvaluationDimension> dimensions;
  final double passingMinimum;

  const EvaluationConfig({
    this.mode = 'Bolivia 2026',
    this.scaleMax = 100,
    this.dimensions = const [
      EvaluationDimension(
        id: 'ser',
        name: 'Ser',
        weight: 10,
      ),
      EvaluationDimension(
        id: 'saber',
        name: 'Saber',
        weight: 45,
      ),
      EvaluationDimension(
        id: 'hacer',
        name: 'Hacer',
        weight: 40,
      ),
      EvaluationDimension(
        id: 'autoevaluacion',
        name: 'Autoevaluación',
        weight: 5,
      ),
    ],
    this.passingMinimum = 51,
  });

  double get totalWeight {
    return dimensions.fold<double>(
      0,
      (sum, dimension) => sum + dimension.weight,
    );
  }

  double get passingPointsThreeTerms {
    return passingMinimum * 3;
  }

  bool get isValid {
    return (totalWeight - 100).abs() < 0.001 &&
        scaleMax > 0 &&
        passingMinimum >= 0 &&
        passingMinimum <= scaleMax &&
        dimensions.isNotEmpty;
  }

  double weightFor(String dimension) {
    for (final item in dimensions) {
      if (item.name == dimension || item.id == dimension) {
        return item.weight;
      }
    }

    return 0;
  }

  EvaluationDimension? dimensionById(String id) {
    for (final dimension in dimensions) {
      if (dimension.id == id) {
        return dimension;
      }
    }

    return null;
  }

  EvaluationDimension? dimensionByName(String name) {
    for (final dimension in dimensions) {
      if (dimension.name == name) {
        return dimension;
      }
    }

    return null;
  }

  // Compatibilidad con el código anterior.
  // Estas propiedades permiten que partes antiguas de la aplicación
  // sigan funcionando mientras hacemos la transición al nuevo sistema.

  double get ser => _weightAt(0);

  double get saber => _weightAt(1);

  double get hacer => _weightAt(2);

  double get autoevaluacion => _weightAt(3);

  double _weightAt(int index) {
    if (index >= dimensions.length) {
      return 0;
    }

    return dimensions[index].weight;
  }

  EvaluationConfig copyWith({
    String? mode,
    double? scaleMax,
    List<EvaluationDimension>? dimensions,
    double? passingMinimum,
  }) {
    return EvaluationConfig(
      mode: mode ?? this.mode,
      scaleMax: scaleMax ?? this.scaleMax,
      dimensions: dimensions ?? this.dimensions,
      passingMinimum:
          passingMinimum ?? this.passingMinimum,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mode': mode,
      'scaleMax': scaleMax,
      'dimensions':
          dimensions.map((item) => item.toMap()).toList(),
      'passingMinimum': passingMinimum,
    };
  }

  factory EvaluationConfig.fromMap(
    Map<String, dynamic> map,
  ) {
    final rawDimensions =
        map['dimensions'] as List<dynamic>?;

    // Nuevo formato
    if (rawDimensions != null && rawDimensions.isNotEmpty) {
      return EvaluationConfig(
        mode: map['mode']?.toString() ?? 'Bolivia 2026',
        scaleMax:
            (map['scaleMax'] as num?)?.toDouble() ?? 100,
        dimensions: rawDimensions
            .map(
              (item) => EvaluationDimension.fromMap(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(),
        passingMinimum:
            (map['passingMinimum'] as num?)?.toDouble() ?? 51,
      );
    }

    // Compatibilidad con configuraciones guardadas
    // con la versión anterior.
    return EvaluationConfig(
      mode: map['mode']?.toString() ?? 'Bolivia 2026',
      scaleMax:
          (map['scaleMax'] as num?)?.toDouble() ?? 100,
      dimensions: [
        EvaluationDimension(
          id: 'ser',
          name: 'Ser',
          weight: (map['ser'] as num?)?.toDouble() ?? 10,
        ),
        EvaluationDimension(
          id: 'saber',
          name: 'Saber',
          weight: (map['saber'] as num?)?.toDouble() ?? 45,
        ),
        EvaluationDimension(
          id: 'hacer',
          name: 'Hacer',
          weight: (map['hacer'] as num?)?.toDouble() ?? 40,
        ),
        EvaluationDimension(
          id: 'autoevaluacion',
          name: 'Autoevaluación',
          weight:
              (map['autoevaluacion'] as num?)?.toDouble() ?? 5,
        ),
      ],
      passingMinimum:
          (map['passingMinimum'] as num?)?.toDouble() ?? 51,
    );
  }
}