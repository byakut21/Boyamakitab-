import 'package:flutter/widgets.dart';

import '../model/artwork.dart';
import '../model/coloring_controller.dart';
import '../model/picture.dart';
import 'art_renderer.dart';

/// Resmi, alana sığan en büyük kare olarak ortalayıp çizer.
///
/// [live] verilirse (boyama ekranı) tüm alan çizim alanıdır: biten işlemler önbellekteki
/// görüntüden, o an çizilen çizgi canlı çizilir. Verilmezse (ana ekran) sadece resim
/// karesi ve [artwork] doğrudan çizilir.
class PicturePainter extends CustomPainter {
  PicturePainter({
    required this.picture,
    this.artwork = Artwork.blank,
    this.live,
  }) : super(repaint: live);

  final ColoringPicture picture;
  final Artwork artwork;
  final ColoringController? live;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = PictureLayout(size);
    canvas.save();
    canvas.translate(layout.offset.dx, layout.offset.dy);
    canvas.scale(layout.scale);

    final c = live;
    if (c == null) {
      canvas.clipRect(pictureArea);
      ArtRenderer.paintArt(canvas, picture, artwork);
    } else {
      final area = layout.area;
      canvas.clipRect(area);
      final image = c.committedImage(area);
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        area,
        Paint()..filterQuality = FilterQuality.medium,
      );
      final current = c.current;
      if (current != null) ArtRenderer.paintOp(canvas, current, live: true);
    }
    ArtRenderer.paintOutlines(canvas, picture);
    canvas.restore();
  }

  @override
  bool shouldRepaint(PicturePainter old) =>
      old.picture != picture || old.artwork != artwork || old.live != live;
}
