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
- **Ebeveyn şifresi:** ana ekranın sağ üstündeki soluk kilidi 3 saniye basılı tutup 4 haneli şifreyi girince
  panel açılır (şifre ilk seferde belirlenir). Panelde: çocuk kilidi, şifre değiştirme, müzik/ses/titreşim,
  tüm boyamaları silme ve çıkış.
- **Çocuk kilidi:** açılınca uygulama Android'in ekran sabitleme özelliğiyle ekrana kilitlenir; ana ekran,
  son uygulamalar, bildirim çubuğu ve bölünmüş ekran çalışmaz. Çıkış sadece ebeveyn panelinden, şifreyle.
  Android'in kendi kilit açma hareketini (Geri + Son uygulamalar) de şifreye bağlamak için telefonda
  Ayarlar > Güvenlik > Uygulama sabitleme > "Sabitlemeyi kaldırmadan önce PIN iste" açılmalıdır.
- **Güvenli:** internet izni yok, reklam yok, veri toplama yok. Tam ekran çalışır, ekran kararmaz.

## APK'yı indirmek
Her gönderimde GitHub Actions uygulamayı test eder ve APK'yı derler. Repo sayfasında
**Actions → son "APK derle" çalışması → Artifacts → boyama-kitabi-apk** yolundan indirip telefona kurabilirsiniz
(telefonda "bilinmeyen kaynaklardan yükleme" izni gerekir).

## Güncelleme

Depoda `KEYSTORE_BASE64` ve `KEYSTORE_PASSWORD` adlı iki GitHub secret'ı varsa her APK aynı
anahtarla imzalanır; sürüm numarası da her derlemede artar. Böylece yeni APK eskisinin
üstüne kurulur, boyamalar ve ayarlar kalır. Secret yoksa APK geçici bir anahtarla imzalanır
ve güncellemek için eskisini silmek gerekir.

## Çocuk kilidi

Ebeveyn panelinden "Çocuk kilidi" açılınca uygulama ekrana sabitlenir. Çocuk "Geri" ve
"Son uygulamalar" tuşlarına basılı tutup sabitlemeyi kaldırırsa uygulama hemen yeniden
sabitlenir ve kilidi açmak için ebeveyn şifresini sorar.

Android normal sabitlemede "Uygulama sabitlensin mi?" sorusunu ve "Uygulama sabitlendi"
uyarısını kendisi gösterir; bunu uygulamalar kapatamaz.

### Tam kilit (uyarısız, isteğe bağlı)

Telefonda hiç hesap (Google hesabı dahil) yokken, bilgisayardan bir kez:

```
adb shell dpm set-device-owner com.boyama.boyama_kitabi/.AdminReceiver
```

Bundan sonra sabitleme sorusuz ve uyarısız olur, Geri+Son uygulamalar kısayolu da çalışmaz;
çıkış sadece ebeveyn panelinden şifreyle yapılır. Panelde "Tam kilit açık" düğmesiyle
geri alınabilir.

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
