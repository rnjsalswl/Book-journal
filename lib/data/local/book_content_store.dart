import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import 'seed_books.dart';

/// On-device-only cache of a book's body text (paragraphs of sentences).
///
/// EPUB text is usually copyrighted, so it's parsed client-side and kept
/// here — in this browser/device's local storage — and never uploaded to
/// Supabase. What *does* sync through the backend is just the
/// `(paragraph_index, sentence_index)` "coordinates" annotations point
/// at (see `AnnotationsRepository`) — never the sentence text itself. Two
/// people only see each other's underlines lined up correctly if they've
/// each imported the same edition of the book onto their own device.
class BookContentStore {
  static String _key(String bookId) => 'book_content_v1:$bookId';

  Future<List<List<String>>?> fetch(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(bookId));
    if (raw != null) return _decode(raw);

    final assetPath = kSeedBookAssets[bookId];
    if (assetPath == null) return null;
    final bundled = await rootBundle.loadString(assetPath);
    return _decode(bundled);
  }

  List<List<String>> _decode(String raw) {
    final decoded = jsonDecode(raw) as List;
    return decoded.map<List<String>>((p) => (p as List).cast<String>()).toList();
  }

  Future<void> save({required String bookId, required List<List<String>> paragraphs}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(bookId), jsonEncode(paragraphs));
  }

  Future<bool> has(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_key(bookId)) || kSeedBookAssets.containsKey(bookId);
  }

  Future<void> remove(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(bookId));
  }
}
