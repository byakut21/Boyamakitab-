import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Müzik ve ses efektleri. Testlerde ses çalınmasın diye [AppAudio.silent] kullanılır.
abstract class AppAudio {
  /// Gerçek ses: arka planda döngüde çalan müzik ve kısa efektler.
  factory AppAudio() = _PlayerAudio;

  /// Hiç ses çıkarmayan sürüm.
  factory AppAudio.silent() = _SilentAudio;

  /// Müzik açık mı (ebeveyn ayarı).
  set musicEnabled(bool value);

  /// Efektler açık mı (ebeveyn ayarı).
  bool soundsEnabled = true;

  /// Uygulama arka plana gidince/döndüğünde.
  void pauseMusic();
  void resumeMusic();

  /// Boyama sesi.
  void plop();

  /// Çıkartma sesi.
  void sparkle();
}

class _SilentAudio implements AppAudio {
  @override
  bool soundsEnabled = true;
  @override
  set musicEnabled(bool value) {}
  @override
  void pauseMusic() {}
  @override
  void resumeMusic() {}
  @override
  void plop() {}
  @override
  void sparkle() {}
}

class _PlayerAudio implements AppAudio {
  _PlayerAudio() {
    _music.setReleaseMode(ReleaseMode.loop).catchError(_log);
    _music.setVolume(0.45).catchError(_log);
    // Efektler müziği durdurmasın: ses odağı istemezler.
    final effects = AudioContext(
      android: AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
    );
    _plopPool = AudioPool.create(
      source: AssetSource('audio/plop.ogg'),
      maxPlayers: 3,
      audioContext: effects,
      playerMode: PlayerMode.lowLatency,
    );
    _sparklePool = AudioPool.create(
      source: AssetSource('audio/cikartma.ogg'),
      maxPlayers: 2,
      audioContext: effects,
      playerMode: PlayerMode.lowLatency,
    );
  }

  final _music = AudioPlayer();
  late final Future<AudioPool> _plopPool;
  late final Future<AudioPool> _sparklePool;
  bool _musicOn = false;
  bool _started = false;

  @override
  bool soundsEnabled = true;

  static void _log(Object e) => debugPrint('Ses hatası: $e');

  @override
  set musicEnabled(bool value) {
    _musicOn = value;
    value ? resumeMusic() : pauseMusic();
  }

  @override
  void pauseMusic() {
    if (_started) _music.pause().catchError(_log);
  }

  @override
  void resumeMusic() {
    if (!_musicOn) return;
    if (_started) {
      _music.resume().catchError(_log);
    } else {
      _started = true;
      _music
          .play(AssetSource('audio/muzik.ogg'), volume: 0.45)
          .catchError(_log);
    }
  }

  void _play(Future<AudioPool> pool, double volume) {
    if (!soundsEnabled) return;
    pool.then((p) => p.start(volume: volume)).catchError((Object e) {
      _log(e);
      return () async {};
    });
  }

  @override
  void plop() => _play(_plopPool, 0.6);

  @override
  void sparkle() => _play(_sparklePool, 0.6);
}
