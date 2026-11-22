import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/artwork.dart';
import '../model/picture.dart';

/// Boyamaları ve ayarları cihazda saklar. Hiçbir veri cihazdan çıkmaz.
class Storage {
  Storage._(this._prefs);

  static Future<Storage> open() async =>
      Storage._(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  static String _key(String id) => 'art2_$id';

  Map<String, Artwork> loadAll(List<ColoringPicture> pictures) {
    final result = <String, Artwork>{};
    for (final p in pictures) {
      final text = _prefs.getString(_key(p.id));
      if (text == null) continue;
      try {
        result[p.id] = Artwork.fromJson(
          jsonDecode(text) as Map<String, dynamic>,
          p,
        );
      } catch (_) {
        // Bozuk kayıt: yok say, resim boş açılır.
      }
    }
    return result;
  }

  Future<void> save(String id, Artwork art) =>
      _prefs.setString(_key(id), jsonEncode(art.toJson()));

  Future<void> deleteAll() async {
    for (final key
        in _prefs.getKeys().where((k) => k.startsWith('art')).toList()) {
      await _prefs.remove(key);
    }
  }

  bool get haptics => _prefs.getBool('haptics') ?? true;
  set haptics(bool value) => _prefs.setBool('haptics', value);

  bool get music => _prefs.getBool('music') ?? true;
  set music(bool value) => _prefs.setBool('music', value);

  bool get sounds => _prefs.getBool('sounds') ?? true;
  set sounds(bool value) => _prefs.setBool('sounds', value);
}
