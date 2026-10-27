import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'models.dart';

final DrawingStore store = DrawingStore();

class DrawingStore extends ChangeNotifier {
  final List<Drawing> _drawings = <Drawing>[];
  bool _loaded = false;

  bool get loaded => _loaded;

  List<Drawing> get drawings => List.unmodifiable(_drawings);

  Directory get _dir =>
      Directory('${Directory.systemTemp.path}${Platform.pathSeparator}sketchpad');

  File get _file => File('${_dir.path}${Platform.pathSeparator}drawings.json');

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final file = _file;
      if (await file.exists()) {
        final raw = jsonDecode(await file.readAsString());
        if (raw is List) {
          _drawings
            ..clear()
            ..addAll([
              for (final item in raw) Drawing.fromJson(item as Map<String, dynamic>),
            ]);
          _sort();
        }
      }
    } catch (_) {
      // Corrupt or unreadable data: start with an empty in-memory gallery.
    }
    notifyListeners();
  }

  Future<void> save(Drawing drawing) async {
    final index = _drawings.indexWhere((d) => d.id == drawing.id);
    if (index >= 0) {
      _drawings[index] = drawing;
    } else {
      _drawings.insert(0, drawing);
    }
    _sort();
    notifyListeners();
    await _persist();
  }

  Future<void> delete(String id) async {
    _drawings.removeWhere((d) => d.id == id);
    notifyListeners();
    await _persist();
  }

  Future<String> exportPng(Uint8List bytes) async {
    await _dir.create(recursive: true);
    final path =
        '${_dir.path}${Platform.pathSeparator}sketch_${DateTime.now().millisecondsSinceEpoch}.png';
    await File(path).writeAsBytes(bytes, flush: true);
    return path;
  }

  void _sort() => _drawings.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  Future<void> _persist() async {
    try {
      await _dir.create(recursive: true);
      final data = jsonEncode([for (final d in _drawings) d.toJson()]);
      await _file.writeAsString(data, flush: true);
    } catch (_) {
      // Persistence is best-effort; the in-memory gallery still works.
    }
  }
}
