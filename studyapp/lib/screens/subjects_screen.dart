import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/subjects_provider.dart';
import 'subject_notes_screen.dart';

class SubjectsScreen extends StatelessWidget {
  const SubjectsScreen({super.key});

  Future<void> _addSubject(BuildContext context) async {
    final provider = context.read<SubjectsProvider>();
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nueva materia'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) {
                  Navigator.pop(context, value);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (name == null) return;

    final added = await provider.addSubject(name);

    if (!added && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esa materia ya existe.')),
      );
    }
  }

  Future<void> _deleteSubject(BuildContext context, String subject) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar materia'),
          content: Text('¿Quieres eliminar "$subject"?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    if (context.mounted) {
      await context.read<SubjectsProvider>().deleteSubject(subject);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjects = context.watch<SubjectsProvider>().subjects;

    return Stack(
      children: [
        subjects.isEmpty
            ? const Center(
                child: Text('No tienes materias.\nAgrega tu primera materia.', textAlign: TextAlign.center),
              )
            : GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                itemCount: subjects.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.15,
                ),
                itemBuilder: (context, index) {
                  final subject = subjects[index];

                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SubjectNotesScreen(subject: subject)),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.menu_book, color: Color(0xFF2563EB), size: 38),
                            const SizedBox(height: 10),
                            Text(
                              subject,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              onPressed: () => _deleteSubject(context, subject),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton.extended(
            onPressed: () => _addSubject(context),
            icon: const Icon(Icons.add),
            label: const Text('Nueva materia'),
          ),
        ),
      ],
    );
  }
}