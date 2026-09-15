-- Lets authenticated users add new books to the shared catalog (needed for
-- the EPUB-import flow: adding a book creates a `books` row for its
-- title/author/category — metadata only, not the book's actual text).
--
-- The book's body text is deliberately NOT stored here or anywhere on the
-- server: EPUB content is typically copyrighted, so it's parsed and kept
-- client-side only (see lib/data/local/book_content_store.dart). Only the
-- (paragraph_index, sentence_index) "coordinates" of underlines/comments
-- are synced through the `annotations` table — never the sentence text
-- itself — so annotations line up correctly on any device that has
-- imported the same edition, without the server ever holding the text.

create policy "authenticated users can add books"
  on public.books for insert
  with check (auth.role() = 'authenticated');
