import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'models.dart';

const Color kCanvasColor = Color(0xFFFFFFFF);

void paintStroke(Canvas canvas, Stroke stroke) {
  final points = stroke.points;
  if (points.isEmpty) return;
  final paint = Paint()
    ..color = stroke.isEraser ? kCanvasColor : stroke.color
    ..strokeWidth = stroke.width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;
  if (points.length == 1) {
    canvas.drawCircle(
      points.single,
      stroke.width / 2,
      paint..style = PaintingStyle.fill,
    );
    return;
  }
  final path = Path()..moveTo(points.first.dx, points.first.dy);
  for (final p in points.skip(1)) {
    path.lineTo(p.dx, p.dy);
  }
  canvas.drawPath(path, paint);
}

Rect _boundsOf(List<Stroke> strokes) {
  Rect? bounds;
  for (final stroke in strokes) {
    for (final point in stroke.points) {
      final current = bounds;
      bounds = current == null
          ? Rect.fromPoints(point, point)
          : current.expandToInclude(Rect.fromPoints(point, point));
    }
  }
  return bounds ?? Rect.zero;
}

class StrokePainter extends CustomPainter {
  StrokePainter({required this.strokes});

  final List<Stroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      paintStroke(canvas, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant StrokePainter oldDelegate) => true;
}

class DrawingThumbnailPainter extends CustomPainter {
  DrawingThumbnailPainter({required this.strokes});

  final List<Stroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = _boundsOf(strokes);
    if (bounds.isEmpty) return;
    const inset = 10.0;
    final bw = bounds.width == 0 ? 1.0 : bounds.width;
    final bh = bounds.height == 0 ? 1.0 : bounds.height;
    final scale = math.min(
      (size.width - inset * 2) / bw,
      (size.height - inset * 2) / bh,
    );
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);
    canvas.translate(-bounds.center.dx, -bounds.center.dy);
    for (final stroke in strokes) {
      paintStroke(canvas, stroke);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant DrawingThumbnailPainter oldDelegate) =>
      !identical(oldDelegate.strokes, strokes);
}
