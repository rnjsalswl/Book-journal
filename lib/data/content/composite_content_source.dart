import 'book_content_source.dart';

/// Tries each source in order and returns the first hit. Order encodes
/// priority: a user's own local copy wins over a (future) library API's,
/// which wins over the app's bundled demo text.
class CompositeBookContentSource implements BookContentSource {
  final List<BookContentSource> sources;
  const CompositeBookContentSource(this.sources);

  @override
  Future<List<List<String>>?> fetch(String bookId) async {
    for (final source in sources) {
      final result = await source.fetch(bookId);
      if (result != null) return result;
    }
    return null;
  }
}
