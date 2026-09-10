import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../utils/formatters.dart';
import 'note_editor_screen.dart';

class SubjectNotesScreen extends StatelessWidget {
  final String subject;

  const SubjectNotesScreen({super.key, required this.subject});

  Future<void> _openEditor(BuildContext context, {Note? existing}) async {
    final result = await Navigator.push<Note>(
      context,
      MaterialPageRoute(builder: (_) => NoteEditorScreen(subject: subject, existing: existing)),
    );

    if (result == null) return;

    if (context.mounted) {
      await context.read<NotesProvider>().saveNote(result);
    }
  }

  Future<void> _deleteNote(BuildContext context, Note note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar apunte'),
          content: Text('¿Quieres eliminar "${note.title}"?'),
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
      await context.read<NotesProvider>().deleteNote(note);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();
    final notes = notesProvider.notesFor(subject);

    return Scaffold(
      appBar: AppBar(title: Text(subject)),
      body: notesProvider.loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                notes.isEmpty
                    ? const Center(
                        child: Text('Todavía no hay apuntes.\nAgrega el primero.', textAlign: TextAlign.center),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: notes.length,
                        itemBuilder: (context, index) {
                          final note = notes[index];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(
                                note.title.isEmpty ? '(Sin título)' : note.title,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(formatDate(note.date)),
                              onTap: () => _openEditor(context, existing: note),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _deleteNote(context, note),
                              ),
                            ),
                          );
                        },
                      ),
                Positioned(
                  right: 20,
                  bottom: 20,
                  child: FloatingActionButton.extended(
                    onPressed: () => _openEditor(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Nuevo apunte'),
                  ),
                ),
              ],
            ),
    );
  }
}