import 'package:flutter/material.dart';

import '../models/assessment.dart';
import '../models/evaluation_config.dart';
import '../utils/id_generator.dart';

Future<Assessment?> showAssessmentDialog(
  BuildContext context,
  EvaluationConfig config,
) async {
  final nameController = TextEditingController();
  final obtainedController = TextEditingController();
  final maximumController = TextEditingController();

  if (config.dimensions.isEmpty) {
    return null;
  }

  String dimension = config.dimensions.first.id;

  return showDialog<Assessment>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final selectedDimension = config.dimensionById(dimension);

          return AlertDialog(
            title: const Text('Nueva evaluación'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      hintText: 'Ej.: Examen parcial',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: dimension,
                    decoration: const InputDecoration(
                      labelText: 'Dimensión',
                      border: OutlineInputBorder(),
                    ),
                    items: config.dimensions
                        .map((item) => DropdownMenuItem<String>(
                              value: item.id,
                              child: Text(item.name),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          dimension = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: obtainedController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Obtenido',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: maximumController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Máximo',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      selectedDimension == null
                          ? 'Peso no disponible.'
                          : 'Peso de ${selectedDimension.name}: ${selectedDimension.weight} puntos.',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  final name = nameController.text.trim();

                  final obtained = double.tryParse(
                    obtainedController.text.trim().replaceAll(',', '.'),
                  );

                  final maximum = double.tryParse(
                    maximumController.text.trim().replaceAll(',', '.'),
                  );

                  if (name.isEmpty ||
                      obtained == null ||
                      maximum == null ||
                      maximum <= 0 ||
                      obtained < 0 ||
                      obtained > maximum) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Revisa los datos de la evaluación.')),
                    );
                    return;
                  }

                  Navigator.pop(
                    context,
                    Assessment(
                      id: generateId(),
                      name: name,
                      dimension: selectedDimension?.name ?? dimension,
                      dimensionId: selectedDimension?.id,
                      obtained: obtained,
                      maximum: maximum,
                    ),
                  );
                },
                child: const Text('Agregar'),
              ),
            ],
          );
        },
      );
    },
  );
}