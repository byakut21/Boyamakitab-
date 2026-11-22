import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'art_renderer.dart';

/// Boyama araçları. Her biri yazısız, seçili renkte çizilen bir simgeyle gösterilir.
enum Tool { fill, pencil, marker, crayon, watercolor, rainbow, eraser }

/// Araç simgesi: seçili renkle boyanmış küçük bir kalem, pastel, silgi vb.
class ToolIcon extends StatelessWidget {
  const ToolIcon({super.key, required this.tool, required this.color});

  final Tool tool;
  final int color;

  @override
  Widget build(BuildContext context) {
    final c = Color(color);
    // Beyaz seçiliyken simge kaybolmasın.
    final visible = color == 0xFFFFFFFF ? const Color(0xFFBDBDBD) : c;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: switch (tool) {
        Tool.fill => FittedBox(
          child: Icon(Icons.format_color_fill_rounded, color: visible),
        ),
        Tool.marker => FittedBox(
          child: Icon(Icons.brush_rounded, color: visible),
        ),
        Tool.watercolor => FittedBox(
          child: Icon(
            Icons.water_drop_rounded,
            color: visible.withValues(alpha: 0.55),
          ),
        ),
        _ => CustomPaint(painter: _ToolPainter(tool, c), size: Size.infinite),
      },
    );
  }
}

class _ToolPainter extends CustomPainter {
  _ToolPainter(this.tool, this.color);

  final Tool tool;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height) / 100;
    canvas.translate((size.width - 100 * s) / 2, (size.height - 100 * s) / 2);
    canvas.scale(s);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..color = outlineColor
      ..strokeWidth = 5
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    Paint fill(Color c) => Paint()..color = c;

    // Tüm araçlar sol alttan sağ üste doğru 45 derece eğik çizilir.
    canvas.translate(50, 50);
    canvas.rotate(-math.pi / 4);
    switch (tool) {
      case Tool.pencil:
        final body = Rect.fromLTRB(-20, -10, 30, 10);
        canvas.drawRect(body, fill(color));
        canvas.drawRect(body, line);
        final wood = Path()
          ..moveTo(-20, -10)
          ..lineTo(-42, 0)
          ..lineTo(-20, 10)
          ..close();
        canvas.drawPath(wood, fill(const Color(0xFFFFE0B2)));
        final lead = Path()
          ..moveTo(-34, -3.6)
          ..lineTo(-42, 0)
          ..lineTo(-34, 3.6)
          ..close();
        canvas.drawPath(lead, fill(color));
        canvas.drawPath(wood, line);
        canvas.drawRRect(
          RRect.fromLTRBR(30, -10, 42, 10, const Radius.circular(4)),
          fill(const Color(0xFFF48FB1)),
        );
        canvas.drawRRect(
          RRect.fromLTRBR(30, -10, 42, 10, const Radius.circular(4)),
          line,
        );
      case Tool.crayon:
        final body = RRect.fromLTRBR(
          -22,
          -13,
          40,
          13,
          const Radius.circular(5),
        );
        canvas.drawRRect(body, fill(color));
        // Kâğıt sargı.
        canvas.drawRect(
          Rect.fromLTRB(-6, -13, 24, 13),
          fill(Colors.white.withValues(alpha: 0.75)),
        );
        canvas.drawLine(
          const Offset(2, -13),
          const Offset(2, 13),
          line..strokeWidth = 3,
        );
        canvas.drawLine(const Offset(16, -13), const Offset(16, 13), line);
        line.strokeWidth = 5;
        canvas.drawRRect(body, line);
        final tip = Path()
          ..moveTo(-22, -10)
          ..lineTo(-40, -4)
          ..lineTo(-40, 4)
          ..lineTo(-22, 10)
          ..close();
        canvas.drawPath(tip, fill(color));
        canvas.drawPath(tip, line);
      case Tool.rainbow:
        canvas.rotate(math.pi / 4);
        const colors = [
          Color(0xFFE53935), Color(0xFFFB8C00), Color(0xFFFDD835), //
          Color(0xFF43A047), Color(0xFF1E88E5), Color(0xFF8E24AA), //
        ];
        for (var i = 0; i < colors.length; i++) {
          final r = 40.0 - i * 6;
          canvas.drawArc(
            Rect.fromCircle(center: const Offset(0, 14), radius: r),
            math.pi,
            math.pi,
            false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 6.5
              ..color = colors[i],
          );
        }
      case Tool.eraser:
        final pink = RRect.fromLTRBR(-34, -16, 6, 16, const Radius.circular(6));
        final sleeve = RRect.fromLTRBR(
          4,
          -16,
          36,
          16,
          const Radius.circular(6),
        );
        canvas.drawRRect(pink, fill(const Color(0xFFF8BBD0)));
        canvas.drawRRect(sleeve, fill(const Color(0xFF64B5F6)));
        canvas.drawRRect(pink, line);
        canvas.drawRRect(sleeve, line);
      default:
        break;
    }
  }

  @override
  bool shouldRepaint(_ToolPainter old) =>
      old.tool != tool || old.color != color;
}

/// Kalınlık seçici: üç büyüklükte nokta.
class SizeDot extends StatelessWidget {
  const SizeDot({
    super.key,
    required this.level,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final int level;
  final bool selected;
  final int color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dot = 10.0 + level * 9;
    final c = color == 0xFFFFFFFF ? const Color(0xFFBDBDBD) : Color(color);
    return Semantics(
      button: true,
      selected: selected,
      label: const ['İnce', 'Orta', 'Kalın'][level],
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? const Color(0xFFFFD54F) : Colors.white,
            border: Border.all(color: outlineColor, width: selected ? 3 : 1.5),
          ),
          alignment: Alignment.center,
          child: Container(
            width: dot,
            height: dot,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}
