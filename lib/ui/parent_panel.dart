import 'package:flutter/material.dart';

/// Sadece yetişkinler için: ayarlar, temizleme ve uygulamadan çıkış.
class ParentPanel extends StatefulWidget {
  const ParentPanel({
    super.key,
    required this.childLock,
    this.fullLock = false,
    this.onClearFullLock,
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

  /// Uygulama cihaz sahibi: sabitleme sorusuz, uyarısız ve kısayolla açılamaz.
  final bool fullLock;
  final Future<void> Function()? onClearFullLock;
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
  late bool fullLock = widget.fullLock;
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
            if (fullLock)
              OutlinedButton.icon(
                icon: const Icon(Icons.verified_user_rounded),
                onPressed: () async {
                  await widget.onClearFullLock?.call();
                  if (mounted) setState(() => fullLock = false);
                },
                label: const Text('Tam kilit açık · kaldırmak için dokunun'),
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
              fullLock
                  ? 'Tam kilit açık: uygulama uyarısız sabitlenir ve çıkış sadece '
                        'bu panelden yapılır. '
                        'Uygulama internet kullanmaz, reklam içermez ve veri toplamaz.'
                  : 'Android sabitlerken "Uygulama sabitlensin mi?" diye sorar ve '
                        '"Uygulama sabitlendi" uyarısı gösterir; bu, telefonun kendi '
                        'güvenlik uyarısıdır. "Geri" ve "Son uygulamalar" tuşlarına '
                        'birlikte uzun basmak da kilidi açar. Bunu şifreye bağlamak için '
                        'Ayarlar > Güvenlik > Uygulama sabitleme bölümünde '
                        '"Sabitlemeyi kaldırmadan önce PIN iste" seçeneğini açın. '
                        'Uyarısız tam kilit için README\'deki "Tam kilit" adımlarına bakın. '
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
