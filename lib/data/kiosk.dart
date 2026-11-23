import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Çocuk kilidi: uygulamayı ekrana sabitler (Android "lock task" / ekran sabitleme).
///
/// Sabitliyken ana ekran ve son uygulamalar tuşları çalışmaz, bildirim çubuğu
/// açılmaz. Çıkış uygulama içinden, ebeveyn şifresiyle yapılır.
class Kiosk {
  const Kiosk();

  static const _channel = MethodChannel('boyama/kiosk');

  Future<bool> _call(String method) async {
    try {
      return await _channel.invokeMethod<bool>(method) ?? false;
    } on MissingPluginException {
      return false; // Testler ve Android dışı platformlar.
    } on PlatformException catch (e) {
      debugPrint('Çocuk kilidi hatası: ${e.message}');
      return false;
    }
  }

  Future<void> start() => _call('start');
  Future<void> stop() => _call('stop');
  Future<bool> isLocked() => _call('isLocked');

  /// Kilidi kaldırıp uygulamayı kapatır.
  Future<void> exit() async {
    if (!await _call('exit')) await SystemNavigator.pop();
  }
}
