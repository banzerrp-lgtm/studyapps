import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../models/note.dart';
import '../utils/id_generator.dart';

class NoteEditorScreen extends StatefulWidget {
  final String subject;
  final Note? existing;

  const NoteEditorScreen({super.key, required this.subject, this.existing});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final TextEditingController titleController;
  late final QuillController quillController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.existing?.title ?? '');
    quillController = _buildQuillController();
  }

  QuillController _buildQuillController() {
    final content = widget.existing?.content;

    if (content == null || content.isEmpty) {
      return QuillController.basic();
    }

    try {
      final document = Document.fromJson(jsonDecode(content));
      return QuillController(document: document, selection: const TextSelection.collapsed(offset: 0));
    } catch (_) {
      return QuillController.basic();
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    quillController.dispose();
    super.dispose();
  }

  void _save() {
    final title = titleController.text.trim();
    final contentJson = jsonEncode(quillController.document.toDelta().toJson());

    final note = Note(
      id: widget.existing?.id ?? generateId(),
      subject: widget.subject,
      title: title.isEmpty ? 'Sin título' : title,
      content: contentJson,
      date: widget.existing?.date ?? DateTime.now(),
      files: widget.existing?.files ?? const [],
    );

    Navigator.pop(context, note);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject),
        actions: [IconButton(icon: const Icon(Icons.check), onPressed: _save)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: titleController,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(hintText: 'Título del apunte', border: InputBorder.none),
            ),
          ),
          const Divider(height: 1),
          QuillSimpleToolbar(
            controller: quillController,
            config: const QuillSimpleToolbarConfig(
              showFontFamily: false,
              showFontSize: false,
              showColorButton: false,
              showBackgroundColorButton: false,
              showClearFormat: false,
              showCodeBlock: false,
              showQuote: false,
              showIndent: false,
              showLink: false,
              showSearchButton: false,
              showSubscript: false,
              showSuperscript: false,
              showStrikeThrough: false,
              showInlineCode: false,
              showAlignmentButtons: false,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: QuillEditor.basic(
                controller: quillController,
                config: const QuillEditorConfig(padding: EdgeInsets.zero),
              ),
            ),
          ),
        ],
      ),
    );
  }
}