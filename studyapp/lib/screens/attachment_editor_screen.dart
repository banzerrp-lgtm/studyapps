import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/attachment.dart';

class AttachmentEditorScreen extends StatefulWidget {
  final List<Attachment> initialAttachments;

  const AttachmentEditorScreen({super.key, this.initialAttachments = const []});

  @override
  State<AttachmentEditorScreen> createState() => _AttachmentEditorScreenState();
}

class _AttachmentEditorScreenState extends State<AttachmentEditorScreen> {
  late List<Attachment> attachments;
  int selectedIndex = 0;

  Attachment? get selected =>
      attachments.isEmpty ? null : attachments[selectedIndex];

  @override
  void initState() {
    super.initState();
    attachments = [...widget.initialAttachments];
  }

  Future<void> _pick(AttachmentType type) async {
    final result = await FilePicker.pickFile(
      type: type == AttachmentType.image ? FileType.image : FileType.custom,
      allowedExtensions: type == AttachmentType.pdf ? ['pdf'] : null,
    );
    if (result == null) return;
    final bytes = await result.readAsBytes();
    if (bytes.isEmpty) return;

    setState(() {
      attachments.add(
        Attachment(
          name: result.name,
          type: type,
          dataBase64: base64Encode(bytes),
        ),
      );
      selectedIndex = attachments.length - 1;
    });
  }

  Future<void> _showMenu() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Imagen'),
              onTap: () {
                Navigator.pop(context);
                _pick(AttachmentType.image);
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('Documento PDF'),
              onTap: () {
                Navigator.pop(context);
                _pick(AttachmentType.pdf);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _updateSelected(Attachment value) {
    setState(() => attachments[selectedIndex] = value);
  }

  Future<void> _removeAttachment(int index) async {
    final attachment = attachments[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar adjunto'),
        content: Text('¿Quieres eliminar "${attachment.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() {
      attachments.removeAt(index);
      if (attachments.isEmpty) {
        selectedIndex = 0;
      } else if (selectedIndex >= attachments.length) {
        selectedIndex = attachments.length - 1;
      } else if (index < selectedIndex) {
        selectedIndex--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => Navigator.pop(context, attachments),
        ),
        title: const Text('Adjuntos'),
        actions: [
          IconButton(
            tooltip: 'Adjuntar archivo',
            icon: const Icon(Icons.attach_file),
            onPressed: _showMenu,
          ),
          IconButton(
            tooltip: 'Guardar adjuntos',
            icon: const Icon(Icons.check),
            onPressed: () => Navigator.pop(context, attachments),
          ),
        ],
      ),
      body: attachments.isEmpty
          ? Center(
              child: FilledButton.icon(
                onPressed: _showMenu,
                icon: const Icon(Icons.attach_file),
                label: const Text('Añadir imagen o PDF'),
              ),
            )
          : Column(
              children: [
                SizedBox(
                  height: 76,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(12),
                    itemCount: attachments.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InputChip(
                        selected: index == selectedIndex,
                        label: Text(attachments[index].name),
                        avatar: Icon(
                          attachments[index].isPdf
                              ? Icons.picture_as_pdf
                              : Icons.image,
                          size: 18,
                        ),
                        onDeleted: () => _removeAttachment(index),
                        onSelected: (_) =>
                            setState(() => selectedIndex = index),
                        deleteIcon: const Icon(Icons.close, size: 16),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: AttachmentCanvas(
                    key: ValueKey(selected!.id),
                    attachment: selected!,
                    onChanged: _updateSelected,
                  ),
                ),
              ],
            ),
    );
  }
}

class AttachmentCanvas extends StatefulWidget {
  final Attachment attachment;
  final ValueChanged<Attachment> onChanged;

  const AttachmentCanvas({
    super.key,
    required this.attachment,
    required this.onChanged,
  });

  @override
  State<AttachmentCanvas> createState() => _AttachmentCanvasState();
}

class _AttachmentCanvasState extends State<AttachmentCanvas> {
  late List<AttachmentAnnotation> annotations;
  int page = 1;
  bool editing = false;
  AttachmentAnnotationType tool = AttachmentAnnotationType.draw;
  double width = 4;
  PdfDocument? document;
  PdfPageImage? pageImage;
  String? pdfError;

  @override
  void initState() {
    super.initState();
    annotations = [...widget.attachment.annotations];
    if (widget.attachment.isPdf) {
      if (kIsWeb) {
        pdfError = 'El visor interno no está disponible en Chrome.';
      } else {
        _loadPdf();
      }
    }
  }

  @override
  void dispose() {
    document?.close();
    super.dispose();
  }

  Future<void> _loadPdf() async {
    try {
      final bytes = base64Decode(widget.attachment.dataBase64);
      document = await PdfDocument.openData(Uint8List.fromList(bytes));
      await _loadPage();
    } catch (error) {
      if (!mounted) return;
      setState(() => pdfError = error.toString());
    }
  }

  Future<void> _openPdfInApp() async {
    if (kIsWeb) {
      final uri = Uri.parse(
        'data:application/pdf;base64,${widget.attachment.dataBase64}',
      );
      final launched = await launchUrl(uri, webOnlyWindowName: '_blank');
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el PDF.')),
        );
      }
      return;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/studyapp_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(base64Decode(widget.attachment.dataBase64));

      final result = await OpenFile.open(file.path);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el PDF.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el PDF.')),
        );
      }
    }
  }

  Future<void> _loadPage() async {
    final pdf = document;
    if (pdf == null) return;
    final loadedPage = await pdf.getPage(page);
    final renderWidth = loadedPage.width.clamp(1, 1200).toDouble();
    final renderHeight = renderWidth * loadedPage.height / loadedPage.width;
    final image = await loadedPage.render(
      width: renderWidth,
      height: renderHeight,
      format: PdfPageImageFormat.png,
    );
    await loadedPage.close();
    if (!mounted) return;
    setState(() => pageImage = image);
  }

  void _finishStroke(List<Offset> points) {
    if (points.isEmpty) return;
    final annotation = AttachmentAnnotation(
      page: widget.attachment.isPdf ? page : 1,
      type: tool,
      points: points,
      color: tool == AttachmentAnnotationType.highlight
          ? 0x66FFEB3B
          : 0xFF1565C0,
      width: tool == AttachmentAnnotationType.highlight ? 18 : width,
    );
    final updated = [...annotations, annotation];
    setState(() => annotations = updated);
    widget.onChanged(widget.attachment.copyWith(annotations: updated));
  }

  Widget _baseViewer() {
    if (widget.attachment.isPdf) {
      if (pdfError != null) {
        return Center(
          child: FilledButton.icon(
            onPressed: _openPdfInApp,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Abrir PDF para leer'),
          ),
        );
      }
      final image = pageImage;
      if (image == null) {
        return const Center(child: CircularProgressIndicator());
      }
      return Image.memory(image.bytes, fit: BoxFit.contain);
    }
    final bytes = base64Decode(widget.attachment.dataBase64);
    return Image.memory(Uint8List.fromList(bytes), fit: BoxFit.contain);
  }

  @override
  Widget build(BuildContext context) {
    final activeAnnotations = annotations.where(
      (item) => item.page == (widget.attachment.isPdf ? page : 1),
    );
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 4,
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  label: Text('Leer'),
                  icon: Icon(Icons.visibility),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('Anotar'),
                  icon: Icon(Icons.edit),
                ),
              ],
              selected: {editing},
              onSelectionChanged: (value) =>
                  setState(() => editing = value.first),
            ),
            if (editing)
              SegmentedButton<AttachmentAnnotationType>(
                segments: const [
                  ButtonSegment(
                    value: AttachmentAnnotationType.draw,
                    icon: Icon(Icons.edit),
                  ),
                  ButtonSegment(
                    value: AttachmentAnnotationType.highlight,
                    icon: Icon(Icons.highlight),
                  ),
                  ButtonSegment(
                    value: AttachmentAnnotationType.underline,
                    icon: Icon(Icons.format_underline),
                  ),
                ],
                selected: {tool},
                onSelectionChanged: (value) =>
                    setState(() => tool = value.first),
              ),
          ],
        ),
        if (widget.attachment.isPdf)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Página anterior',
                onPressed: page > 1
                    ? () {
                        setState(() => page--);
                        _loadPage();
                      }
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text('Página $page/${document?.pagesCount ?? '-'}'),
              IconButton(
                tooltip: 'Página siguiente',
                onPressed: document != null && page < document!.pagesCount
                    ? () {
                        setState(() => page++);
                        _loadPage();
                      }
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              fit: StackFit.expand,
              children: [
                _baseViewer(),
                CustomPaint(painter: _AnnotationPainter(activeAnnotations)),
                if (editing)
                  _DrawingLayer(onStroke: _finishStroke, width: width),
              ],
            ),
          ),
        ),
        if (editing)
          Slider(
            min: 2,
            max: 24,
            divisions: 11,
            value: width,
            label: '${width.round()} px',
            onChanged: (value) => setState(() => width = value),
          ),
      ],
    );
  }
}

