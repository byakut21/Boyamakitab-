import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart' show HSVColor;

import '../model/artwork.dart';
import '../model/picture.dart';

const Color outlineColor = Color(0xFF2B2B2B);

/// Boyamaları çizen ortak kod: hem ana ekrandaki küçük resimler hem boyama ekranı kullanır.
class ArtRenderer {
  ArtRenderer._();

  static const _area = Rect.fromLTWH(0, 0, canvasSize, canvasSize);

  static final _outline = Paint()
    ..style = PaintingStyle.stroke
    ..color = outlineColor
    ..strokeWidth = outlineWidth
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  /// Beyaz zemin + sırayla tüm işlemler. Silgi, zemine kadar siler.
  static void paintArt(Canvas canvas, ColoringPicture picture, Artwork art) {
    canvas.drawRect(_area, Paint()..color = const Color(white));
    canvas.saveLayer(_area, Paint());
    for (final op in art.visibleOps) {
      switch (op) {
        case FillOp(:final region, :final color):
          canvas.drawPath(
            picture.visibleRegions[region],
            Paint()..color = Color(color),
          );
        case BrushStroke():
          paintStroke(canvas, op);
        case ClearOp():
          break;
      }
    }
    canvas.restore();
  }

  /// Kontur ve süs çizgileri; her zaman en üstte durur.
  static void paintOutlines(Canvas canvas, ColoringPicture picture) {
    for (var i = 0; i < picture.regions.length; i++) {
      if (!picture.outlined[i]) continue;
      final cover = picture.coverAbove[i];
      if (cover == null) {
        canvas.drawPath(picture.regions[i], _outline);
      } else {
        canvas.save();
        canvas.clipPath(_visibleArea(cover));
        canvas.drawPath(picture.regions[i], _outline);
        canvas.restore();
      }
    }
    for (final d in picture.details) {
      canvas.drawPath(d, _outline);
    }
  }

  static final _visibleCache = Expando<Path>();

  static Path _visibleArea(Path cover) => _visibleCache[cover] ??= Path.combine(
    PathOperation.difference,
    Path()..addRect(_area.inflate(outlineWidth)),
    cover,
  );

  /// Tek bir fırça çizgisi. [live] doğruysa çizgi hâlâ çiziliyordur, önbellek kullanılmaz.
  /// Silgi canlı çizilirken (katman dışında) beyaz boya gibi görünür; sonuç aynıdır.
  static void paintStroke(Canvas canvas, BrushStroke s, {bool live = false}) {
    final pts = s.points;
    if (pts.isEmpty) return;
    final color = Color(s.color);
    final path = live ? buildStrokePath(pts) : s.path;
    Paint stroke(Color c, double w) => Paint()
      ..style = PaintingStyle.stroke
      ..color = c
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    void line(Paint p) {
      if (pts.length == 1) {
        canvas.drawCircle(
          pts.first,
          p.strokeWidth / 2,
          Paint()
            ..color = p.color
            ..blendMode = p.blendMode
            ..maskFilter = p.maskFilter,
        );
      } else {
        canvas.drawPath(path, p);
      }
    }

    switch (s.kind) {
      case BrushKind.pencil:
        line(stroke(color.withValues(alpha: 0.92), s.width));
      case BrushKind.marker:
        line(stroke(color, s.width));
      case BrushKind.crayon:
        // Hafif bir zemin, üstüne tanecikler: kâğıt dokusu gibi.
        line(stroke(color.withValues(alpha: 0.35), s.width * 0.9));
        final grain = live ? buildCrayonGrain(pts, s.width) : s.crayonGrain;
        canvas.drawRawPoints(
          PointMode.points,
          grain,
          stroke(color.withValues(alpha: 0.85), math.max(3.0, s.width * 0.16)),
        );
      case BrushKind.watercolor:
        line(
          stroke(color.withValues(alpha: 0.38), s.width)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, s.width * 0.12),
        );
      case BrushKind.rainbow:
        _paintRainbow(canvas, pts, s.width);
      case BrushKind.eraser:
        line(
          live
              ? stroke(const Color(white), s.width)
              : (stroke(const Color(0xFF000000), s.width)
                  ..blendMode = BlendMode.clear),
        );
    }
  }

  static void _paintRainbow(Canvas canvas, List<Offset> pts, double width) {
    Color hue(double distance) =>
        HSVColor.fromAHSV(1, (distance / 3) % 360, 0.85, 0.95).toColor();
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    if (pts.length == 1) {
      canvas.drawCircle(pts.first, width / 2, Paint()..color = hue(0));
      return;
    }
    var travelled = 0.0;
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i - 1];
      final b = pts[i];
      paint.color = hue(travelled);
      canvas.drawLine(a, b, paint);
      travelled += (b - a).distance;
    }
  }
}
