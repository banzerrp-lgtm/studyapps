import 'package:flutter/material.dart';

import '../models/assessment.dart';
import '../models/evaluation_config.dart';
import '../models/term_grade.dart';
import '../services/grade_service.dart';
import '../utils/formatters.dart';
import '../utils/id_generator.dart';
import 'assessment_dialog.dart';

Future<TermGrade?> showTermGradeEditor(
  BuildContext context, {
  required String subject,
  required int trimester,
  required EvaluationConfig config,
  required TermGrade? existing,
}) async {
  String mode = existing?.mode ?? 'direct';

  final directController = TextEditingController(
    text: existing?.directScore == null ? '' : formatNumber(existing!.directScore!),
  );

  List<Assessment> assessments = existing == null
      ? []
      : existing.assessments
          .map((item) => Assessment(
                id: item.id,
                name: item.name,
                dimension: item.dimension,
                dimensionId: item.dimensionId,
                obtained: item.obtained,
                maximum: item.maximum,
              ))
          .toList();

  return showDialog<TermGrade>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final preview = TermGrade(
            id: existing?.id ?? generateId(),
            subject: subject,
            trimester: trimester,
            mode: mode,
            directScore: double.tryParse(
              directController.text.trim().replaceAll(',', '.'),
            ),
            assessments: assessments,
          );

          final score = GradeService.calculateTermScore(preview, config);

          return AlertDialog(
            title: Text('$trimester.º trimestre'),
            content: SizedBox(
              width: 550,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      subject,
                      style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 14),
                    const Text('Método de registro', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'direct',
                          label: Text('Nota directa'),
                          icon: Icon(Icons.edit_note),
                        ),
                        ButtonSegment(
                          value: 'detailed',
                          label: Text('Detallada'),
                          icon: Icon(Icons.calculate_outlined),
                        ),
                      ],
                      selected: {mode},
                      onSelectionChanged: (selection) {
                        setDialogState(() {
                          mode = selection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 18),
                    if (mode == 'direct')
                      TextField(
                        controller: directController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setDialogState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Nota final del trimestre',
                          suffixText: '/ ${formatNumber(config.scaleMax)}',
                          border: const OutlineInputBorder(),
                        ),
                      )
                    else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'Puedes poner evaluaciones sobre 40, 30, 20, 15 o cualquier otro máximo. StudyApp las convierte al peso de la dimensión.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (assessments.isEmpty)
                        Text(
                          'Todavía no hay evaluaciones.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ...assessments.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.assignment_outlined, size: 20),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text(
                                      '${item.dimension} • ${formatNumber(item.obtained)} / ${formatNumber(item.maximum)}',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setDialogState(() {
                                    assessments.removeAt(index);
                                  });
                                },
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        );
                      }),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final assessment = await showAssessmentDialog(context, config);

                          if (assessment != null) {
                            setDialogState(() {
                              assessments.add(assessment);
                            });
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar evaluación'),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text('Nota calculada', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Text(
                            '${formatNumber(score)} / ${formatNumber(config.scaleMax)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
                          ),
                        ],
                      ),
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
                onPressed: () {
                  if (mode == 'direct') {
                    final value = double.tryParse(
                      directController.text.trim().replaceAll(',', '.'),
                    );

                    if (value == null || value < 0 || value > config.scaleMax) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'La nota debe estar entre 0 y ${formatNumber(config.scaleMax)}.',
                          ),
                        ),
                      );
                      return;
                    }
                  }

                  if (mode == 'detailed' && assessments.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Agrega al menos una evaluación.')),
                    );
                    return;
                  }

                  final grade = TermGrade(
                    id: existing?.id ?? generateId(),
                    subject: subject,
                    trimester: trimester,
                    mode: mode,
                    directScore: mode == 'direct'
                        ? double.tryParse(directController.text.trim().replaceAll(',', '.'))
                        : null,
                    assessments: mode == 'detailed' ? assessments : [],
                  );

                  Navigator.pop(context, grade);
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      );
    },
  );
}