import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'book_content_source.dart';

/// User-uploaded EPUB text, cached on this device only — never synced to
/// Supabase. EPUB content is typically copyrighted, so it's parsed
/// client-side (see lib/data/epub_parser.dart /
/// lib/data/local/epub_import.dart) and kept here, in this
/// browser/device's local storage, and nowhere else.
class LocalDeviceContentSource implements BookContentSource {
  static String _key(String bookId) => 'book_content_v1:$bookId';

  @override
  Future<List<List<String>>?> fetch(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(bookId));
    if (raw == null) return null;
    return _decode(raw);
  }

  Future<void> save({required String bookId, required List<List<String>> paragraphs}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(bookId), jsonEncode(paragraphs));
  }

  Future<bool> has(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_key(bookId));
  }

  Future<void> remove(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(bookId));
  }

  List<List<String>> _decode(String raw) {
    final decoded = jsonDecode(raw) as List;
    return decoded.map<List<String>>((p) => (p as List).cast<String>()).toList();
  }
}
