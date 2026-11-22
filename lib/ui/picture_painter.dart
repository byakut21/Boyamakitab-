import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../model/artwork.dart';
import '../model/coloring_controller.dart';
import '../model/picture.dart';

const double brushWidth = 36;
const Color outlineColor = Color(0xFF2B2B2B);

/// Resmi; önce dolgular, sonra fırça çizgileri, en üstte de kontur çizgileri olacak
/// şekilde çizer. Resim, alana sığan en büyük kare olarak ortalanır.
class PicturePainter extends CustomPainter {
  PicturePainter({
    required this.picture,
    required this.fills,
    required this.strokes,
    this.live,
  }) : super(repaint: live);

  final ColoringPicture picture;
  final List<int> fills;
  final List<BrushStroke> strokes;

  /// Boyama ekranında verilir: çizilmekte olan çizgi buradan okunur ve her
  /// değişiklikte yeniden çizilir.
  final ColoringController? live;

  static final _fill = Paint()..style = PaintingStyle.fill;
  static final _brush = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = brushWidth
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  static final _outline = Paint()
    ..style = PaintingStyle.stroke
    ..color = outlineColor
    ..strokeWidth = outlineWidth
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static const _area = Rect.fromLTWH(0, 0, canvasSize, canvasSize);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width, size.height) / canvasSize;
    canvas.save();
    canvas.translate(
      (size.width - canvasSize * scale) / 2,
      (size.height - canvasSize * scale) / 2,
    );
    canvas.scale(scale);
    canvas.clipRect(_area);

    for (var i = 0; i < picture.regions.length; i++) {
      _fill.color = Color(i < fills.length ? fills[i] : white);
      canvas.drawPath(picture.regions[i], _fill);
    }
    for (final s in strokes) {
      _drawStroke(canvas, s.color, s.points, () => s.path);
    }
    final current = live?.currentPoints;
    if (current != null && current.isNotEmpty) {
      _drawStroke(
        canvas,
        live!.currentColor,
        current,
        () => buildStrokePath(current),
      );
    }
    // Konturlar: üstte duran alanların altında kalan kısımlar kesilir.
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
    canvas.restore();
  }

  static final _visibleCache = Expando<Path>();

  static Path _visibleArea(Path cover) => _visibleCache[cover] ??= Path.combine(
    PathOperation.difference,
    Path()..addRect(_area.inflate(outlineWidth)),
    cover,
  );

  void _drawStroke(
    Canvas canvas,
    int color,
    List<Offset> points,
    Path Function() path,
  ) {
    if (points.length == 1) {
      // Tek dokunuş: yuvarlak bir nokta bırak.
      _fill.color = Color(color);
      canvas.drawCircle(points.first, brushWidth / 2, _fill);
    } else {
      _brush.color = Color(color);
      canvas.drawPath(path(), _brush);
    }
  }

  @override
  bool shouldRepaint(PicturePainter old) =>
      old.picture != picture ||
      old.fills != fills ||
      old.strokes != strokes ||
      old.live != live;
}
