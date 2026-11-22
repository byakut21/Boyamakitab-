import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../model/artwork.dart';
import '../model/coloring_controller.dart';
import '../model/picture.dart';
import 'components.dart';
import 'picture_painter.dart';
import 'tool_icons.dart';

const _toolLabels = {
  Tool.fill: 'Dokun ve boya',
  Tool.pencil: 'Kalem',
  Tool.marker: 'Fırça',
  Tool.crayon: 'Pastel boya',
  Tool.watercolor: 'Sulu boya',
  Tool.rainbow: 'Gökkuşağı fırçası',
  Tool.glitter: 'Simli fırça',
  Tool.stars: 'Yıldız fırçası',
  Tool.sticker: 'Çıkartma',
  Tool.eraser: 'Silgi',
};

BrushKind? _brushFor(Tool tool) => switch (tool) {
  Tool.fill || Tool.sticker => null,
  Tool.pencil => BrushKind.pencil,
  Tool.marker => BrushKind.marker,
  Tool.crayon => BrushKind.crayon,
  Tool.watercolor => BrushKind.watercolor,
  Tool.rainbow => BrushKind.rainbow,
  Tool.glitter => BrushKind.glitter,
  Tool.stars => BrushKind.stars,
  Tool.eraser => BrushKind.eraser,
};

class ColoringScreen extends StatefulWidget {
  const ColoringScreen({
    super.key,
    required this.picture,
    required this.initial,
    required this.haptics,
    required this.onChanged,
    this.onPlop,
    this.onSparkle,
  });

  final ColoringPicture picture;
  final Artwork initial;
  final bool haptics;
  final ValueChanged<Artwork> onChanged;

  /// Boyamada çalınacak kısa ses.
  final VoidCallback? onPlop;

  /// Çıkartmada çalınacak ses.
  final VoidCallback? onSparkle;

  @override
  State<ColoringScreen> createState() => _ColoringScreenState();
}

class _ColoringScreenState extends State<ColoringScreen> {
  late final controller = ColoringController(widget.picture, widget.initial);
  Tool tool = Tool.fill;
  int color = paletteColors.first;
  int sizeLevel = 1;
  Sticker sticker = Sticker.star;

  static const stickerSize = 170.0;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _buzz() {
    if (widget.haptics) HapticFeedback.mediumImpact();
  }

  void _changed() {
    _buzz();
    widget.onChanged(controller.toArtwork());
  }

