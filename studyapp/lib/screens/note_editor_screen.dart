import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../models/attachment.dart';
import '../models/note.dart';
import '../utils/id_generator.dart';
import 'attachment_editor_screen.dart';
import 'whiteboard_screen.dart';

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
  String? drawingPng;
  String? drawingJson;
  late List<Attachment> attachments;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.existing?.title ?? '');
    quillController = _buildQuillController();
    drawingJson = widget.existing?.drawingJson;
    drawingPng = widget.existing?.files.cast<String?>().firstWhere(
      (file) => file?.startsWith('data:image/png;base64,') ?? false,
      orElse: () => null,
    );
    attachments = [...(widget.existing?.attachments ?? const [])];
  }

  QuillController _buildQuillController() {
    final content = widget.existing?.content;
    if (content == null || content.isEmpty) return QuillController.basic();
    try {
      return QuillController(
        document: Document.fromJson(jsonDecode(content)),
        selection: const TextSelection.collapsed(offset: 0),
      );
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
    final files = [
      ...(widget.existing?.files ?? const <String>[]).where(
        (file) => !file.startsWith('data:image/png;base64,'),
      ),
      ?drawingPng,
    ];
    Navigator.pop(
      context,
      Note(
        id: widget.existing?.id ?? generateId(),
        subject: widget.subject,
        title: titleController.text.trim().isEmpty
            ? 'Sin título'
            : titleController.text.trim(),
        content: jsonEncode(quillController.document.toDelta().toJson()),
        date: widget.existing?.date ?? DateTime.now(),
        files: files,
        drawingJson: drawingJson,
        attachments: attachments,
      ),
    );
  }

  Future<void> _openWhiteboard() async {
    final result = await Navigator.push<WhiteboardResult>(
      context,
      MaterialPageRoute(
        builder: (_) => WhiteboardScreen(sketchJson: drawingJson),
      ),
    );
    if (result == null) return;
    setState(() {
      drawingPng = result.pngDataUri;
      drawingJson = result.sketchJson;
    });
  }

  Future<void> _openAttachments() async {
    final result = await Navigator.push<List<Attachment>>(
      context,
      MaterialPageRoute(
        builder: (_) => AttachmentEditorScreen(initialAttachments: attachments),
      ),
    );
    if (result != null) setState(() => attachments = result);
  }

  Uint8List? get _drawingBytes {
    final value = drawingPng;
    if (value == null || !value.startsWith('data:image/png;base64,')) {
      return null;
    }
    try {
      return base64Decode(value.substring('data:image/png;base64,'.length));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject),
        actions: [
          IconButton(
            tooltip: 'Abrir pizarrón',
            icon: Icon(drawingPng == null ? Icons.draw_outlined : Icons.draw),
            onPressed: _openWhiteboard,
          ),
          IconButton(
            tooltip: 'Adjuntos',
            icon: Badge(
              isLabelVisible: attachments.isNotEmpty,
              label: Text('${attachments.length}'),
              child: const Icon(Icons.attach_file),
            ),
            onPressed: _openAttachments,
          ),
          IconButton(icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: titleController,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  hintText: 'Título del apunte',
                  border: InputBorder.none,
                ),
              ),
            ),
            const Divider(height: 1),
            const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.subject), text: 'Texto'),
                Tab(icon: Icon(Icons.draw_outlined), text: 'Pizarrón'),
                Tab(icon: Icon(Icons.attach_file), text: 'Adjuntos'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildTextTab(),
                  _buildWhiteboardTab(),
                  _buildAttachmentsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextTab() {
    return Column(
      children: [
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
    );
  }

  Widget _buildWhiteboardTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Card(
              clipBehavior: Clip.antiAlias,
              margin: EdgeInsets.zero,
              child: _drawingBytes == null
                  ? const Center(child: Text('Todavía no hay un dibujo.'))
                  : Image.memory(_drawingBytes!, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _openWhiteboard,
            icon: const Icon(Icons.edit),
            label: Text(
              _drawingBytes == null ? 'Abrir pizarrón' : 'Editar dibujo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: _drawingBytes == null && attachments.isEmpty
                ? const Center(child: Text('Todavía no hay adjuntos.'))
                : ListView(
                    children: [
                      if (_drawingBytes != null)
                        ListTile(
                          leading: SizedBox(
                            width: 56,
                            height: 56,
                            child: Image.memory(
                              _drawingBytes!,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: const Text('Dibujo del pizarrón'),
                          subtitle: const Text('Imagen guardada'),
                          onTap: _openWhiteboard,
                        ),
                      ...attachments.map(
                        (attachment) => ListTile(
                          leading: _AttachmentThumbnail(attachment: attachment),
                          title: Text(attachment.name),
                          subtitle: Text(
                            attachment.annotations.isEmpty
                                ? 'Solo lectura'
                                : '${attachment.annotations.length} anotaciones',
                          ),
                          onTap: _openAttachments,
                        ),
                      ),
                    ],
                  ),
          ),
          FilledButton.icon(
            onPressed: _openAttachments,
            icon: const Icon(Icons.attach_file),
            label: const Text('Gestionar adjuntos'),
          ),
        ],
      ),
    );
  }
}

class _AttachmentThumbnail extends StatelessWidget {
  final Attachment attachment;

  const _AttachmentThumbnail({required this.attachment});

  @override
  Widget build(BuildContext context) {
    if (attachment.isPdf) {
      return const SizedBox(
        width: 56,
        height: 56,
        child: Icon(Icons.picture_as_pdf, size: 32),
      );
    }
    final encoded = attachment.renderedBase64 ?? attachment.dataBase64;
    try {
      return SizedBox(
        width: 56,
        height: 56,
        child: Image.memory(
          base64Decode(encoded),
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image_outlined),
        ),
      );
    } catch (_) {
      return const SizedBox(
        width: 56,
        height: 56,
        child: Icon(Icons.broken_image_outlined),
      );
    }
  }
}
