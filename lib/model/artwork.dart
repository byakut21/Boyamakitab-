import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'picture.dart';

const int white = 0xFFFFFFFF;

/// Çizim araçları. Her birinin kendine özgü bir görünümü var.
enum BrushKind {
  /// İnce, net kurşun kalem çizgisi.
  pencil(10),

  /// Yumuşak uçlu, dolgun fırça.
  marker(36),

  /// Pürüzlü, tanecikli pastel boya.
  crayon(32),

  /// Yarı saydam, kenarları dağılan sulu boya; üst üste geldikçe koyulaşır.
  watercolor(52),

  /// Çizdikçe renk değiştiren gökkuşağı fırçası.
  rainbow(36),

  /// Işıl ışıl parlayan simli fırça.
  glitter(40),

  /// Çizgi boyunca minik yıldızlar bırakan desenli fırça.
  stars(34),

  /// Silgi: boyayı da çizgiyi de siler, çizgiler (konturlar) kalır.
  eraser(56);

  const BrushKind(this.baseWidth);
  final double baseWidth;
}

/// Fırça kalınlıkları: ince, orta, kalın.
const List<double> brushSizes = [0.55, 1.0, 1.7];

/// Bir boyama işlemi. Resim, işlemler sırayla uygulanarak çizilir.
sealed class DrawOp {
  const DrawOp();

  Map<String, Object> toJson();

  static DrawOp fromJson(Map<String, dynamic> json) => switch (json['t']) {
    'f' => FillOp(json['r'] as int, json['c'] as int),
    's' => BrushStroke.fromJson(json),
    'x' => const ClearOp(),
    _ => throw FormatException('Bilinmeyen işlem: ${json['t']}'),
  };
}

/// Bir alanı tek renkle boyar.
class FillOp extends DrawOp {
  const FillOp(this.region, this.color);
  final int region;
  final int color;

  @override
  Map<String, Object> toJson() => {'t': 'f', 'r': region, 'c': color};
}

/// Çıkartmalar: dokununca seçili renkte yapıştırılır.
enum Sticker { star, heart, smiley, flower, moon }

/// Bir çıkartma yapıştırır.
class StampOp extends DrawOp {
  const StampOp(this.sticker, this.color, this.center, this.size);
  final Sticker sticker;
  final int color;
  final Offset center;
  final double size;

  @override
  Map<String, Object> toJson() => {
    't': 'k',
    's': sticker.name,
    'c': color,
    'x': center.dx.roundToDouble(),
    'y': center.dy.roundToDouble(),
    'z': size,
  };
}

/// Resmi tamamen temizler; önceki işlemler geri alma için listede kalır.
class ClearOp extends DrawOp {
  const ClearOp();

  @override
  Map<String, Object> toJson() => {'t': 'x'};
}

/// Parmakla çizilmiş tek bir çizgi; noktalar resim koordinatlarındadır.
class BrushStroke extends DrawOp {
  BrushStroke(this.kind, this.color, this.width, this.points);

  final BrushKind kind;
  final int color;
  final double width;
  final List<Offset> points;

  late final Path path = buildStrokePath(points);

  /// Pastel boya taneleri: [x, y, x, y, ...]. Aynı çizgi her seferinde aynı görünsün
  /// diye sabit tohumlu rastgele sayılarla bir kez üretilir.
  late final Float32List crayonGrain = buildCrayonGrain(points, width);

  /// Simli fırçanın parıltıları; renk tonlarına göre üç grup.
  late final List<Float32List> glitterGrain = buildGlitter(points, width);

  /// Yıldız fırçasının yıldızlarının yerleri ve açıları: [x, y, açı, ...].
  late final Float32List starStamps = buildStarStamps(points, width);

  @override
  Map<String, Object> toJson() => {
    't': 's',
    'k': kind.name,
    'c': color,
    'w': width,
    'p': [
      for (final p in points) ...[p.dx.roundToDouble(), p.dy.roundToDouble()],
    ],
  };

