import '../content/book_content_source.dart';
import '../content/composite_content_source.dart';
import '../content/library_api_content_source.dart';
import '../content/local_content_source.dart';
import '../content/seed_content_source.dart';

/// Facade over everywhere a book's body text can come from. Reads try, in
/// order: this device's local cache (user-uploaded EPUBs) → a future
/// library e-book API (see [LibraryApiContentSource] — not wired to
/// anything real yet) → the app's bundled demo texts. Writes always go to
/// the local cache; see each source's doc comment for why.
class BookContentStore implements BookContentSource {
  final LocalDeviceContentSource _local = LocalDeviceContentSource();
  late final CompositeBookContentSource _composite = CompositeBookContentSource([
    _local,
    const LibraryApiContentSource(),
    SeedContentSource(),
  ]);

  @override
  Future<List<List<String>>?> fetch(String bookId) => _composite.fetch(bookId);

  Future<void> save({required String bookId, required List<List<String>> paragraphs}) =>
      _local.save(bookId: bookId, paragraphs: paragraphs);

  Future<bool> has(String bookId) async => await fetch(bookId) != null;

  Future<void> remove(String bookId) => _local.remove(bookId);
}
