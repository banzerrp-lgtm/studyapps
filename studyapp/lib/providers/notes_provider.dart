import 'package:flutter/foundation.dart';

import '../models/note.dart';
import '../services/database_service.dart';

class NotesProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  List<Note> _notes = [];
  bool _loading = true;

  List<Note> get notes => List.unmodifiable(_notes);
  bool get loading => _loading;

  List<Note> notesFor(String subject) {
    final filtered = _notes.where((note) => note.subject == subject).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  Future<void> load() async {
    try {
      _notes = await _db.loadNotes();
    } catch (error, stackTrace) {
      debugPrint('No se pudieron cargar los apuntes: $error\n$stackTrace');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> saveNote(Note note) async {
    _notes.removeWhere((item) => item.id == note.id);
    _notes.add(note);
    notifyListeners();

    await _db.upsertNote(note);
  }

  Future<void> deleteNote(Note note) async {
    _notes.removeWhere((item) => item.id == note.id);
    notifyListeners();

    await _db.deleteNote(note.id);
  }
}
