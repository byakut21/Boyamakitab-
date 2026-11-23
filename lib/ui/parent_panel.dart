import 'package:flutter/material.dart';

/// Sadece yetişkinler için: ayarlar, temizleme ve uygulamadan çıkış.
class ParentPanel extends StatefulWidget {
  const ParentPanel({
    super.key,
    required this.childLock,
    required this.onChildLockChanged,
    required this.onChangePin,
    required this.haptics,
    required this.onHapticsChanged,
    required this.music,
    required this.onMusicChanged,
    required this.sounds,
    required this.onSoundsChanged,
    required this.onClearAll,
    required this.onExit,
  });

  final bool childLock;
  final ValueChanged<bool> onChildLockChanged;

  /// Yeni şifre belirletir; değiştiyse true döner.
  final Future<bool> Function() onChangePin;
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
  late bool childLock = widget.childLock;
  bool pinChanged = false;
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
              title: const Text('Çocuk kilidi'),
              subtitle: const Text(
                'Uygulama ekrana sabitlenir: ana ekran, son uygulamalar ve '
                'bildirimler çalışmaz. Çıkış sadece bu panelden, şifreyle.',
              ),
              value: childLock,
              onChanged: (v) {
                setState(() => childLock = v);
                widget.onChildLockChanged(v);
              },
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.password_rounded),
              onPressed: () async {
                final changed = await widget.onChangePin();
                if (changed && mounted) setState(() => pinChanged = true);
              },
              label: Text(
                pinChanged ? 'Şifre değiştirildi' : 'Şifreyi değiştir',
              ),
            ),
            const Divider(),
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
              child: const Text('Kilidi kaldır ve uygulamadan çık'),
            ),
            Text(
              'Çocuk kilidi açıkken Android, "Geri" ve "Son uygulamalar" tuşlarına '
              'birlikte uzun basılarak da kilidi açmaya izin verir. Bunu da şifreye '
              'bağlamak için telefonun Ayarlar > Güvenlik > Uygulama sabitleme '
              'bölümünde "Sabitlemeyi kaldırmadan önce PIN iste" seçeneğini açın. '
              'Uygulama internet kullanmaz, reklam içermez ve veri toplamaz.',
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
