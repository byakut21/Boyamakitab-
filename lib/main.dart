import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'data/storage.dart';
import 'model/artwork.dart';
import 'model/picture.dart';
import 'model/picture_library.dart';
import 'ui/coloring_screen.dart';
import 'ui/components.dart';
import 'ui/gallery_screen.dart';
import 'ui/parent_panel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Tam ekran: çocuk yanlışlıkla alt/üst çubuklara dokunmasın.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  // Boyarken ekran kararmasın.
  WakelockPlus.enable().ignore();
  final storage = await Storage.open();
  runApp(BoyamaApp(storage: storage));
}

class BoyamaApp extends StatefulWidget {
  const BoyamaApp({super.key, required this.storage});

  final Storage storage;

  @override
  State<BoyamaApp> createState() => _BoyamaAppState();
}

class _BoyamaAppState extends State<BoyamaApp> {
  final _navigator = GlobalKey<NavigatorState>();
  late final Map<String, Artwork> artworks = widget.storage.loadAll(
    PictureLibrary.all,
  );
  late bool haptics = widget.storage.haptics;

  void _open(ColoringPicture picture) {
    _navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => ColoringScreen(
          picture: picture,
          initial: artworks[picture.id] ?? Artwork.blank(picture),
          haptics: haptics,
          onChanged: (art) {
            setState(() => artworks[picture.id] = art);
            widget.storage.save(picture.id, art);
          },
        ),
      ),
    );
  }

  void _showParentPanel() {
    showDialog<void>(
      context: _navigator.currentContext!,
      builder: (_) => ParentPanel(
        haptics: haptics,
        onHapticsChanged: (v) {
          setState(() => haptics = v);
          widget.storage.haptics = v;
        },
        onClearAll: () {
          setState(artworks.clear);
          widget.storage.deleteAll();
        },
        onExit: () => SystemNavigator.pop(),
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
