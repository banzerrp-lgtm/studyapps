import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/subjects_provider.dart';
import '../providers/tasks_provider.dart';
import '../utils/formatters.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  Future<void> _addTask(BuildContext context) async {
    final tasksProvider = context.read<TasksProvider>();
    final subjects = context.read<SubjectsProvider>().subjects;

    final controller = TextEditingController();
    String selectedSubject = subjects.isNotEmpty ? subjects.first : 'General';
    String priority = 'Media';
    DateTime date = DateTime.now();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nueva tarea'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la tarea',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    if (subjects.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: selectedSubject,
                        decoration: const InputDecoration(labelText: 'Materia', border: OutlineInputBorder()),
                        items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedSubject = value;
                            });
                          }
                        },
                      ),
                    const SizedBox(height: 15),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_month),
                      title: const Text('Fecha'),
                      subtitle: Text(formatDate(date)),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: date,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );

                        if (picked != null) {
                          setDialogState(() {
                            date = picked;
                          });
                        }
                      },
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: priority,
                      decoration: const InputDecoration(labelText: 'Prioridad', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'Alta', child: Text('🔴 Alta')),
                        DropdownMenuItem(value: 'Media', child: Text('🟡 Media')),
                        DropdownMenuItem(value: 'Baja', child: Text('🟢 Baja')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            priority = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                FilledButton(
                  onPressed: () {
                    if (controller.text.trim().isEmpty) return;
                    Navigator.pop(context, true);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;

    await tasksProvider.addTask(
      title: controller.text.trim(),
      subject: selectedSubject,
      date: date,
      priority: priority,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasksProvider = context.watch<TasksProvider>();
    final tasks = tasksProvider.tasks;
    final pending = tasksProvider.pendingCount;

    return Stack(
      children: [
        Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(20, 5, 20, 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  const Icon(Icons.assignment_outlined, color: Color(0xFF2563EB), size: 35),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Mis tareas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('$pending pendientes'),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: tasks.isEmpty
                  ? const Center(child: Text('No tienes tareas todavía.'))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 5, 20, 100),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                          child: Row(
                            children: [
                              Checkbox(
                                value: task.completed,
                                onChanged: (_) => context.read<TasksProvider>().toggleTask(task),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        decoration: task.completed ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      '${task.subject} • ${formatDate(task.date)}',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'Prioridad: ${task.priority}',
                                      style: TextStyle(
                                        color: priorityColor(task.priority),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => context.read<TasksProvider>().deleteTask(task),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton.extended(
            onPressed: () => _addTask(context),
            icon: const Icon(Icons.add),
            label: const Text('Nueva tarea'),
          ),
        ),
      ],
    );
  }
}