  void _selectTool(Tool t) {
    setState(() => tool = t);
    _buzz();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final landscape = constraints.maxWidth > constraints.maxHeight;

              final actions = ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  final buttons = [
                    BigIconButton(
                      icon: Icons.home_rounded,
                      label: 'Ana sayfa',
                      onTap: () => Navigator.of(context).pop(),
                      color: const Color(0xFF1E88E5),
                      size: 50,
                    ),
                    BigIconButton(
                      icon: Icons.undo_rounded,
                      label: 'Geri al',
                      onTap: () {
                        if (controller.undo()) _changed();
                      },
                      enabled: controller.canUndo,
                      size: 50,
                    ),
                    BigIconButton(
                      icon: Icons.delete_rounded,
                      label: 'Temizle',
                      onTap: () {
                        if (controller.clearAll()) _changed();
                      },
                      color: const Color(0xFF8D6E63),
                      size: 50,
                    ),
                  ];
                  return Flex(
                    direction: landscape ? Axis.vertical : Axis.horizontal,
                    mainAxisSize: MainAxisSize.min,
                    spacing: 6,
                    children: buttons,
                  );
                },
              );

              final selector = _OptionSelector(
                vertical: landscape,
                tool: tool,
                color: color,
                sizeLevel: sizeLevel,
                sticker: sticker,
                onSize: (i) {
                  setState(() => sizeLevel = i);
                  _buzz();
                },
                onSticker: (st) {
                  setState(() => sticker = st);
                  _buzz();
                },
              );

              final tools = _ToolBar(
                vertical: landscape,
                selected: tool,
                color: color,
                onSelect: _selectTool,
              );

              final palette = PaletteBar(
                selected: color,
                vertical: landscape,
                onSelect: (c) {
                  setState(() {
                    color = c;
                    // Silgi ya da gökkuşağındayken renk seçilirse boyamaya dön.
                    if (tool == Tool.eraser || tool == Tool.rainbow) {
                      tool = Tool.fill;
                    }
                  });
                  _buzz();
                },
              );

              final canvas = Expanded(
                child: _DrawingCanvas(
                  controller: controller,
                  tool: tool,
                  color: color,
                  sizeFactor: brushSizes[sizeLevel],
                  sticker: sticker,
                  stickerSize: stickerSize * brushSizes[sizeLevel],
                  onAction: _changed,
                  onPlop: widget.onPlop,
                  onSparkle: widget.onSparkle,
                ),
              );

              if (landscape) {
                return Row(
                  spacing: 8,
                  children: [
                    Column(
                      spacing: 10,
                      children: [
                        actions,
                        Expanded(child: selector),
                      ],
                    ),
                    tools,
                    canvas,
                    palette,
                  ],
                );
              }
              return Column(
                spacing: 8,
                children: [
                  SizedBox(
                    height: 54,
                    child: Row(
                      spacing: 8,
                      children: [
                        actions,
                        Expanded(child: selector),
                      ],
                    ),
                  ),
                  canvas,
                  tools,
                  palette,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Kalınlık seçimi; çıkartma aracında ise hangi çıkartmanın yapıştırılacağı.
class _OptionSelector extends StatelessWidget {
  const _OptionSelector({
    required this.vertical,
    required this.tool,
    required this.color,
    required this.sizeLevel,
    required this.sticker,
    required this.onSize,
    required this.onSticker,
  });

  final bool vertical;
  final Tool tool;
  final int color;
  final int sizeLevel;
  final Sticker sticker;
  final ValueChanged<int> onSize;
  final ValueChanged<Sticker> onSticker;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 6.0;
        final count = tool == Tool.sticker
            ? Sticker.values.length
            : brushSizes.length;
        final available = vertical
            ? constraints.maxHeight
            : constraints.maxWidth;
        final size = ((available - gap * (count - 1)) / count - 4).clamp(
          28.0,
          48.0,
        );
        final children = tool == Tool.sticker
            ? [
                for (final st in Sticker.values)
                  BigIconButton(
                    icon: Icons.circle,
                    label: 'Çıkartma',
                    selected: st == sticker,
                    size: size,
                    onTap: () => onSticker(st),
                    child: StickerIcon(sticker: st, color: color),
                  ),
              ]
            : [
                for (var i = 0; i < brushSizes.length; i++)
                  SizeDot(
                    level: i,
                    selected: sizeLevel == i,
                    color: color,
                    size: size,
                    onTap: () => onSize(i),
                  ),
              ];
        // Kalınlık boyamada anlamsız; soluk gösterilir.
        return AnimatedOpacity(
          opacity: tool == Tool.fill ? 0.3 : 1,
          duration: const Duration(milliseconds: 200),
          child: IgnorePointer(
            ignoring: tool == Tool.fill,
            child: Align(
              alignment: vertical ? Alignment.center : Alignment.centerRight,
              child: Flex(
                direction: vertical ? Axis.vertical : Axis.horizontal,
                mainAxisSize: MainAxisSize.min,
                spacing: gap,
                children: children,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// On araç: dikey ekranda iki satır, yatay ekranda iki sütun. Düğme boyutu
/// ekrana sığacak şekilde ayarlanır.
class _ToolBar extends StatelessWidget {
  const _ToolBar({
    required this.vertical,
    required this.selected,
    required this.color,
    required this.onSelect,
  });

  final bool vertical;
  final Tool selected;
  final int color;
  final ValueChanged<Tool> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        const perLine = 5;
        final available = vertical
            ? constraints.maxHeight
            : constraints.maxWidth;
        final size = math.min(
          60.0,
          (available - gap * (perLine - 1)) / perLine - 4,
        );
        Widget button(Tool t) => BigIconButton(
          icon: Icons.circle,
          label: _toolLabels[t]!,
          selected: t == selected,
          onTap: () => onSelect(t),
          size: size,
          child: ToolIcon(tool: t, color: color),
        );
        final lines = [
          for (var i = 0; i < Tool.values.length; i += perLine)
            Flex(
              direction: vertical ? Axis.vertical : Axis.horizontal,
              mainAxisSize: MainAxisSize.min,
              spacing: gap,
              children: [
                for (final t in Tool.values.skip(i).take(perLine)) button(t),
              ],
            ),
        ];
        return Flex(
          direction: vertical ? Axis.horizontal : Axis.vertical,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: gap,
          children: lines,
        );
      },
    );
  }
}

/// Boyama alanı: ekranda kalan alanın tamamı. Resim ortada en büyük boyda durur,
/// çevresindeki boşluk da boyanıp çizilebilir.
class _DrawingCanvas extends StatefulWidget {
  const _DrawingCanvas({
    required this.controller,
    required this.tool,
    required this.color,
    required this.sizeFactor,
    required this.sticker,
    required this.stickerSize,
    required this.onAction,
    this.onPlop,
    this.onSparkle,
  });

  final ColoringController controller;
  final Tool tool;
  final int color;
  final double sizeFactor;
  final Sticker sticker;
  final double stickerSize;
  final VoidCallback onAction;
  final VoidCallback? onPlop;
  final VoidCallback? onSparkle;

  @override
  State<_DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<_DrawingCanvas> {
  int? _pointer;
  Offset? _downAt;

  void _tap(PictureLayout layout, Offset local) {
    final c = widget.controller;
    final p = layout.toPicture(local);
    if (widget.tool == Tool.sticker) {
      c.placeSticker(p, widget.sticker, widget.color, widget.stickerSize);
      widget.onSparkle?.call();
    } else if (c.fillAt(p, widget.color)) {
      widget.onPlop?.call();
    } else {
      return;
    }
    widget.onAction();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            final layout = PictureLayout(size);
            // Ham dokunma olayları: sadece ilk parmak dikkate alınır, avuç içi
            // ya da ikinci parmak çizimi bozmaz.
            return Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (e) {
                if (_pointer != null) return;
                _pointer = e.pointer;
                _downAt = e.localPosition;
                final brush = _brushFor(widget.tool);
                if (brush != null) {
                  c.startStroke(
                    layout.toPicture(e.localPosition),
                    brush,
                    widget.color,
                    brush.baseWidth * widget.sizeFactor,
                  );
                }
              },
              onPointerMove: (e) {
                if (e.pointer != _pointer) return;
                c.extendStroke(layout.toPicture(e.localPosition));
              },
              onPointerUp: (e) {
                if (e.pointer != _pointer) return;
                _pointer = null;
                if (c.current != null) {
                  if (c.endStroke()) widget.onAction();
                } else if ((e.localPosition - _downAt!).distance < 40) {
                  _tap(layout, _downAt!);
                }
              },
              onPointerCancel: (e) {
                if (e.pointer != _pointer) return;
                _pointer = null;
                if (c.endStroke()) widget.onAction();
              },
              child: CustomPaint(
                size: size,
                painter: PicturePainter(picture: c.picture, live: c),
              ),
            );
          },
        ),
      ),
    );
  }
}
