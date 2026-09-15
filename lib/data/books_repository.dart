import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/book.dart';

class BooksRepository {
  final SupabaseClient _client;
  BooksRepository(this._client);

  Future<List<Book>> all() async {
    final rows = await _client.from('books').select().order('created_at');
    return rows.map<Book>((r) => Book.fromMap(r)).toList();
  }

  Future<Book> byId(String id) async {
    final row = await _client.from('books').select().eq('id', id).single();
    return Book.fromMap(row);
  }

  Future<List<Book>> byCategory(String category) async {
    final rows = await _client.from('books').select().eq('category', category);
    return rows.map<Book>((r) => Book.fromMap(r)).toList();
  }

  /// Adds a book to the shared catalog (title/author/category only — never
  /// the book's body text, see lib/data/local/book_content_store.dart).
  Future<Book> create({
    required String title,
    required String author,
    required String category,
    required String colorHex,
    required int totalPages,
  }) async {
    final row = await _client
        .from('books')
        .insert({
          'title': title,
          'author': author,
          'category': category,
          'color': colorHex,
          'total_pages': totalPages,
        })
        .select()
        .single();
    return Book.fromMap(row);
  }
}

class ShelfRepository {
  final SupabaseClient _client;
  ShelfRepository(this._client);

  /// Own shelf entries, joined with the book row (mirrors `mkBook` in the
  /// prototype, which merged BOOKS with per-user reading state).
  Future<List<ShelfEntry>> forUser(String userId) async {
    final rows = await _client
        .from('shelf_entries')
        .select('*, books(*)')
        .eq('user_id', userId)
        .order('updated_at', ascending: false);
    return rows.map<ShelfEntry>((r) => _fromJoinedRow(r)).toList();
  }

  Future<ShelfEntry?> forBook(String userId, String bookId) async {
    final row = await _client
        .from('shelf_entries')
        .select('*, books(*)')
        .eq('user_id', userId)
        .eq('book_id', bookId)
        .maybeSingle();
    return row == null ? null : _fromJoinedRow(row);
  }

  Future<void> upsertProgress({
    required String userId,
    required String bookId,
    required int currentPage,
    required int totalPages,
    String status = 'reading',
    String? sharedGroupId,
  }) async {
    await _client.from('shelf_entries').upsert({
      'user_id': userId,
      'book_id': bookId,
      'status': status,
      'current_page': currentPage,
      'pct': totalPages == 0 ? 0 : ((currentPage / totalPages) * 100).round(),
      'shared_group_id': sharedGroupId,
      'started_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,book_id');
  }

  Future<void> markDone({required String userId, required String bookId}) async {
    await _client.from('shelf_entries').update({
      'status': 'done',
      'pct': 100,
      'finished_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('user_id', userId).eq('book_id', bookId);
  }

  ShelfEntry _fromJoinedRow(Map<String, dynamic> r) {
    final book = Book.fromMap(r['books'] as Map<String, dynamic>);
    return ShelfEntry(
      id: r['id'] as String,
      book: book,
      status: r['status'] as String,
      currentPage: (r['current_page'] as num?)?.toInt() ?? 0,
      pct: (r['pct'] as num?)?.toInt() ?? 0,
      sharedGroupId: r['shared_group_id'] as String?,
    );
  }
}
