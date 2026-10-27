import 'dart:ui';

class Stroke {
  Stroke({
    required this.points,
    required this.color,
    required this.width,
    this.isEraser = false,
  });

  factory Stroke.fromJson(Map<String, dynamic> json) {
    return Stroke(
      points: [
        for (final p in (json['points'] as List<dynamic>))
          Offset((p[0] as num).toDouble(), (p[1] as num).toDouble()),
      ],
      color: Color(json['color'] as int),
      width: (json['width'] as num).toDouble(),
      isEraser: (json['eraser'] as bool?) ?? false,
    );
  }

  final List<Offset> points;
  final Color color;
  final double width;
  final bool isEraser;

  Stroke copy() => Stroke(
        points: List<Offset>.of(points),
        color: color,
        width: width,
        isEraser: isEraser,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'points': [for (final p in points) <double>[p.dx, p.dy]],
        'color': color.toARGB32(),
        'width': width,
        'eraser': isEraser,
      };
}

class Drawing {
  Drawing({
    required this.id,
    required this.title,
    required this.strokes,
    required this.updatedAt,
  });

  factory Drawing.fromJson(Map<String, dynamic> json) => Drawing(
        id: json['id'] as String,
        title: json['title'] as String,
        strokes: [
          for (final s in (json['strokes'] as List<dynamic>))
            Stroke.fromJson(s as Map<String, dynamic>),
        ],
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  final String id;
  final String title;
  final List<Stroke> strokes;
  final DateTime updatedAt;

  bool get isBlank => !strokes.any((stroke) => stroke.points.isNotEmpty);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'strokes': [for (final s in strokes) s.toJson()],
        'updatedAt': updatedAt.toIso8601String(),
      };
}
