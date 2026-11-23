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
      onHide: widget.audio.pauseMusic,
      onShow: widget.audio.resumeMusic,
      onResume: _applyChildLock,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyChildLock());
  }

  /// Çocuk kilidi açıksa uygulamayı ekrana sabitler.
  void _applyChildLock() {
    if (widget.storage.childLock) widget.kiosk.start();
  }

  @override
  void dispose() {
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
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => ParentPanel(
        childLock: widget.storage.childLock,
        onChildLockChanged: (v) {
          widget.storage.childLock = v;
          v ? widget.kiosk.start() : widget.kiosk.stop();
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
        onExit: widget.kiosk.exit,
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
