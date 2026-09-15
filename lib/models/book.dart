import 'package:flutter/painting.dart';

/// Maps a book's `category` string to the station id in the library map
/// (`STATIONS[].id` in the prototype) that browses it.
const Map<String, String> kCategoryStationId = {
  'new': 'new',
  'novel': 'novel',
  'essay': 'essay',
  'sf': 'sf',
  'poem': 'poem',
};

class Book {
  final String id;
  final String title;
  final String author;
  final String category;
  final Color color;
  final int totalPages;

  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.color,
    required this.totalPages,
  });

  factory Book.fromMap(Map<String, dynamic> m) => Book(
        id: m['id'] as String,
        title: m['title'] as String,
        author: m['author'] as String,
        category: m['category'] as String,
        color: _parseHex(m['color'] as String? ?? '#8c491a'),
        totalPages: (m['total_pages'] as num?)?.toInt() ?? 200,
      );

  static Color _parseHex(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}

/// Per-user reading state for a [Book] — mirrors the `shelf_entries` table
/// and the `BOOKS[].pct/meta/tag` fields the prototype derived in-memory.
class ShelfEntry {
  final String id;
  final Book book;
  final String status; // new | reading | done
  final int currentPage;
  final int pct;
  final String? sharedGroupId;

  const ShelfEntry({
    required this.id,
    required this.book,
    required this.status,
    required this.currentPage,
    required this.pct,
    this.sharedGroupId,
  });

  String get metaLabel {
    if (status == 'done') return '다 읽음';
    if (status == 'new') return '신간 · $currentPage/${book.totalPages}쪽';
    final shared = sharedGroupId != null ? ' · 함께' : '';
    return '$currentPage/${book.totalPages}쪽$shared';
  }

  String get tagLabel {
    if (status == 'done') return '감상문';
    if (sharedGroupId != null) return '함께';
    if (status == 'new') return '신간';
    return '읽는 중';
  }
}
