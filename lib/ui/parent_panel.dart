import 'package:flutter/material.dart';

/// Sadece yetişkinler için: ayarlar, temizleme ve uygulamadan çıkış.
class ParentPanel extends StatefulWidget {
  const ParentPanel({
    super.key,
    required this.haptics,
    required this.onHapticsChanged,
    required this.music,
    required this.onMusicChanged,
    required this.sounds,
    required this.onSoundsChanged,
    required this.onClearAll,
    required this.onExit,
  });

  final bool haptics;
  final ValueChanged<bool> onHapticsChanged;
  final bool music;
  final ValueChanged<bool> onMusicChanged;
  final bool sounds;
  final ValueChanged<bool> onSoundsChanged;
  final VoidCallback onClearAll;
  final VoidCallback onExit;

  @override
  State<ParentPanel> createState() => _ParentPanelState();
}

class _ParentPanelState extends State<ParentPanel> {
  late bool haptics = widget.haptics;
  late bool music = widget.music;
  late bool sounds = widget.sounds;
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
          spacing: 8,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Müzik'),
              value: music,
              onChanged: (v) {
                setState(() => music = v);
                widget.onMusicChanged(v);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ses efektleri'),
              value: sounds,
              onChanged: (v) {
                setState(() => sounds = v);
                widget.onSoundsChanged(v);
              },
            ),
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
