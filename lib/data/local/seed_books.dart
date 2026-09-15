/// Book ids (from `supabase/migrations/0002_seed.sql`) that ship with real,
/// freshly-authored body text bundled into the app itself, so anyone can
/// open the librarian's quest book(s) and try underlining/commenting right
/// away — no EPUB upload needed. This works because these texts were
/// written for this app (not scanned/extracted from an existing
/// copyrighted book), so bundling them client-side (and, unlike an
/// uploaded EPUB, they can ship with the app itself) carries no copyright
/// concern.
const Map<String, String> kSeedBookAssets = {
  // 우주보다 작은 것들 — the librarian's SF-shelf quest book
  '00000000-0000-0000-0000-000000000004': 'assets/seed_books/0004.json',
  // 밀물 관찰기 — the librarian's alternate "new arrivals" recommendation
  '00000000-0000-0000-0000-000000000006': 'assets/seed_books/0006.json',
};