  static BrushStroke fromJson(Map<String, dynamic> json) {
    final raw = (json['p'] as List).cast<num>();
    return BrushStroke(
      BrushKind.values.byName(json['k'] as String),
      json['c'] as int,
      (json['w'] as num).toDouble(),
      [
        for (var i = 0; i + 1 < raw.length; i += 2)
          Offset(raw[i].toDouble(), raw[i + 1].toDouble()),
      ],
    );
  }
}

/// Bir resmin o anki boyanmış hali: sırayla uygulanan işlemler.
class Artwork {
  const Artwork(this.ops);

  static const blank = Artwork([]);

  final List<DrawOp> ops;

  /// Son temizlemeden sonraki, ekranda görünen işlemler.
  Iterable<DrawOp> get visibleOps {
    final start = ops.lastIndexWhere((op) => op is ClearOp) + 1;
    return ops.skip(start);
  }

  bool get isEmpty => visibleOps.isEmpty;

  Map<String, Object> toJson() => {
    'v': 2,
    'ops': [for (final op in ops) op.toJson()],
  };

  static Artwork fromJson(Map<String, dynamic> json, ColoringPicture picture) {
    if (json['v'] != 2) throw const FormatException('Eski kayıt biçimi');
    final ops = [
      for (final o in json['ops'] as List)
        DrawOp.fromJson(o as Map<String, dynamic>),
    ];
    for (final op in ops) {
      if (op is FillOp &&
          (op.region < 0 || op.region >= picture.regions.length)) {
        throw const FormatException('Resimle uyuşmayan kayıt');
      }
    }
    return Artwork(ops);
  }
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

/// Çizgi boyunca, kalınlığın içine rastgele serpiştirilmiş taneler.
Float32List buildCrayonGrain(
  List<Offset> pts,
  double width, {
  int density = 3,
}) {
  if (pts.isEmpty) return Float32List(0);
  final seed =
      pts.first.dx.round() * 7919 + pts.first.dy.round() * 104729 + pts.length;
  final rnd = math.Random(seed);
  final out = <double>[];
  final radius = width / 2;
  void sprinkle(Offset c, int n) {
    for (var k = 0; k < n; k++) {
      final a = rnd.nextDouble() * 2 * math.pi;
      final r = radius * math.sqrt(rnd.nextDouble());
      out
        ..add(c.dx + r * math.cos(a))
        ..add(c.dy + r * math.sin(a));
    }
  }

  if (pts.length == 1) {
    sprinkle(pts.first, 40);
  } else {
    final step = math.max(2.0, width / 10);
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i - 1];
      final b = pts[i];
      final len = (b - a).distance;
      final n = math.max(1, (len / step).ceil());
      for (var j = 0; j < n; j++) {
        sprinkle(Offset.lerp(a, b, j / n)!, density);
      }
    }
  }
  return Float32List.fromList(out);
}

/// Simli fırça: çizginin biraz dışına da taşan, üç ayrı tonda parıltılar.
List<Float32List> buildGlitter(List<Offset> pts, double width) {
  final grain = buildCrayonGrain(pts, width * 1.15, density: 2);
  final groups = [<double>[], <double>[], <double>[]];
  for (var i = 0; i + 1 < grain.length; i += 2) {
    groups[(i ~/ 2) % 3]
      ..add(grain[i])
      ..add(grain[i + 1]);
  }
  return [for (final g in groups) Float32List.fromList(g)];
}

/// Çizgi boyunca eşit aralıklarla yıldız yerleri.
Float32List buildStarStamps(List<Offset> pts, double width) {
  if (pts.isEmpty) return Float32List(0);
  final out = <double>[pts.first.dx, pts.first.dy, 0];
  final spacing = width * 1.5;
  var carried = 0.0;
  var n = 1;
  for (var i = 1; i < pts.length; i++) {
    final a = pts[i - 1];
    final b = pts[i];
    final len = (b - a).distance;
    var t = spacing - carried;
    while (t <= len) {
      final p = Offset.lerp(a, b, t / len)!;
      out
        ..add(p.dx)
        ..add(p.dy)
        ..add((n++ * 0.7) % (2 * math.pi / 5));
      t += spacing;
    }
    carried = len - (t - spacing);
  }
  return Float32List.fromList(out);
}
