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
  Tool.eraser: 'Silgi',
};

BrushKind? _brushFor(Tool tool) => switch (tool) {
  Tool.fill => null,
  Tool.pencil => BrushKind.pencil,
  Tool.marker => BrushKind.marker,
  Tool.crayon => BrushKind.crayon,
  Tool.watercolor => BrushKind.watercolor,
  Tool.rainbow => BrushKind.rainbow,
  Tool.eraser => BrushKind.eraser,
};

class ColoringScreen extends StatefulWidget {
  const ColoringScreen({
    super.key,
    required this.picture,
    required this.initial,
    required this.haptics,
    required this.onChanged,
  });

  final ColoringPicture picture;
  final Artwork initial;
  final bool haptics;
  final ValueChanged<Artwork> onChanged;

  @override
  State<ColoringScreen> createState() => _ColoringScreenState();
}

class _ColoringScreenState extends State<ColoringScreen> {
  late final controller = ColoringController(widget.picture, widget.initial);
  Tool tool = Tool.fill;
  int color = paletteColors.first;
  int sizeLevel = 1;

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
          padding: const EdgeInsets.all(10),
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
                      size: 56,
                    ),
                    BigIconButton(
                      icon: Icons.undo_rounded,
                      label: 'Geri al',
                      onTap: () {
                        if (controller.undo()) _changed();
                      },
                      enabled: controller.canUndo,
                      size: 56,
                    ),
                    BigIconButton(
                      icon: Icons.delete_rounded,
                      label: 'Temizle',
                      onTap: () {
                        if (controller.clearAll()) _changed();
                      },
                      color: const Color(0xFF8D6E63),
                      size: 56,
                    ),
                  ];
                  return landscape
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 8,
                          children: buttons,
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 8,
                          children: buttons,
                        );
                },
              );

              // Kalınlık sadece çizim araçlarında anlamlı; boyamada soluk görünür.
              final sizes = AnimatedOpacity(
                opacity: tool == Tool.fill ? 0.3 : 1,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: tool == Tool.fill,
                  child: Flex(
                    direction: landscape ? Axis.vertical : Axis.horizontal,
                    mainAxisSize: MainAxisSize.min,
                    spacing: 6,
                    children: [
                      for (var i = 0; i < brushSizes.length; i++)
                        SizeDot(
                          level: i,
                          selected: sizeLevel == i,
                          color: color,
                          onTap: () {
                            setState(() => sizeLevel = i);
                            _buzz();
                          },
                        ),
                    ],
                  ),
                ),
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
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Center(
                    child: _DrawingCanvas(
                      controller: controller,
                      tool: tool,
                      color: color,
                      sizeFactor: brushSizes[sizeLevel],
                      onAction: _changed,
                    ),
                  ),
                ),
              );

              if (landscape) {
                return Row(
                  spacing: 8,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [actions, sizes],
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [actions, sizes],
                  ),
                  canvas,
                  tools,
                  palette,
                  const SizedBox(height: 4),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Yedi araç: dikey ekranda tek satır, yatay ekranda tek sütun. Düğme boyutu
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
        const gap = 6.0;
        final n = Tool.values.length;
        final available = vertical
            ? constraints.maxHeight
            : constraints.maxWidth;
        final size = math.min(60.0, (available - gap * (n - 1)) / n - 2);
        final buttons = [
          for (final t in Tool.values)
            BigIconButton(
              icon: Icons.circle,
              label: _toolLabels[t]!,
              selected: t == selected,
              onTap: () => onSelect(t),
              size: size,
              child: ToolIcon(tool: t, color: color),
            ),
        ];
        return vertical
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: gap,
                children: buttons,
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: gap,
                children: buttons,
              );
      },
    );
  }
}

/// Boyama alanı: kare, beyaz, köşeleri yuvarlak. Dokunuşlar resim koordinatlarına çevrilir.
class _DrawingCanvas extends StatefulWidget {
  const _DrawingCanvas({
    required this.controller,
    required this.tool,
    required this.color,
    required this.sizeFactor,
    required this.onAction,
  });

  final ColoringController controller;
  final Tool tool;
  final int color;
  final double sizeFactor;
  final VoidCallback onAction;

  @override
  State<_DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<_DrawingCanvas> {
  int? _pointer;
  Offset? _downAt;

  Offset _toPicture(Offset local, Size size) =>
      local / (size.width / canvasSize);

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
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
                      _toPicture(e.localPosition, size),
                      brush,
                      widget.color,
                      brush.baseWidth * widget.sizeFactor,
                    );
                  }
                },
                onPointerMove: (e) {
                  if (e.pointer != _pointer) return;
                  c.extendStroke(_toPicture(e.localPosition, size));
                },
                onPointerUp: (e) {
                  if (e.pointer != _pointer) return;
                  _pointer = null;
                  if (c.current != null) {
                    if (c.endStroke()) widget.onAction();
                  } else if ((e.localPosition - _downAt!).distance < 40 &&
                      c.fillAt(_toPicture(_downAt!, size), widget.color)) {
                    widget.onAction();
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
      ),
    );
  }
}
