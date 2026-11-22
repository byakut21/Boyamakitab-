import 'package:boyama_kitabi/data/app_audio.dart';
import 'package:boyama_kitabi/data/storage.dart';
import 'package:boyama_kitabi/main.dart';
import 'package:boyama_kitabi/model/artwork.dart';
import 'package:boyama_kitabi/model/coloring_controller.dart';
import 'package:boyama_kitabi/model/picture.dart';
import 'package:boyama_kitabi/model/picture_library.dart';
import 'package:boyama_kitabi/ui/picture_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Resimler', () {
    test('her resmin benzersiz kimliği ve boyanabilir alanları var', () {
      final ids = PictureLibrary.all.map((p) => p.id).toSet();
      expect(ids.length, PictureLibrary.all.length);
      for (final p in PictureLibrary.all) {
        expect(p.regions.length, greaterThan(1), reason: p.id);
        expect(p.regions.length, p.outlined.length);
      }
    });

    test('dokunulan noktadaki en üstteki alan bulunur', () {
      final sun = PictureLibrary.byId('gunes')!;
      // Güneşin ortası: arka plan değil, güneş dairesi.
      final center = sun.regionAt(const Offset(500, 520));
      expect(center, greaterThan(0));
      // Köşe: arka plan.
      expect(sun.regionAt(const Offset(980, 20)), 0);
      // Göz, güneşin üstündedir.
      expect(sun.regionAt(const Offset(425, 455)), greaterThan(center));
    });
  });

  group('Boyama durumu', () {
    test('boya, çiz, temizle ve geri al', () {
      final cat = PictureLibrary.byId('kedi')!;
      final c = ColoringController(cat, Artwork.blank);
      expect(c.canUndo, isFalse);

      expect(c.fillAt(const Offset(500, 750), 0xFFE53935), isTrue);
      // Aynı renk hemen tekrar: değişiklik yok.
      expect(c.fillAt(const Offset(500, 750), 0xFFE53935), isFalse);

      c.startStroke(const Offset(100, 100), BrushKind.crayon, 0xFF1E88E5, 30);
      c.extendStroke(const Offset(200, 200));
      expect(c.endStroke(), isTrue);
      expect(c.ops, hasLength(2));

      expect(c.clearAll(), isTrue);
      expect(c.toArtwork().isEmpty, isTrue);
      // Boş resim tekrar temizlenmez.
      expect(c.clearAll(), isFalse);

      c.undo(); // temizlemeyi geri al
      expect(c.toArtwork().visibleOps, hasLength(2));
      c.undo(); // çizgiyi geri al
      c.undo(); // boyamayı geri al
      expect(c.canUndo, isFalse);
    });

    test('tüm fırça türleri JSON üzerinden aynen geri yüklenir', () {
      final fish = PictureLibrary.byId('balik')!;
      final c = ColoringController(fish, Artwork.blank);
      c.fillAt(const Offset(450, 500), 0xFFFB8C00);
      for (final kind in BrushKind.values) {
        c.startStroke(const Offset(10, 10), kind, 0xFF212121, kind.baseWidth);
        c.extendStroke(const Offset(60, 80));
        c.endStroke();
      }
      c.placeSticker(const Offset(300, 300), Sticker.heart, 0xFFEC407A, 170);
      c.clearAll();
      final back = Artwork.fromJson(c.toArtwork().toJson(), fish);
      final stamp = back.ops.whereType<StampOp>().single;
      expect(stamp.sticker, Sticker.heart);
      expect(stamp.center, const Offset(300, 300));
      expect(back.ops, hasLength(c.ops.length));
      final strokes = back.ops.whereType<BrushStroke>().toList();
      expect(strokes.map((s) => s.kind), BrushKind.values);
      expect(strokes.last.points, const [Offset(10, 10), Offset(60, 80)]);
      expect(back.ops.last, isA<ClearOp>());
    });
  });

  testWidgets('silgi boyayı siler, sonra yeniden boyanabilir', (tester) async {
    final apple = PictureLibrary.byId('elma')!;
    final c = ColoringController(apple, Artwork.blank);
    const red = 0xFFE53935;
    const spot = Offset(500, 650); // elmanın ortası

    Future<int> pixelAt(Offset p) async {
      final image = c.committedImage(pictureArea);
      final scale = image.width / canvasSize;
      final data = await tester.runAsync(() => image.toByteData());
      final x = (p.dx * scale).round(), y = (p.dy * scale).round();
      final i = (y * image.width + x) * 4;
      final b = data!.buffer.asUint8List();
      return 0xFF000000 | (b[i] << 16) | (b[i + 1] << 8) | b[i + 2];
    }

    c.fillAt(spot, red);
    expect(await pixelAt(spot), red);

    c.startStroke(spot - const Offset(50, 0), BrushKind.eraser, red, 56);
    c.extendStroke(spot + const Offset(50, 0));
    c.endStroke();
    expect(await pixelAt(spot), white);

    // Silinen yer, yeniden dokununca tekrar boyanır.
    expect(c.fillAt(spot, red), isTrue);
    expect(await pixelAt(spot), red);
    c.dispose();
  });

  testWidgets('ana ekrandan bir resim açılıp boyanır', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await Storage.open();
    await tester.pumpWidget(
      BoyamaApp(storage: storage, audio: AppAudio.silent()),
    );

    final cards = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is PicturePainter,
    );
    expect(cards, findsWidgets);

    await tester.tap(cards.first);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.format_color_fill_rounded), findsOneWidget);

    // Resmin ortasına dokun: güneş boyanır ve kaydedilir.
    final canvas = find.byWidgetPredicate(
      (w) =>
          w is CustomPaint &&
          w.painter is PicturePainter &&
          (w.painter! as PicturePainter).live != null,
    );
    await tester.tapAt(tester.getCenter(canvas) + const Offset(0, 10));
    await tester.pump();
    expect(storage.loadAll(PictureLibrary.all), contains('gunes'));
  });
}
