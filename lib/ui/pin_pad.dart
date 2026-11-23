import 'package:flutter/material.dart';

/// Ebeveyn şifresi ekranı: büyük rakam tuşları ve 4 nokta.
///
/// [existingPin] verilirse şifre sorulur; verilmezse yeni şifre iki kez girilerek
/// belirlenir. Doğru şifrede (ya da yeni şifre belirlenince) şifreyle birlikte kapanır.
class PinDialog extends StatefulWidget {
  const PinDialog({super.key, this.existingPin, this.title});

  final String? existingPin;
  final String? title;

  /// Şifreyi sorar; doğruysa true döner.
  static Future<bool> verify(
    BuildContext context,
    String pin, {
    String? title,
  }) async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PinDialog(existingPin: pin, title: title),
    );
    return result == pin;
  }

  /// Yeni şifre belirletir; vazgeçilirse null döner.
  static Future<String?> create(BuildContext context) => showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PinDialog(),
  );

  @override
  State<PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<PinDialog> {
  static const length = 4;
  String _entered = '';
  String? _first; // yeni şifre belirlerken ilk giriş
  String? _error;
  int _wrong = 0;

  bool get _creating => widget.existingPin == null;

  String get _prompt {
    if (!_creating) return widget.title ?? 'Ebeveyn şifresini girin';
    return _first == null
        ? 'Yeni 4 haneli şifre belirleyin'
        : 'Şifreyi tekrar girin';
  }

  void _digit(int d) {
    if (_entered.length >= length) return;
    setState(() {
      _entered += '$d';
      _error = null;
    });
    if (_entered.length == length) _complete();
  }

  void _complete() {
    final pin = _entered;
    if (!_creating) {
      if (pin == widget.existingPin) {
        Navigator.of(context).pop(pin);
      } else {
        setState(() {
          _wrong++;
          _entered = '';
          _error = 'Şifre yanlış';
        });
      }
      return;
    }
    if (_first == null) {
      setState(() {
        _first = pin;
        _entered = '';
      });
    } else if (_first == pin) {
      Navigator.of(context).pop(pin);
    } else {
      setState(() {
        _first = null;
        _entered = '';
        _error = 'Şifreler aynı değil, baştan girin';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget key(Widget child, VoidCallback? onTap, {String? label}) => Semantics(
      button: true,
      label: label,
      child: SizedBox(
        width: 68,
        height: 68,
        child: Material(
          color: onTap == null
              ? Colors.transparent
              : theme.colorScheme.surfaceContainerHighest,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Center(child: child),
          ),
        ),
      ),
    );
    Widget digit(int d) => key(
      Text('$d', style: theme.textTheme.headlineSmall),
      () => _digit(d),
      label: '$d',
    );

    return AlertDialog(
      title: Text(_prompt, textAlign: TextAlign.center),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 14,
              children: [
                for (var i = 0; i < length; i++)
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < _entered.length
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(
              height: 20,
              child: Text(
                _error ?? '',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
            for (final row in const [
              [1, 2, 3],
              [4, 5, 6],
              [7, 8, 9],
            ])
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 12,
                children: [for (final d in row) digit(d)],
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 12,
              children: [
                key(const SizedBox(), null),
                digit(0),
                key(
                  const Icon(Icons.backspace_outlined),
                  _entered.isEmpty
                      ? null
                      : () => setState(
                          () => _entered = _entered.substring(
                            0,
                            _entered.length - 1,
                          ),
                        ),
                  label: 'Sil',
                ),
              ],
            ),
            if (!_creating && _wrong >= 3)
              Text(
                'Şifreyi unuttuysanız: Ayarlar > Uygulamalar > Boyama Kitabı > '
                'Depolama > Verileri temizle ile sıfırlayabilirsiniz (boyamalar da silinir).',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Vazgeç'),
        ),
      ],
    );
  }
}
