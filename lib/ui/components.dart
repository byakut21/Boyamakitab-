import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFFFFF6E5);
  static const outline = Color(0xFF2B2B2B);
  static const toolIdle = Colors.white;
  static const toolSelected = Color(0xFFFFD54F);
}

/// Çocukların okumadan anlayacağı 12 canlı renk.
const List<int> paletteColors = [
  0xFFE53935, 0xFFFB8C00, 0xFFFDD835, 0xFF7CB342, //
  0xFF43A047, 0xFF00ACC1, 0xFF1E88E5, 0xFF8E24AA, //
  0xFFEC407A, 0xFF8D6E63, 0xFF212121, 0xFFFFFFFF, //
];

/// Büyük, yuvarlak, sadece simgeli düğme.
class BigIconButton extends StatelessWidget {
  const BigIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.enabled = true,
    this.color = AppColors.outline,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool enabled;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: AnimatedScale(
        scale: selected ? 1.1 : 1,
        duration: const Duration(milliseconds: 250),
        curve: Curves.elasticOut,
        child: Opacity(
          opacity: enabled ? 1 : 0.35,
          child: Material(
            color: selected ? AppColors.toolSelected : AppColors.toolIdle,
            shape: const CircleBorder(),
            elevation: selected ? 6 : 2,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: enabled ? onTap : null,
              child: SizedBox(
                width: 64,
                height: 64,
                child: Icon(icon, size: 38, color: color),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final int color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: selected ? 1.2 : 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Color(color),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.outline,
              width: selected ? 5 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: selected ? 6 : 2,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renk paleti: dikey ekranda alt alta iki satır, yatay ekranda yan yana iki sütun.
class PaletteBar extends StatelessWidget {
  const PaletteBar({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.vertical,
  });

  final int selected;
  final ValueChanged<int> onSelect;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final groups = [paletteColors.sublist(0, 6), paletteColors.sublist(6)];
    Widget group(List<int> colors) {
      final dots = [
        for (final c in colors)
          _ColorDot(
            color: c,
            selected: c == selected,
            onTap: () => onSelect(c),
          ),
      ];
      return vertical
          ? Column(mainAxisSize: MainAxisSize.min, spacing: 10, children: dots)
          : Row(mainAxisSize: MainAxisSize.min, spacing: 8, children: dots);
    }

    return vertical
        ? Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 10,
            children: groups.map(group).toList(),
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: groups.map(group).toList(),
          );
  }
}
