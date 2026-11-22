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

  static String _key(String id) => 'art_$id';

  Map<String, Artwork> loadAll(List<ColoringPicture> pictures) {
    final result = <String, Artwork>{};
    for (final p in pictures) {
      final text = _prefs.getString(_key(p.id));
      if (text == null) continue;
      try {
        final art = Artwork.fromJson(jsonDecode(text) as Map<String, dynamic>);
        if (art.fills.length == p.regions.length) result[p.id] = art;
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
        in _prefs.getKeys().where((k) => k.startsWith('art_')).toList()) {
      await _prefs.remove(key);
    }
  }

  bool get haptics => _prefs.getBool('haptics') ?? true;
  set haptics(bool value) => _prefs.setBool('haptics', value);
}