class _DrawingLayer extends StatefulWidget {
  final ValueChanged<List<Offset>> onStroke;
  final double width;

  const _DrawingLayer({required this.onStroke, required this.width});

  @override
  State<_DrawingLayer> createState() => _DrawingLayerState();
}

class _DrawingLayerState extends State<_DrawingLayer> {
  final points = <Offset>[];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (details) => setState(
        () => points
          ..clear()
          ..add(details.localPosition),
      ),
      onPanUpdate: (details) =>
          setState(() => points.add(details.localPosition)),
      onPanEnd: (_) {
        widget.onStroke([...points]);
        setState(points.clear);
      },
      child: CustomPaint(painter: _LiveStrokePainter(points, widget.width)),
    );
  }
}

class _LiveStrokePainter extends CustomPainter {
  final List<Offset> points;
  final double width;
  _LiveStrokePainter(this.points, this.width);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    for (var i = 1; i < points.length; i++) {
      canvas.drawLine(points[i - 1], points[i], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LiveStrokePainter oldDelegate) => true;
}

class _AnnotationPainter extends CustomPainter {
  final Iterable<AttachmentAnnotation> annotations;
  _AnnotationPainter(this.annotations);

  @override
  void paint(Canvas canvas, Size size) {
    for (final annotation in annotations) {
      if (annotation.points.isEmpty) continue;
      final paint = Paint()
        ..color = Color(annotation.color)
        ..strokeWidth = annotation.width
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      for (var i = 1; i < annotation.points.length; i++) {
        canvas.drawLine(annotation.points[i - 1], annotation.points[i], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AnnotationPainter oldDelegate) => true;
}
