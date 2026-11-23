import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'data/app_audio.dart';
import 'data/kiosk.dart';
import 'data/storage.dart';
import 'model/artwork.dart';
import 'model/picture.dart';
import 'model/picture_library.dart';
import 'ui/coloring_screen.dart';
import 'ui/components.dart';
import 'ui/gallery_screen.dart';
import 'ui/parent_panel.dart';
import 'ui/pin_pad.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Tam ekran: çocuk yanlışlıkla alt/üst çubuklara dokunmasın.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  // Boyarken ekran kararmasın.
  WakelockPlus.enable().ignore();
  final storage = await Storage.open();
  runApp(BoyamaApp(storage: storage, audio: AppAudio()));
}

class BoyamaApp extends StatefulWidget {
  const BoyamaApp({
    super.key,
    required this.storage,
    required this.audio,
    this.kiosk = const Kiosk(),
  });

  final Storage storage;
  final AppAudio audio;
  final Kiosk kiosk;

  @override
  State<BoyamaApp> createState() => _BoyamaAppState();
}

class _BoyamaAppState extends State<BoyamaApp> {
  final _navigator = GlobalKey<NavigatorState>();
  late final Map<String, Artwork> artworks = widget.storage.loadAll(
    PictureLibrary.all,
  );
  late bool haptics = widget.storage.haptics;
  late bool music = widget.storage.music;
  late bool sounds = widget.storage.sounds;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    widget.audio
      ..soundsEnabled = sounds
      ..musicEnabled = music;
    // Uygulama arka plana gidince müzik sussun, dönünce devam etsin.
    _lifecycle = AppLifecycleListener(
      onHide: () {
        widget.audio.pauseMusic();
        _watch?.cancel();
      },
      onShow: () {
        widget.audio.resumeMusic();
        _applyChildLock();
        _startWatch();
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyChildLock());
    _startWatch();
  }

  Timer? _watch;
  bool _wasLocked = false;

  /// Ebeveyn, sabitleme kaldırılınca şifreyi doğru girdi: bir sonraki açılışa
  /// (veya kilidi panelden yeniden açana) kadar tekrar sabitleme.
  bool _suspended = false;
  bool _askingPin = false;

  /// Sabitlemenin "Geri" tuşuyla kaldırılıp kaldırılmadığını saniyede bir yoklar.
  void _startWatch() {
    _watch?.cancel();
    _watch = Timer.periodic(const Duration(seconds: 1), (_) => _checkLock());
  }

  Future<void> _checkLock() async {
    if (!widget.storage.childLock || _suspended) {
      _wasLocked = false;
      return;
    }
    final locked = await widget.kiosk.isLocked();
    if (_wasLocked && !locked) _onUnpinned();
    _wasLocked = locked;
  }

  /// Android sabitlemeyi kendi kısayoluyla kaldırdı: hemen yeniden sabitle ve
  /// kilidi gerçekten açmak için ebeveyn şifresini iste.
  Future<void> _onUnpinned() async {
    _lastLockRequest = DateTime.now();
    widget.kiosk.start();
    final pin = widget.storage.parentPin;
    final context = _navigator.currentContext;
    if (_askingPin || pin == null || context == null) return;
    _askingPin = true;
    final ok = await PinDialog.verify(
      context,
      pin,
      title: 'Kilidi açmak için ebeveyn şifresi',
    );
    _askingPin = false;
    if (ok) {
      _suspended = true;
      await widget.kiosk.stop();
    }
  }

  DateTime? _lastLockRequest;

  /// Çocuk kilidi açıksa uygulamayı ekrana sabitler.
  ///
  /// Uygulama açılınca ve arka plandan dönünce çağrılır. Android'in "Uygulama
  /// sabitlensin mi?" sorusu uygulamayı bir anlığına duraklattığı için
  /// sorudan dönüşte tekrar istenmez; aksi halde soru üst üste çıkıyordu.
  Future<void> _applyChildLock() async {
    if (!widget.storage.childLock || _suspended) return;
    if (await widget.kiosk.isLocked()) return;
    final now = DateTime.now();
    final last = _lastLockRequest;
    if (last != null && now.difference(last) < const Duration(seconds: 20)) {
      return;
    }
    _lastLockRequest = now;
    await widget.kiosk.start();
  }

  @override
  void dispose() {
    _watch?.cancel();
    _lifecycle.dispose();
    widget.audio.pauseMusic();
    super.dispose();
  }

  void _open(ColoringPicture picture) {
    _navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => ColoringScreen(
          picture: picture,
          initial: artworks[picture.id] ?? Artwork.blank,
          haptics: haptics,
          onPlop: widget.audio.plop,
          onSparkle: widget.audio.sparkle,
          onChanged: (art) {
            setState(() => artworks[picture.id] = art);
            widget.storage.save(picture.id, art);
          },
        ),
      ),
    );
  }

  /// Kilit 3 sn basılı tutulunca: önce şifre (ilk seferde şifre belirlenir), sonra panel.
  Future<void> _showParentPanel() async {
    final context = _navigator.currentContext!;
    final pin = widget.storage.parentPin;
    if (pin == null) {
      final created = await PinDialog.create(context);
      if (created == null) return;
      widget.storage.parentPin = created;
    } else if (!await PinDialog.verify(context, pin)) {
      return;
    }
    final fullLock = await widget.kiosk.isFullLock();
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => ParentPanel(
        childLock: widget.storage.childLock,
        fullLock: fullLock,
        onClearFullLock: () {
          _suspended = true;
          return widget.kiosk.clearFullLock();
        },
        onChildLockChanged: (v) {
          widget.storage.childLock = v;
          if (v) {
            _suspended = false;
            _lastLockRequest = DateTime.now();
            widget.kiosk.start();
          } else {
            widget.kiosk.stop();
          }
        },
        onChangePin: () async {
          final ctx = _navigator.currentContext!;
          final created = await PinDialog.create(ctx);
          if (created != null) widget.storage.parentPin = created;
          return created != null;
        },
        music: music,
        onMusicChanged: (v) {
          setState(() => music = v);
          widget.storage.music = v;
          widget.audio.musicEnabled = v;
        },
        sounds: sounds,
        onSoundsChanged: (v) {
          setState(() => sounds = v);
          widget.storage.sounds = v;
          widget.audio.soundsEnabled = v;
        },
        haptics: haptics,
        onHapticsChanged: (v) {
          setState(() => haptics = v);
          widget.storage.haptics = v;
        },
        onClearAll: () {
          setState(artworks.clear);
          widget.storage.deleteAll();
        },
        onExit: () {
          _suspended = true;
          widget.kiosk.exit();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigator,
      title: 'Boyama Kitabı',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFFFB300),
        scaffoldBackgroundColor: AppColors.background,
      ),
      home: GalleryScreen(
        artworks: artworks,
        onOpen: _open,
        onParentUnlocked: _showParentPanel,
      ),
    );
  }
}
