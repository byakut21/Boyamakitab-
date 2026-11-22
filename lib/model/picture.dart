import 'dart:math' as math;
import 'dart:ui';

/// Tüm çizimler 1000x1000 birimlik bir alanda tanımlanır ve ekrana göre ölçeklenir.
const double canvasSize = 1000;
const double outlineWidth = 12;

/// Boyanabilir bir resim.
///
/// [regions] dokununca boyanan kapalı alanlardır; listede sonra gelen alan öncekilerin
/// üstünde durur. [details] sadece çizgi olarak çizilen süslerdir (bıyık, gülümseme gibi).
class ColoringPicture {
  ColoringPicture({
    required this.id,
    required this.name,
    required this.regions,
    required this.outlined,
    required this.details,
  });

  final String id;
  final String name;
  final List<Path> regions;
  final List<bool> outlined;
  final List<Path> details;

  /// Her alan için, kendisinden sonra gelen (üstünde duran) alanların birleşimi.
  /// Kontur çizilirken bu kısım kesilir; böylece arkada kalan kulak, kanat gibi
  /// parçaların çizgileri öndeki parçanın üstünden geçmez. Bir kez hesaplanır.
  late final List<Path?> coverAbove = _computeCovers();

  List<Path?> _computeCovers() {
    final covers = List<Path?>.filled(regions.length, null);
    Path? cover;
    for (var i = regions.length - 1; i >= 0; i--) {
      covers[i] = cover;
      cover = cover == null
          ? (Path()..addPath(regions[i], Offset.zero))
          : Path.combine(PathOperation.union, cover, regions[i]);
    }
    return covers;
  }

  /// Her alanın görünen kısmı: üstünde duran alanlar çıkarılmış hali. Boyama
  /// işlemleri zaman sırasıyla çizildiği için bir alanı boyamak, önündeki
  /// parçaların (göz, burun...) üstüne taşmamalıdır.
  late final List<Path> visibleRegions = [
    for (var i = 0; i < regions.length; i++)
      coverAbove[i] == null
          ? regions[i]
          : Path.combine(PathOperation.difference, regions[i], coverAbove[i]!),
  ];

  /// Verilen noktadaki en üstteki alanın sırası, yoksa -1.
  int regionAt(Offset p) {
    for (var i = regions.length - 1; i >= 0; i--) {
      if (regions[i].contains(p)) return i;
    }
    return -1;
  }
}

Path circlePath(double cx, double cy, double r) =>
    Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));

Path ovalPath(double l, double t, double r, double b) =>
    Path()..addOval(Rect.fromLTRB(l, t, r, b));

Path roundRectPath(double l, double t, double r, double b, double radius) =>
    Path()..addRRect(RRect.fromLTRBR(l, t, r, b, Radius.circular(radius)));

/// Resimleri kısa ve okunur biçimde tanımlamak için küçük bir yardımcı.
class PictureBuilder {
  PictureBuilder(this.id, this.name);

  final String id;
  final String name;
  final _regions = <Path>[];
  final _outlined = <bool>[];
  final _details = <Path>[];

  void _add(Path path, {bool outline = true}) {
    _regions.add(path);
    _outlined.add(outline);
  }

  /// Arka planın tamamı da boyanabilir bir alandır (gökyüzü, deniz...).
  void background() => _add(
    Path()..addRect(const Rect.fromLTWH(0, 0, canvasSize, canvasSize)),
    outline: false,
  );

  void circle(double cx, double cy, double r) => _add(circlePath(cx, cy, r));
  void oval(double l, double t, double r, double b) =>
      _add(ovalPath(l, t, r, b));
  void rect(double l, double t, double r, double b) =>
      _add(Path()..addRect(Rect.fromLTRB(l, t, r, b)));
  void roundRect(double l, double t, double r, double b, double radius) =>
      _add(roundRectPath(l, t, r, b, radius));

  /// Köşe noktaları [x1, y1, x2, y2, ...] olarak verilen kapalı çokgen.
  void poly(List<double> pts) => _add(_polyline(pts, close: true));

  /// İki eğriden oluşan yaprak benzeri kapalı şekil.
  void leaf(
    double x1,
    double y1,
    double c1x,
    double c1y,
    double x2,
    double y2,
    double c2x,
    double c2y,
  ) => _add(
    Path()
      ..moveTo(x1, y1)
      ..quadraticBezierTo(c1x, c1y, x2, y2)
      ..quadraticBezierTo(c2x, c2y, x1, y1)
      ..close(),
  );

  /// Birden fazla şekli tek bir boyanabilir alanda birleştirir.
  void union(List<Path> parts) =>
      _add(parts.reduce((a, b) => Path.combine(PathOperation.union, a, b)));

  /// Pamuk gibi bir bulut.
  void cloud(double cx, double cy, double w) => union([
    circlePath(cx - w * 0.28, cy, w * 0.22),
    circlePath(cx, cy - w * 0.1, w * 0.28),
    circlePath(cx + w * 0.28, cy, w * 0.22),
    roundRectPath(
      cx - w * 0.5,
      cy - w * 0.02,
      cx + w * 0.5,
      cy + w * 0.22,
      w * 0.11,
    ),
  ]);

  void line(List<double> pts) => _details.add(_polyline(pts, close: false));

  void arc(
    double l,
    double t,
    double r,
    double b,
    double startDeg,
    double sweepDeg,
  ) => _details.add(
    Path()..addArc(
      Rect.fromLTRB(l, t, r, b),
      startDeg * math.pi / 180,
      sweepDeg * math.pi / 180,
    ),
  );

  ColoringPicture build() => ColoringPicture(
    id: id,
    name: name,
    regions: List.unmodifiable(_regions),
    outlined: List.unmodifiable(_outlined),
    details: List.unmodifiable(_details),
  );

  static Path _polyline(List<double> pts, {required bool close}) {
    assert(pts.length >= 4 && pts.length.isEven);
    final path = Path()..moveTo(pts[0], pts[1]);
    for (var i = 2; i < pts.length; i += 2) {
      path.lineTo(pts[i], pts[i + 1]);
    }
    if (close) path.close();
    return path;
  }
}

ColoringPicture picture(
  String id,
  String name,
  void Function(PictureBuilder b) draw,
) {
  final builder = PictureBuilder(id, name);
  draw(builder);
  return builder.build();
}
