import 'package:boyama_kitabi/data/storage.dart';
import 'package:boyama_kitabi/main.dart';
import 'package:boyama_kitabi/model/artwork.dart';
import 'package:boyama_kitabi/model/coloring_controller.dart';
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
      final c = ColoringController(cat, Artwork.blank(cat));
      expect(c.canUndo, isFalse);

      expect(c.fillAt(const Offset(500, 750), 0xFFE53935), isTrue);
      // Aynı renk tekrar: değişiklik yok.
      expect(c.fillAt(const Offset(500, 750), 0xFFE53935), isFalse);

      c.startStroke(const Offset(100, 100), 0xFF1E88E5);
      c.extendStroke(const Offset(200, 200));
      expect(c.endStroke(), isTrue);
      expect(c.strokes, hasLength(1));

      expect(c.clearAll(), isTrue);
      expect(c.fills.every((f) => f == white), isTrue);
      expect(c.strokes, isEmpty);

      c.undo(); // temizlemeyi geri al
      expect(c.strokes, hasLength(1));
      expect(c.fills.contains(0xFFE53935), isTrue);
      c.undo(); // çizgiyi geri al
      expect(c.strokes, isEmpty);
      c.undo(); // boyamayı geri al
      expect(c.fills.every((f) => f == white), isTrue);
      expect(c.canUndo, isFalse);
    });

    test('kayıt JSON üzerinden aynen geri yüklenir', () {
      final fish = PictureLibrary.byId('balik')!;
      final c = ColoringController(fish, Artwork.blank(fish));
      c.fillAt(const Offset(450, 500), 0xFFFB8C00);
      c.startStroke(const Offset(10, 10), 0xFF212121);
      c.endStroke();
      final back = Artwork.fromJson(c.toArtwork().toJson());
      expect(back.fills, c.fills);
      expect(back.strokes.single.points, c.strokes.single.points);
    });
  });

  testWidgets('ana ekrandan bir resim açılıp boyanır', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await Storage.open();
    await tester.pumpWidget(BoyamaApp(storage: storage));

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
