import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart' show HSVColor;

import '../model/artwork.dart';
import '../model/picture.dart';

const Color outlineColor = Color(0xFF2B2B2B);

/// Boyamaları çizen ortak kod: hem ana ekrandaki küçük resimler hem boyama ekranı kullanır.
class ArtRenderer {
  ArtRenderer._();

  static final _outline = Paint()
    ..style = PaintingStyle.stroke
    ..color = outlineColor
    ..strokeWidth = outlineWidth
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  /// Beyaz zemin + sırayla tüm işlemler. Silgi, zemine kadar siler.
  static void paintArt(
    Canvas canvas,
    ColoringPicture picture,
    Artwork art, {
    Rect area = pictureArea,
  }) {
    canvas.drawRect(area, Paint()..color = const Color(white));
    canvas.saveLayer(area, Paint());
    for (final op in art.visibleOps) {
      switch (op) {
        case FillOp(:final region, :final color):
          canvas.drawPath(
            picture.visibleRegions[region],
            Paint()..color = Color(color),
          );
        case BrushStroke():
        case StampOp():
          paintOp(canvas, op);
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
    Path()..addRect(worldRect),
    cover,
  );

  /// Bir fırça çizgisi ya da çıkartma.
  static void paintOp(Canvas canvas, DrawOp op, {bool live = false}) {
    switch (op) {
      case BrushStroke():
        _paintStroke(canvas, op, live: live);
      case StampOp(:final sticker, :final color, :final center, :final size):
        paintSticker(canvas, sticker, Color(color), center, size);
      default:
        break;
    }
  }

  /// Tek bir fırça çizgisi. [live] doğruysa çizgi hâlâ çiziliyordur, önbellek kullanılmaz.
  /// Silgi canlı çizilirken (katman dışında) beyaz boya gibi görünür; sonuç aynıdır.
  static void _paintStroke(Canvas canvas, BrushStroke s, {bool live = false}) {
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
      case BrushKind.glitter:
        line(stroke(color.withValues(alpha: 0.3), s.width * 0.8));
        final groups = live ? buildGlitter(pts, s.width) : s.glitterGrain;
        final tones = [
          color,
          Color.lerp(color, const Color(white), 0.55)!,
          const Color(white),
        ];
        final dot = math.max(3.0, s.width * 0.13);
        for (var g = 0; g < groups.length; g++) {
          canvas.drawRawPoints(
            PointMode.points,
            groups[g],
            stroke(tones[g], dot),
          );
        }
      case BrushKind.stars:
        final stamps = live ? buildStarStamps(pts, s.width) : s.starStamps;
        for (var i = 0; i + 2 < stamps.length; i += 3) {
          _star(
            canvas,
            Offset(stamps[i], stamps[i + 1]),
            s.width * 0.62,
            stamps[i + 2],
            color,
          );
        }
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

void _star(Canvas canvas, Offset c, double r, double angle, Color color) {
  final path = starPath(c, r, angle);
  canvas.drawPath(path, Paint()..color = color);
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.0, r * 0.14)
      ..strokeJoin = StrokeJoin.round
      ..color = outlineColor,
  );
}

/// Beş köşeli yıldız.
Path starPath(Offset c, double r, [double angle = 0]) {
  final path = Path();
  for (var i = 0; i < 10; i++) {
    final rr = i.isEven ? r : r * 0.45;
    final a = -math.pi / 2 + angle + i * math.pi / 5;
    final p = c + Offset(math.cos(a), math.sin(a)) * rr;
    if (i == 0) {
      path.moveTo(p.dx, p.dy);
    } else {
      path.lineTo(p.dx, p.dy);
    }
  }
  return path..close();
}

/// Çıkartmayı [c] merkezli, [size] çaplı çizer.
void paintSticker(
  Canvas canvas,
  Sticker sticker,
  Color color,
  Offset c,
  double size,
) {
  final r = size / 2;
  final line = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(2.0, size * 0.05)
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round
    ..color = outlineColor;
  final fill = Paint()..color = color;
  void shape(Path p) {
    canvas.drawPath(p, fill);
    canvas.drawPath(p, line);
  }

  switch (sticker) {
    case Sticker.star:
      shape(starPath(c, r));
    case Sticker.heart:
      shape(
        Path()
          ..moveTo(c.dx, c.dy + r * 0.9)
          ..cubicTo(
            c.dx - r * 1.3,
            c.dy + r * 0.05,
            c.dx - r * 0.75,
            c.dy - r * 1.0,
            c.dx,
            c.dy - r * 0.4,
          )
          ..cubicTo(
            c.dx + r * 0.75,
            c.dy - r * 1.0,
            c.dx + r * 1.3,
            c.dy + r * 0.05,
            c.dx,
            c.dy + r * 0.9,
          )
          ..close(),
      );
    case Sticker.smiley:
      shape(Path()..addOval(Rect.fromCircle(center: c, radius: r * 0.9)));
      final eye = Paint()..color = outlineColor;
      canvas.drawCircle(c + Offset(-r * 0.32, -r * 0.2), r * 0.11, eye);
      canvas.drawCircle(c + Offset(r * 0.32, -r * 0.2), r * 0.11, eye);
      canvas.drawArc(
        Rect.fromCircle(center: c + Offset(0, r * 0.05), radius: r * 0.5),
        0.35,
        math.pi - 0.7,
        false,
        line,
      );
    case Sticker.flower:
      for (var i = 0; i < 5; i++) {
        final a = -math.pi / 2 + i * 2 * math.pi / 5;
        shape(
          Path()..addOval(
            Rect.fromCircle(
              center: c + Offset(math.cos(a), math.sin(a)) * r * 0.55,
              radius: r * 0.38,
            ),
          ),
        );
      }
      final middle = Path()
        ..addOval(Rect.fromCircle(center: c, radius: r * 0.3));
      canvas.drawPath(middle, Paint()..color = const Color(0xFFFDD835));
      canvas.drawPath(middle, line);
    case Sticker.moon:
      shape(
        Path.combine(
          PathOperation.difference,
          Path()..addOval(Rect.fromCircle(center: c, radius: r * 0.9)),
          Path()..addOval(
            Rect.fromCircle(
              center: c + Offset(r * 0.45, -r * 0.25),
              radius: r * 0.75,
            ),
          ),
        ),
      );
  }
}
