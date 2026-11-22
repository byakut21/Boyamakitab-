import 'package:flutter/material.dart';

/// Sadece yetişkinler için: ayarlar, temizleme ve uygulamadan çıkış.
class ParentPanel extends StatefulWidget {
  const ParentPanel({
    super.key,
    required this.haptics,
    required this.onHapticsChanged,
    required this.onClearAll,
    required this.onExit,
  });

  final bool haptics;
  final ValueChanged<bool> onHapticsChanged;
  final VoidCallback onClearAll;
  final VoidCallback onExit;

  @override
  State<ParentPanel> createState() => _ParentPanelState();
}

class _ParentPanelState extends State<ParentPanel> {
  late bool haptics = widget.haptics;
  bool confirmClear = false;
  bool cleared = false;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AlertDialog(
      title: const Text('Ebeveyn Paneli'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Dokununca titreşim'),
              value: haptics,
              onChanged: (v) {
                setState(() => haptics = v);
                widget.onHapticsChanged(v);
              },
            ),
            OutlinedButton(
              onPressed: cleared
                  ? null
                  : () {
                      if (confirmClear) {
                        widget.onClearAll();
                        setState(() => cleared = true);
                      } else {
                        setState(() => confirmClear = true);
                      }
                    },
              child: Text(
                cleared
                    ? 'Tüm boyamalar silindi'
                    : confirmClear
                    ? 'Emin misiniz? Silmek için tekrar dokunun'
                    : 'Tüm boyamaları sil',
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
              ),
              onPressed: widget.onExit,
              child: const Text('Uygulamadan çık'),
            ),
            Text(
              'İpucu: Çocuğunuzun uygulamadan çıkmaması için Android\'in '
              '"Uygulama sabitleme" özelliğini kullanabilirsiniz '
              '(Ayarlar > Güvenlik > Uygulama sabitleme). Uygulama internet '
              'kullanmaz, reklam içermez ve hiçbir veri toplamaz.',
              style: text.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Kapat'),
        ),
      ],
    );
  }
}
