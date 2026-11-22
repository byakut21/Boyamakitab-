# Boyama Kitabı (0-4 yaş)

Küçük çocuklar için Android boyama uygulaması. Flutter ile yazıldı.

## Özellikler
- **Okuma gerektirmeyen arayüz:** sadece büyük resimler, büyük renkli düğmeler ve simgeler.
- **Dokun ve boya:** bir alana dokununca seçili renkle dolar.
- **Çizim araçları:** kalem, fırça, pastel boya (tanecikli), sulu boya (yarı saydam, üst üste koyulaşır),
  gökkuşağı fırçası, simli fırça, yıldız fırçası, çıkartmalar (yıldız, kalp, gülen yüz, çiçek, ay) ve silgi.
  Araç simgeleri seçili renkte görünür. Üç fırça kalınlığı, 16 renk.
  Sadece ilk parmak sayılır, avuç içi çizimi bozmaz.
- **Geniş çizim alanı:** ekranda kalan tüm alan çizim alanıdır; resmin çevresi de boyanabilir.
- **Müzik ve sesler:** bu proje için üretilmiş özgün, neşeli bir müzik döngüsü ile boyama/çıkartma sesleri
  (`tool/make_audio.py`). Ebeveyn panelinden ayrı ayrı kapatılabilir.
- **Geri al ve temizle:** temizleme de geri alınabilir, yanlışlıkla basılırsa sorun olmaz.
- **18 özgün resim:** güneş, kedi, balık, elma, balonlar, çiçek, kelebek, araba, ev, tavşan, kuş,
  kaplumbağa, tekne, uçak, ağaç, dondurma, pasta, roket. Hepsi bu proje için basit şekillerle çizildi, bilinen bir karakter yok.
- **Otomatik kayıt:** boyamalar cihazda saklanır, ana ekranda boyanmış halleri görünür.
- **Ebeveyn kilidi:** ana ekranın sağ üstündeki soluk kilidi 3 saniye basılı tutunca panel açılır (müzik, ses efektleri ve titreşim ayarları, tüm boyamaları silme, uygulamadan çıkış). Ana ekranda geri tuşu uygulamadan çıkarmaz.
- **Güvenli:** internet izni yok, reklam yok, veri toplama yok. Tam ekran çalışır, ekran kararmaz.

## APK'yı indirmek
Her gönderimde GitHub Actions uygulamayı test eder ve APK'yı derler. Repo sayfasında
**Actions → son "APK derle" çalışması → Artifacts → boyama-kitabi-apk** yolundan indirip telefona kurabilirsiniz
(telefonda "bilinmeyen kaynaklardan yükleme" izni gerekir).

## Geliştirme
```bash
flutter pub get
flutter test
flutter run            # bağlı telefonda çalıştırır
flutter build apk      # build/app/outputs/flutter-apk/app-release.apk
```

## Yeni resim eklemek
`lib/model/picture_library.dart` içinde `picture('id', 'Ad', (b) { ... })` bloğu ekleyip `all` listesine koyun.
Resimler 1000x1000'lik bir alanda `circle`, `oval`, `rect`, `roundRect`, `poly`, `leaf`, `cloud` gibi şekillerle
tanımlanır. Sonra eklenen şekil öncekilerin üstünde durur; `line` ve `arc` sadece boyanmayan süs çizgileridir.
