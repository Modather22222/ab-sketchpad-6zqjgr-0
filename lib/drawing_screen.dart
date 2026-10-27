import 'dart:ui' as ui show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;

import 'models.dart';
import 'painter.dart';
import 'store.dart';

enum Tool { brush, eraser }

class DrawingScreen extends StatefulWidget {
  const DrawingScreen({super.key, this.drawing});

  final Drawing? drawing;

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  static const List<Color> _palette = [
    Colors.black,
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.brown,
  ];

  final List<Stroke> _strokes = <Stroke>[];
  final List<Stroke> _redoStack = <Stroke>[];
  final GlobalKey _canvasKey = GlobalKey();

  Tool _tool = Tool.brush;
  Color _color = Colors.black;
  double _width = 4;
  Stroke? _pending;
  String? _id;
  String? _title;

  @override
  void initState() {
    super.initState();
    // Work on copies so reopening and discarding never mutates saved sketches.
    if (widget.drawing != null) {
      _strokes.addAll([for (final s in widget.drawing!.strokes) s.copy()]);
      _id = widget.drawing!.id;
      _title = widget.drawing!.title;
    }
    _color = _palette.first;
  }

  void _onPanStart(DragStartDetails details) {
    _redoStack.clear();
    _pending = Stroke(
      points: [details.localPosition],
      color: _color,
      width: _width,
      isEraser: _tool == Tool.eraser,
    );
    _strokes.add(_pending!);
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final stroke = _pending;
    if (stroke == null) return;
    final last = stroke.points.last;
    if ((details.localPosition - last).distance < 1.5) return;
    stroke.points.add(details.localPosition);
    setState(() {});
  }

  void _onPanEnd(DragEndDetails details) {
    _pending = null;
    setState(() {});
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    _redoStack.add(_strokes.removeLast());
    setState(() {});
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    _strokes.add(_redoStack.removeLast());
    setState(() {});
  }

  void _clear() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear canvas?'),
        content: const Text('This removes all strokes from the canvas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _strokes.clear();
                _redoStack.clear();
              });
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final now = DateTime.now();
    _id ??= 'd${now.microsecondsSinceEpoch}';
    _title ??= _defaultTitle(now);
    await store.save(
      Drawing(
        id: _id!,
        title: _title!,
        strokes: [for (final s in _strokes) s.copy()],
        updatedAt: now,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved "$_title" to your sketches.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _export() async {
    try {
      final boundary = _canvasKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) return;
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) return;
      final path = await store.exportPng(data.buffer.asUint8List());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported PNG: $path'),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $error')),
      );
    }
  }

  String _defaultTitle(DateTime now) {
    final minute = now.minute.toString().padLeft(2, '0');
    return 'Drawing ${now.month}/${now.day} ${now.hour}:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title ?? 'New sketch'),
        actions: [
          IconButton(
            tooltip: 'Undo',
            onPressed: _strokes.isNotEmpty ? _undo : null,
            icon: const Icon(Icons.undo),
          ),
          IconButton(
            tooltip: 'Redo',
            onPressed: _redoStack.isNotEmpty ? _redo : null,
            icon: const Icon(Icons.redo),
          ),
          IconButton(
            tooltip: 'Save',
            onPressed: _strokes.isNotEmpty ? _save : null,
            icon: const Icon(Icons.save_outlined),
          ),
          IconButton(
            tooltip: 'Export PNG',
            onPressed: _strokes.isNotEmpty ? _export : null,
            icon: const Icon(Icons.ios_share),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: RepaintBoundary(
            key: _canvasKey,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: Container(
                color: kCanvasColor,
                child: CustomPaint(
                  painter: StrokePainter(strokes: _strokes),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildToolbar(context),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    final highlight = Theme.of(context).colorScheme.primary;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<Tool>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: Tool.brush,
                        icon: Icon(Icons.brush),
                        label: Text('Brush'),
                      ),
                      ButtonSegment(
                        value: Tool.eraser,
                        icon: Icon(Icons.cleaning_services),
                        label: Text('Erase'),
                      ),
                    ],
                    selected: {_tool},
                    onSelectionChanged: (selection) =>
                        setState(() => _tool = selection.first),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Clear canvas',
                  onPressed: _strokes.isNotEmpty ? _clear : null,
                  icon: const Icon(Icons.restart_alt),
                ),
              ],
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  const SizedBox(width: 4),
                  for (final color in _palette)
                    GestureDetector(
                      onTap: () => setState(() {
                        _color = color;
                        _tool = Tool.brush;
                      }),
                      child: Container(
                        width: 32,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 6),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _tool == Tool.brush && _color == color
                                ? highlight
                                : Colors.grey,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
            Row(
              children: [
                const Icon(Icons.line_weight, size: 18),
                Expanded(
                  child: Slider(
                    value: _width,
                    min: 2,
                    max: 24,
                    divisions: 11,
                    label: _width.toStringAsFixed(0),
                    onChanged: (value) => setState(() => _width = value),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
