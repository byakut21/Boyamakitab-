import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../ui/art_renderer.dart';
import 'artwork.dart';
import 'picture.dart';

/// Boyama ekranının durumu: işlemler, çizilmekte olan çizgi ve geri alma.
class ColoringController extends ChangeNotifier {
  ColoringController(this.picture, Artwork initial)
    : ops = List.of(initial.ops);

  /// Önbellek görüntüsünde resim biriminin piksel karşılığı (en fazla).
  static const cachePixelsPerUnit = 1.4;
  static const _maxCachePixels = 3000000;
  static const _minStep = 3.0;

  final ColoringPicture picture;
  final List<DrawOp> ops;

  /// Şu anda çizilmekte olan çizgi.
  BrushStroke? current;

  ui.Image? _cache;
  Rect? _cacheArea;

  bool get canUndo => ops.isNotEmpty;

  /// Biten işlemlerin görüntüsü. Her çizimde baştan çizmek yerine bir kez
  /// resim olarak hazırlanır; böylece yüzlerce çizgide bile akıcı kalır.
  ///
  /// [area], resim koordinatlarında ekranın tamamıdır.
  ui.Image committedImage(Rect area) {
    final cached = _cache;
    if (cached != null && _cacheArea == area) return cached;
    _dropCache();
    final k = math.min(
      cachePixelsPerUnit,
      math.sqrt(_maxCachePixels / (area.width * area.height)),
    );
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(k);
    canvas.translate(-area.left, -area.top);
    ArtRenderer.paintArt(canvas, picture, Artwork(ops), area: area);
    final pic = recorder.endRecording();
    final image = pic.toImageSync(
      math.max(1, (area.width * k).round()),
      math.max(1, (area.height * k).round()),
    );
    pic.dispose();
    _cacheArea = area;
    return _cache = image;
  }

  void _dropCache() {
    _cache?.dispose();
    _cache = null;
    _cacheArea = null;
  }

  void _changed() {
    _dropCache();
    notifyListeners();
  }

  /// Dokunulan yere çıkartma yapıştırır.
  void placeSticker(Offset p, Sticker sticker, int color, double size) {
    ops.add(StampOp(sticker, color, p, size));
    _changed();
  }

  /// Dokunulan alanı boyar. Bir şey değiştiyse true döner.
  bool fillAt(Offset p, int color) {
    final index = picture.regionAt(p);
    if (index < 0) return false;
    final last = ops.isEmpty ? null : ops.last;
    if (last is FillOp && last.region == index && last.color == color) {
      return false;
    }
    ops.add(FillOp(index, color));
    _changed();
    return true;
  }

  void startStroke(Offset p, BrushKind kind, int color, double width) {
    current = BrushStroke(kind, color, width, [p]);
    notifyListeners();
  }

  void extendStroke(Offset p) {
    final stroke = current;
    if (stroke == null) return;
    if ((stroke.points.last - p).distance < _minStep) return;
    stroke.points.add(p);
    notifyListeners();
  }

  bool endStroke() {
    final stroke = current;
    if (stroke == null) return false;
    current = null;
    ops.add(
      BrushStroke(
        stroke.kind,
        stroke.color,
        stroke.width,
        List.unmodifiable(stroke.points),
      ),
    );
    _changed();
    return true;
  }

  /// Resmi temizler. Bu da geri alınabilir; yanlışlıkla basılırsa sorun olmaz.
  bool clearAll() {
    if (Artwork(ops).isEmpty) return false;
    ops.add(const ClearOp());
    _changed();
    return true;
  }

  bool undo() {
    if (ops.isEmpty) return false;
    ops.removeLast();
    _changed();
    return true;
  }

  Artwork toArtwork() => Artwork(List.unmodifiable(ops));

  @override
  void dispose() {
    _dropCache();
    super.dispose();
  }
}
