import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../model/artwork.dart';
import '../model/coloring_controller.dart';
import '../model/picture.dart';
import 'art_renderer.dart';

/// Resmi, alana sığan en büyük kare olarak ortalayıp çizer.
///
/// [live] verilirse (boyama ekranı) biten işlemler önbellekteki görüntüden, o an
/// çizilen çizgi ise canlı çizilir. Verilmezse (ana ekran) [artwork] doğrudan çizilir.
class PicturePainter extends CustomPainter {
  PicturePainter({
    required this.picture,
    this.artwork = Artwork.blank,
    this.live,
  }) : super(repaint: live);

  final ColoringPicture picture;
  final Artwork artwork;
  final ColoringController? live;

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

    final c = live;
    if (c == null) {
      ArtRenderer.paintArt(canvas, picture, artwork);
    } else {
      final image = c.committedImage();
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        _area,
        Paint()..filterQuality = FilterQuality.medium,
      );
      final current = c.current;
      if (current != null) ArtRenderer.paintStroke(canvas, current, live: true);
    }
    ArtRenderer.paintOutlines(canvas, picture);
    canvas.restore();
  }

  @override
  bool shouldRepaint(PicturePainter old) =>
      old.picture != picture || old.artwork != artwork || old.live != live;
}
