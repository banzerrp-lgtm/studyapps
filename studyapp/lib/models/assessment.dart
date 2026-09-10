class Assessment {
final String id;
final String name;

// Nombre de la dimensión.
// Se mantiene para compatibilidad con evaluaciones antiguas.
final String dimension;

// ID estable de la dimensión.
// Permite cambiar el nombre de una dimensión
// sin perder la relación con las evaluaciones.
final String? dimensionId;

final double obtained;
final double maximum;

const Assessment({
required this.id,
required this.name,
required this.dimension,
this.dimensionId,
required this.obtained,
required this.maximum,
});

Map<String, dynamic> toMap() {
return {
'id': id,
'name': name,
'dimension': dimension,
'dimensionId': dimensionId,
'obtained': obtained,
'maximum': maximum,
};
}

factory Assessment.fromMap(
Map<String, dynamic> map,
) {
return Assessment(
id: map['id'].toString(),
name: map['name'].toString(),
dimension:
map['dimension']?.toString() ?? '',
dimensionId:
map['dimensionId']?.toString(),
obtained:
(map['obtained'] as num).toDouble(),
maximum:
(map['maximum'] as num).toDouble(),
);
}

Assessment copyWith({
String? id,
String? name,
String? dimension,
String? dimensionId,
double? obtained,
double? maximum,
}) {
return Assessment(
id: id ?? this.id,
name: name ?? this.name,
dimension:
dimension ?? this.dimension,
dimensionId:
dimensionId ?? this.dimensionId,
obtained:
obtained ?? this.obtained,
maximum:
maximum ?? this.maximum,
);
}
}
