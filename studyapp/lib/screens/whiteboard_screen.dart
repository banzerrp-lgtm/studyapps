import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:scribble/scribble.dart';

class WhiteboardResult {
  final String? pngDataUri;
  final String? sketchJson;

  const WhiteboardResult({this.pngDataUri, this.sketchJson});
}

class WhiteboardScreen extends StatefulWidget {
  final String? sketchJson;

  const WhiteboardScreen({super.key, this.sketchJson});

  @override
  State<WhiteboardScreen> createState() => _WhiteboardScreenState();
}

class _WhiteboardScreenState extends State<WhiteboardScreen> {
  late final ScribbleNotifier notifier;
  double strokeWidth = 5;
  bool erasing = false;

  @override
  void initState() {
    super.initState();
    Sketch? sketch;
    final savedSketch = widget.sketchJson;
    if (savedSketch != null && savedSketch.isNotEmpty) {
      try {
        sketch = Sketch.fromJson(
          jsonDecode(savedSketch) as Map<String, dynamic>,
        );
      } catch (_) {
        sketch = null;
      }
    }
    notifier = ScribbleNotifier(sketch: sketch, widths: const [5, 10, 15]);
  }

  @override
  void dispose() {
    notifier.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (notifier.currentSketch.lines.isEmpty) {
      Navigator.pop(context, const WhiteboardResult());
      return;
    }

    final byteData = await notifier.renderImage(pixelRatio: 2);
    final png = byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );

    if (!mounted) return;
    Navigator.pop(
      context,
      WhiteboardResult(
        pngDataUri: 'data:image/png;base64,${base64Encode(png)}',
        sketchJson: jsonEncode(notifier.currentSketch.toJson()),
      ),
    );
  }

  Future<void> _clear() async {
    if (notifier.currentSketch.lines.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar pizarrón'),
        content: const Text('Se eliminarán todos los trazos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
    if (confirmed == true) notifier.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pizarrón'),
        actions: [
          IconButton(
            tooltip: 'Deshacer',
            icon: const Icon(Icons.undo),
            onPressed: notifier.undo,
          ),
          IconButton(
            tooltip: 'Rehacer',
            icon: const Icon(Icons.redo),
            onPressed: notifier.redo,
          ),
          IconButton(
            tooltip: 'Limpiar todo',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: _clear,
          ),
          IconButton(
            tooltip: 'Guardar dibujo',
            icon: const Icon(Icons.check),
            onPressed: _save,
          ),
        ],
      ),
      body: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Lápiz',
                    isSelected: !erasing,
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      setState(() => erasing = false);
                      notifier.setColor(Colors.black);
                    },
                  ),
                  IconButton(
                    tooltip: 'Borrador',
                    isSelected: erasing,
                    icon: const Icon(Icons.auto_fix_normal_outlined),
                    onPressed: () {
                      setState(() => erasing = true);
                      notifier.setEraser();
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text('Grosor'),
                  Expanded(
                    child: Slider(
                      min: 2,
                      max: 24,
                      divisions: 11,
                      value: strokeWidth,
                      label: strokeWidth.round().toString(),
                      onChanged: (value) {
                        setState(() => strokeWidth = value);
                        notifier.setStrokeWidth(value);
                      },
                    ),
                  ),
                  Text('${strokeWidth.round()} px'),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: Scribble(notifier: notifier),
            ),
          ),
        ],
      ),
    );
  }
}
