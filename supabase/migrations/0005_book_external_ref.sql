-- Prepares `books` to be linkable to an external catalog (e.g. a future
-- library e-book API partnership) without any functional change today —
-- see lib/data/content/library_api_content_source.dart for the intended
-- use. Every existing/seeded book keeps external_ref = null and behaves
-- exactly as before (local EPUB import / bundled seed text).

alter table public.books
  add column external_ref text;

comment on column public.books.external_ref is
  'This book''s id in an external catalog (e.g. a library e-book system), if imported/linked from one. Null for seed-catalog and user-EPUB-imported books.';
