import 'package:flutter/material.dart';

import '../model/artwork.dart';
import '../model/picture.dart';
import '../model/picture_library.dart';
import 'components.dart';
import 'picture_painter.dart';

/// Ana ekran: resimlerin büyük kartlar halinde listesi. Yazı yok, sadece resimler.
class GalleryScreen extends StatelessWidget {
  const GalleryScreen({
    super.key,
    required this.artworks,
    required this.onOpen,
    required this.onParentUnlocked,
  });

  final Map<String, Artwork> artworks;
  final ValueChanged<ColoringPicture> onOpen;
  final VoidCallback onParentUnlocked;

  @override
  Widget build(BuildContext context) {
    // Çocuk geri tuşuyla yanlışlıkla uygulamadan çıkmasın; çıkış ebeveyn panelinde.
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _RainbowDots(),
                    ParentLockButton(onUnlocked: onParentUnlocked),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 240,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                  ),
                  itemCount: PictureLibrary.all.length,
                  itemBuilder: (context, i) {
                    final picture = PictureLibrary.all[i];
                    final art = artworks[picture.id] ?? Artwork.blank(picture);
                    return Semantics(
                      button: true,
                      label: picture.name,
                      child: Material(
                        color: Colors.white,
                        elevation: 4,
                        borderRadius: BorderRadius.circular(28),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => onOpen(picture),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: CustomPaint(
                              size: Size.infinite,
                              painter: PicturePainter(
                                picture: picture,
                                fills: art.fills,
                                strokes: art.strokes,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RainbowDots extends StatelessWidget {
  const _RainbowDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      children: [
        for (final c in paletteColors.take(8))
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(color: Color(c), shape: BoxShape.circle),
          ),
      ],
    );
  }
}

/// Ebeveyn kilidi: küçük ve soluk bir kilit. 3 saniye basılı tutulunca açılır.
/// Küçük çocuklar genelde kısa dokunur; bu yüzden basit ama etkili bir kapıdır.
class ParentLockButton extends StatefulWidget {
  const ParentLockButton({super.key, required this.onUnlocked});

  final VoidCallback onUnlocked;

  @override
  State<ParentLockButton> createState() => _ParentLockButtonState();
}

class _ParentLockButtonState extends State<ParentLockButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hold =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _hold.value = 0;
            widget.onUnlocked();
          }
        });

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  void _release() {
    if (_hold.isAnimating) _hold.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Ebeveyn paneli: 3 saniye basılı tutun',
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => _hold.forward(from: 0),
        onPointerUp: (_) => _release(),
        onPointerCancel: (_) => _release(),
        child: SizedBox(
          width: 56,
          height: 56,
          child: AnimatedBuilder(
            animation: _hold,
            builder: (context, _) => Stack(
              alignment: Alignment.center,
              children: [
                if (_hold.value > 0)
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      value: _hold.value,
                      strokeWidth: 4,
                      color: const Color(0xFF1E88E5),
                    ),
                  ),
                const Icon(
                  Icons.lock_rounded,
                  size: 26,
                  color: Color(0x55000000),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
