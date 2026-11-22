import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../model/artwork.dart';
import '../model/coloring_controller.dart';
import '../model/picture.dart';
import 'components.dart';
import 'picture_painter.dart';

enum Tool { fill, brush }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final landscape = constraints.maxWidth > constraints.maxHeight;
              final tools = _ToolButtons(
                vertical: landscape,
                tool: tool,
                controller: controller,
                onHome: () => Navigator.of(context).pop(),
                onTool: (t) {
                  setState(() => tool = t);
                  _buzz();
                },
                onUndo: () {
                  if (controller.undo()) _changed();
                },
                onClear: () {
                  if (controller.clearAll()) _changed();
                },
              );
              final palette = PaletteBar(
                selected: color,
                vertical: landscape,
                onSelect: (c) {
                  setState(() => color = c);
                  _buzz();
                },
              );
              final canvas = Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Center(
                    child: _DrawingCanvas(
                      controller: controller,
                      tool: tool,
                      color: color,
                      onAction: _changed,
                    ),
                  ),
                ),
              );
              return landscape
                  ? Row(children: [tools, canvas, palette])
                  : Column(
                      children: [
                        tools,
                        canvas,
                        palette,
                        const SizedBox(height: 8),
                      ],
                    );
            },
          ),
        ),
      ),
    );
  }
}

class _ToolButtons extends StatelessWidget {
  const _ToolButtons({
    required this.vertical,
    required this.tool,
    required this.controller,
    required this.onHome,
    required this.onTool,
    required this.onUndo,
    required this.onClear,
  });

  final bool vertical;
  final Tool tool;
  final ColoringController controller;
  final VoidCallback onHome;
  final ValueChanged<Tool> onTool;
  final VoidCallback onUndo;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final buttons = [
          BigIconButton(
            icon: Icons.home_rounded,
            label: 'Ana sayfa',
            onTap: onHome,
            color: const Color(0xFF1E88E5),
          ),
          BigIconButton(
            icon: Icons.format_color_fill_rounded,
            label: 'Dokun ve boya',
            onTap: () => onTool(Tool.fill),
            selected: tool == Tool.fill,
            color: const Color(0xFFE53935),
          ),
          BigIconButton(
            icon: Icons.brush_rounded,
            label: 'Parmakla çiz',
            onTap: () => onTool(Tool.brush),
            selected: tool == Tool.brush,
            color: const Color(0xFF8E24AA),
          ),
          BigIconButton(
            icon: Icons.undo_rounded,
            label: 'Geri al',
            onTap: onUndo,
            enabled: controller.canUndo,
          ),
          BigIconButton(
            icon: Icons.delete_rounded,
            label: 'Temizle',
            onTap: onClear,
            color: const Color(0xFF8D6E63),
          ),
        ];
        return vertical
            ? Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: buttons,
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
    required this.onAction,
  });

  final ColoringController controller;
  final Tool tool;
  final int color;
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
                  if (widget.tool == Tool.brush) {
                    c.startStroke(
                      _toPicture(e.localPosition, size),
                      widget.color,
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
                  if (c.currentPoints != null) {
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
                  painter: PicturePainter(
                    picture: c.picture,
                    fills: c.fills,
                    strokes: c.strokes,
                    live: c,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
