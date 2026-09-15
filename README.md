# 픽셀 책방 일지 (Pixel Book Journal)

A Flutter implementation of the `Pixel Book Journal.dc.html` Claude Design
prototype (see `../README.md`, `../chats/chat1.md`, `../project/` for the
original handoff bundle): a Stardew-Valley-style pixel library you walk
around, a librarian NPC who hands out reading quests, a bookshelf/e-book
reader where you underline sentences and leave speech-bubble comments or
post-it notes with friends, a small-group "Wednesday's Desk" exchange
diary, and a profile with a reading-streak heatmap and achievements.

The prototype was a self-contained HTML/JS mock with in-memory fake data.
This is the real thing — a Flutter app backed by Supabase (Postgres +
Auth + Realtime).

## Stack

- **Flutter** (Dart) — targets Android, iOS, and web
- **Supabase** — Postgres database, Auth, and Realtime Presence (for the
  "friend is reading here" indicator in the e-book reader)
- **flutter_riverpod** — state management (plain `Provider`/`FutureProvider`
  reads from Supabase, repository calls + `ref.invalidate` for writes)

## One-time Supabase setup

1. Create a project at [supabase.com](https://supabase.com).
2. In the SQL editor, run the migrations in `supabase/migrations/` **in
   order**:
   - `0001_init.sql` — tables, RLS policies, the `handle_new_user` trigger
   - `0002_seed.sql` — demo book catalog + achievement definitions
   - `0003_functions.sql` — RPCs for XP/leveling, reactions, badge progress,
     reading-log increments
3. Under Project Settings → API, copy the **Project URL** and the
   **anon/publishable key**.
4. (Optional but recommended) Under Authentication → Providers, turn off
   "Confirm email" while developing so `signUp` logs you straight in.

## Running the app

```bash
flutter pub get

flutter run \
  --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR-ANON-KEY
```

Without those two `--dart-define`s the app boots to a "Supabase 설정이
필요해요" screen instead of trying (and failing) to reach a backend.

For web:

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

### Trying it without your own book club

The map, shelf, and reader all work solo — quests, annotations, and
reviews only need your own account. The exchange-diary tab (교환일기) will
show "아직 참여한 교환일기 모임이 없어요" with a button to create a
group (수요일의 책상) for yourself; invite other accounts by having them
sign up and adding their `profiles.id` to `group_members`, or extend the
feed screen with a proper invite-by-email flow.

## Project layout

```
lib/
  core/            Supabase client bootstrap, --dart-define reading
  models/          Plain Dart data classes (Book, Profile, BookAnnotation, …)
  data/            Repositories — one per table/feature, wrap SupabaseClient
  state/           Riverpod providers (repositories, reads, small UI state)
  theme/           Palette, text style, and "hard border + offset shadow"
                   decoration helpers ported 1:1 from the prototype's CSS
  widgets/         Shared pixel-styled widgets (PixelButton, PixelCard, …)
  screens/
    map_screen.dart       서관 — side-scrolling library map (CustomPainter)
    map/                  game loop, canvas painter, sprites, station data,
                           librarian dialogue + browse/book-detail sheets
    shelf_screen.dart     내 서재 — tabs + book grid
    add_book_screen.dart  책 올리기 — pick an EPUB, parse it, add to the catalog
    reader_screen.dart    e-book 리더 — annotations, replies, presence
    reader/                fallback sample text if a book has no local content
    review_screen.dart    감상문 작성
    feed_screen.dart      교환일기 — Wednesday's Desk group feed
    profile_screen.dart   나 — stats, heatmap, achievements
    auth_screen.dart      sign in / sign up (not in the original prototype —
                           added because a real backend needs an account)
    app_shell.dart         bottom-nav shell wrapping the four tabs
supabase/
  migrations/      SQL to run against a fresh Supabase project
```

## E-book text: local-only, by design

EPUB files are usually copyrighted, so their body text is never uploaded
to Supabase. From **내 서재 → +** (or the reader's "EPUB 연결하기" empty
state for a book someone else added), `lib/data/epub_parser.dart` unzips
and parses the `.epub` entirely on-device, and
`lib/data/local/book_content_store.dart` caches the resulting paragraphs
in that browser/device's local storage (`shared_preferences`) under the
book's id — nothing else about the text ever leaves the device.

What *does* sync through Supabase is just:
- the book's **title/author/category** (catalog metadata, `books` table)
- every underline/comment/post-it's **(paragraph_index, sentence_index)
  coordinate** (`annotations` table) — never the sentence text itself

So two people only see each other's annotations lined up correctly once
they've each imported the same edition of the book onto their own
device — the server is coordinating positions, not hosting content.

## What's a placeholder vs. real

- **Pixel sprites**: still code-drawn (`screens/map/pixel_sprites.dart`),
  same as the prototype — swap in real spritesheets by replacing the
  `drawPixelSprite` calls with `Image`/`SpriteSheet` rendering.
- **Everything else** (auth, profiles, shelf/reading progress, EPUB import,
  annotations + replies, the exchange-diary feed + reactions, reviews,
  XP/leveling, badges, reading-log heatmap, quests, friend
  reading-presence) is wired to real Supabase tables/RPCs (metadata and
  coordinates only, per above) — see `supabase/migrations/`.

## Verification done so far

- `flutter analyze` — clean
- `flutter test` — widget test (unconfigured-state screen) + golden
  renders of the auth, review, and map-canvas screens (`test/visual_check_test.dart`,
  PNGs under `test/goldens/`) to confirm the pixel styling actually renders
  as intended
- `flutter build web` — full compile check

Not done: a live end-to-end pass against a real Supabase project (signing
up, walking the map, leaving annotations, posting to the feed) — that
needs your own project's URL/key from the setup steps above.
