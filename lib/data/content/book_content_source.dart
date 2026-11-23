/// A place a book's body text (paragraphs of sentences) can come from.
/// `fetch` returns null to mean "this source doesn't have this book" —
/// not an error — so [CompositeBookContentSource] can fall through to the
/// next source in line.
abstract class BookContentSource {
  Future<List<List<String>>?> fetch(String bookId);
}
