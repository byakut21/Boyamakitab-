import 'dart:ui';

import 'picture.dart';

const int white = 0xFFFFFFFF;

/// Parmakla çizilmiş tek bir çizgi; noktalar resim koordinatlarındadır.
class BrushStroke {
  BrushStroke(this.color, this.points);

  final int color;
  final List<Offset> points;

  late final Path path = buildStrokePath(points);

  Map<String, Object> toJson() => {
    'c': color,
    'p': [
      for (final p in points) ...[p.dx.roundToDouble(), p.dy.roundToDouble()],
    ],
  };

  static BrushStroke fromJson(Map<String, dynamic> json) {
    final raw = (json['p'] as List).cast<num>();
    return BrushStroke(json['c'] as int, [
      for (var i = 0; i + 1 < raw.length; i += 2)
        Offset(raw[i].toDouble(), raw[i + 1].toDouble()),
    ]);
  }
}

/// Bir resmin o anki boyanmış hali.
class Artwork {
  const Artwork(this.fills, this.strokes);

  factory Artwork.blank(ColoringPicture picture) =>
      Artwork(List.filled(picture.regions.length, white), const []);

  final List<int> fills;
  final List<BrushStroke> strokes;

  Map<String, Object> toJson() => {
    'fills': fills,
    'strokes': [for (final s in strokes) s.toJson()],
  };

  static Artwork fromJson(Map<String, dynamic> json) =>
      Artwork((json['fills'] as List).cast<int>(), [
        for (final s in json['strokes'] as List)
          BrushStroke.fromJson(s as Map<String, dynamic>),
      ]);
}

/// Noktaları yumuşak bir eğriyle birleştirir.
Path buildStrokePath(List<Offset> pts) {
  final path = Path();
  if (pts.isEmpty) return path;
  path.moveTo(pts[0].dx, pts[0].dy);
  for (var i = 1; i < pts.length; i++) {
    final prev = pts[i - 1];
    final mid = (prev + pts[i]) / 2;
    path.quadraticBezierTo(prev.dx, prev.dy, mid.dx, mid.dy);
  }
  path.lineTo(pts.last.dx, pts.last.dy);
  return path;
}
