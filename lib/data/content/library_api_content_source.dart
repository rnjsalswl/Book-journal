import 'book_content_source.dart';

/// Extension point for a real library e-book API — e.g. a public
/// library's licensed e-book platform exposing an authorized,
/// partner-only content endpoint.
///
/// **Not wired to anything today.** No such API exists yet: library
/// e-book vendors (교보 전자도서관, 리브로피아, etc.) are DRM-walled and
/// don't expose third-party content access — that would need a formal
/// B2B agreement between the library and whichever vendor they use. This
/// class exists purely so that *when* that agreement exists, only this
/// one file needs real code — the reader, annotations, and the rest of
/// [BookContentStore]'s fallback chain are already wired to read through
/// [BookContentSource] and don't care where the text came from.
///
/// Expected shape once a real contract exists:
/// 1. The book's catalog row carries an `external_ref` (see
///    `Book.externalRef` / `books.external_ref` in the schema) set when
///    the library's catalog is imported or linked.
/// 2. `fetch` calls the library's content endpoint with that ref —
///    something like `GET $baseUrl/books/{externalRef}/content` — using
///    `apiKey` for auth, and gets back per-chapter HTML or plain text.
/// 3. Each chapter runs through [segmentHtmlToParagraphs] (the same
///    paragraph/sentence split the EPUB importer uses), concatenated in
///    chapter order, and returned — so annotation coordinates behave
///    identically regardless of whether the text came from an uploaded
///    EPUB or this API.
///
/// Until then, `fetch` always returns null, and
/// [CompositeBookContentSource] simply falls through to the next source
/// (the local device cache, then the app's bundled seed text).
class LibraryApiContentSource implements BookContentSource {
  final String? baseUrl;
  final String? apiKey;

  const LibraryApiContentSource({this.baseUrl, this.apiKey});

  @override
  Future<List<List<String>>?> fetch(String bookId) async {
    return null;
  }
}
