import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'artwork.dart';
import 'picture.dart';

sealed class _Action {}

class _Fill extends _Action {
  _Fill(this.index, this.previous);
  final int index;
  final int previous;
}

class _Stroke extends _Action {}

class _Clear extends _Action {
  _Clear(this.fills, this.strokes);
  final List<int> fills;
  final List<BrushStroke> strokes;
}

/// Boyama ekranının durumu: alan renkleri, çizgiler ve geri alma geçmişi.
class ColoringController extends ChangeNotifier {
  ColoringController(this.picture, Artwork initial)
    : fills = List.of(
        initial.fills.length == picture.regions.length
            ? initial.fills
            : Artwork.blank(picture).fills,
      ),
      strokes = List.of(initial.strokes);

  static const _maxHistory = 100;
  static const _minStep = 4.0;

  final ColoringPicture picture;
  final List<int> fills;
  final List<BrushStroke> strokes;
  final _history = <_Action>[];

  /// Şu anda çizilmekte olan çizgi.
  List<Offset>? currentPoints;
  int currentColor = white;

  bool get canUndo => _history.isNotEmpty;

  void _push(_Action action) {
    _history.add(action);
    if (_history.length > _maxHistory) _history.removeAt(0);
  }

  /// Dokunulan alanı boyar. Bir şey değiştiyse true döner.
  bool fillAt(Offset p, int color) {
    final index = picture.regionAt(p);
    if (index < 0 || fills[index] == color) return false;
    _push(_Fill(index, fills[index]));
    fills[index] = color;
    notifyListeners();
    return true;
  }

  void startStroke(Offset p, int color) {
    currentColor = color;
    currentPoints = [p];
    notifyListeners();
  }

  void extendStroke(Offset p) {
    final pts = currentPoints;
    if (pts == null) return;
    if ((pts.last - p).distance < _minStep) return;
    pts.add(p);
    notifyListeners();
  }

  bool endStroke() {
    final pts = currentPoints;
    if (pts == null) return false;
    strokes.add(BrushStroke(currentColor, List.unmodifiable(pts)));
    currentPoints = null;
    _push(_Stroke());
    notifyListeners();
    return true;
  }

  /// Resmi temizler. Bu da geri alınabilir; yanlışlıkla basılırsa sorun olmaz.
  bool clearAll() {
    if (strokes.isEmpty && fills.every((c) => c == white)) return false;
    _push(_Clear(List.of(fills), List.of(strokes)));
    fills.fillRange(0, fills.length, white);
    strokes.clear();
    notifyListeners();
    return true;
  }

  bool undo() {
    if (_history.isEmpty) return false;
    switch (_history.removeLast()) {
      case _Fill(:final index, :final previous):
        fills[index] = previous;
      case _Stroke():
        if (strokes.isNotEmpty) strokes.removeLast();
      case _Clear(fills: final oldFills, strokes: final oldStrokes):
        fills.setAll(0, oldFills);
        strokes
          ..clear()
          ..addAll(oldStrokes);
    }
    notifyListeners();
    return true;
  }

  Artwork toArtwork() =>
      Artwork(List.unmodifiable(fills), List.unmodifiable(strokes));
}
