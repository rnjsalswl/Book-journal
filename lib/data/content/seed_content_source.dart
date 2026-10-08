import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../local/seed_books.dart';
import 'book_content_source.dart';

/// Body text bundled into the app itself — freshly written for this app
/// (not extracted from an existing copyrighted book), so shipping it
/// carries no copyright concern. See lib/data/local/seed_books.dart for
/// which book ids have an asset.
class SeedContentSource implements BookContentSource {
  @override
  Future<List<List<String>>?> fetch(String bookId) async {
    final assetPath = kSeedBookAssets[bookId];
    if (assetPath == null) return null;
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw) as List;
    return decoded.map<List<String>>((p) => (p as List).cast<String>()).toList();
  }
}
