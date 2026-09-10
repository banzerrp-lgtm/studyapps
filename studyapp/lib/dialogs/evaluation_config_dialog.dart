import 'package:flutter/material.dart';

import '../models/evaluation_config.dart';
import '../utils/formatters.dart';
import '../utils/id_generator.dart';
import '../widgets/config_field.dart';

Future<EvaluationConfig?> showEvaluationConfigDialog(
  BuildContext context,
  EvaluationConfig current,
) async {
  final dimensions = current.dimensions.map((item) => item.copyWith()).toList();

  final nameControllers = <TextEditingController>[];
  final weightControllers = <TextEditingController>[];

  for (final dimension in dimensions) {
    nameControllers.add(TextEditingController(text: dimension.name));
    weightControllers.add(TextEditingController(text: formatNumber(dimension.weight)));
  }

  final minimum = TextEditingController(text: formatNumber(current.passingMinimum));

  return showDialog<EvaluationConfig>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          double parse(TextEditingController controller) {
            return double.tryParse(controller.text.trim().replaceAll(',', '.')) ?? 0;
          }

          double total = 0;
          for (final controller in weightControllers) {
            total += parse(controller);
          }

          final totalIsValid = (total - 100).abs() < 0.001;
          final minimumValue = parse(minimum);
          final minimumIsValid = minimumValue >= 0 && minimumValue <= 100;

          return AlertDialog(
            title: const Text('Configuración de evaluación'),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Personaliza las dimensiones de evaluación.',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Los pesos deben sumar exactamente 100 puntos.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(dimensions.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: nameControllers[index],
                                onChanged: (_) => setDialogState(() {}),
                                decoration: InputDecoration(
                                  labelText: 'Dimensión ${index + 1}',
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 95,
                              child: TextField(
                                controller: weightControllers[index],
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (_) => setDialogState(() {}),
                                decoration: const InputDecoration(
                                  labelText: 'Puntos',
                                  suffixText: 'pts',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              tooltip: 'Eliminar dimensión',
                              onPressed: dimensions.length > 1
                                  ? () {
                                      nameControllers[index].dispose();
                                      weightControllers[index].dispose();
                                      dimensions.removeAt(index);
                                      nameControllers.removeAt(index);
                                      weightControllers.removeAt(index);
                                      setDialogState(() {});
                                    }
                                  : null,
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final number = dimensions.length + 1;
                          final id = generateId();

                          dimensions.add(
                            EvaluationDimension(id: id, name: 'Dimensión $number', weight: 0),
                          );
                          nameControllers.add(TextEditingController(text: 'Dimensión $number'));
                          weightControllers.add(TextEditingController(text: '0'));

                          setDialogState(() {});
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar dimensión'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: totalIsValid
                            ? Colors.green.withValues(alpha: 0.08)
                            : Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            totalIsValid ? Icons.check_circle_outline : Icons.error_outline,
                            color: totalIsValid ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Total: ${formatNumber(total)} / 100',
                              style: TextStyle(
                                color: totalIsValid ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    ConfigField(
                      label: 'Mínimo para aprobar',
                      controller: minimum,
                      onChanged: () => setDialogState(() {}),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      minimumIsValid
                          ? 'Puntaje mínimo: ${formatNumber(minimumValue)}'
                          : 'El mínimo debe estar entre 0 y 100.',
                      style: TextStyle(
                        fontSize: 12,
                        color: minimumIsValid ? Colors.grey.shade600 : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        final defaults = [
                          EvaluationDimension(id: 'ser', name: 'Ser', weight: 10),
                          EvaluationDimension(id: 'saber', name: 'Saber', weight: 45),
                          EvaluationDimension(id: 'hacer', name: 'Hacer', weight: 40),
                          EvaluationDimension(id: 'autoevaluacion', name: 'Autoevaluación', weight: 5),
                        ];

                        for (final controller in nameControllers) {
                          controller.dispose();
                        }
                        for (final controller in weightControllers) {
                          controller.dispose();
                        }

                        dimensions.clear();
                        nameControllers.clear();
                        weightControllers.clear();

                        for (final item in defaults) {
                          dimensions.add(item);
                          nameControllers.add(TextEditingController(text: item.name));
                          weightControllers.add(TextEditingController(text: formatNumber(item.weight)));
                        }

                        minimum.text = '51';
                        setDialogState(() {});
                      },
                      icon: const Icon(Icons.restore),
                      label: const Text('Restablecer 10 / 45 / 40 / 5'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: totalIsValid && minimumIsValid && dimensions.isNotEmpty
                    ? () {
                        final updatedDimensions = <EvaluationDimension>[];
                        bool namesAreValid = true;

                        for (int i = 0; i < dimensions.length; i++) {
                          final name = nameControllers[i].text.trim();

                          if (name.isEmpty) {
                            namesAreValid = false;
                            break;
                          }

                          final old = dimensions[i];
                          updatedDimensions.add(
                            old.copyWith(name: name, weight: parse(weightControllers[i])),
                          );
                        }

                        if (!namesAreValid) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Todas las dimensiones deben tener un nombre.'),
                            ),
                          );
                          return;
                        }

                        Navigator.pop(
                          context,
                          current.copyWith(
                            dimensions: updatedDimensions,
                            passingMinimum: minimumValue,
                          ),
                        );
                      }
                    : null,
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      );
    },
  );
}