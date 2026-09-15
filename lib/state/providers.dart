import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_init.dart';
import '../data/annotations_repository.dart';
import '../data/auth_repository.dart';
import '../data/badges_repository.dart';
import '../data/books_repository.dart';
import '../data/feed_repository.dart';
import '../data/groups_repository.dart';
import '../data/profile_repository.dart';
import '../data/reader_presence_repository.dart';
import '../data/reading_log_repository.dart';
import '../data/reviews_repository.dart';
import '../data/quests_repository.dart';
import '../models/annotation.dart';
import '../models/badge_progress.dart';
import '../models/book.dart';
import '../models/feed_entry.dart';
import '../models/group.dart';
import '../models/profile.dart';

// ---------------------------------------------------------------------------
// Repositories
// ---------------------------------------------------------------------------

final supabaseClientProvider = Provider<SupabaseClient>((ref) => supabase);

final authRepositoryProvider =
    Provider((ref) => AuthRepository(ref.watch(supabaseClientProvider)));
final profileRepositoryProvider =
    Provider((ref) => ProfileRepository(ref.watch(supabaseClientProvider)));
final booksRepositoryProvider =
    Provider((ref) => BooksRepository(ref.watch(supabaseClientProvider)));
final shelfRepositoryProvider =
    Provider((ref) => ShelfRepository(ref.watch(supabaseClientProvider)));
final annotationsRepositoryProvider =
    Provider((ref) => AnnotationsRepository(ref.watch(supabaseClientProvider)));
final feedRepositoryProvider =
    Provider((ref) => FeedRepository(ref.watch(supabaseClientProvider)));
final reviewsRepositoryProvider =
    Provider((ref) => ReviewsRepository(ref.watch(supabaseClientProvider)));
final badgesRepositoryProvider =
    Provider((ref) => BadgesRepository(ref.watch(supabaseClientProvider)));
final groupsRepositoryProvider =
    Provider((ref) => GroupsRepository(ref.watch(supabaseClientProvider)));
final readingLogRepositoryProvider =
    Provider((ref) => ReadingLogRepository(ref.watch(supabaseClientProvider)));
final questsRepositoryProvider =
    Provider((ref) => QuestsRepository(ref.watch(supabaseClientProvider)));
final readerPresenceRepositoryProvider =
    Provider((ref) => ReaderPresenceRepository(ref.watch(supabaseClientProvider)));

// ---------------------------------------------------------------------------
// Auth
// ---------------------------------------------------------------------------

final authStateChangesProvider = StreamProvider<AuthState>(
  (ref) => ref.watch(authRepositoryProvider).onAuthStateChange,
);

/// Null while signed out. Screens below the app shell can assume non-null.
final currentUserIdProvider = Provider<String?>((ref) {
  final change = ref.watch(authStateChangesProvider).value;
  return change?.session?.user.id ?? ref.watch(authRepositoryProvider).currentUser?.id;
});

// ---------------------------------------------------------------------------
// Reads (FutureProvider — call `ref.invalidate(xProvider)` after a mutation
// through the matching repository to refetch).
// ---------------------------------------------------------------------------

final profileProvider = FutureProvider.family<Profile, String>(
  (ref, userId) => ref.watch(profileRepositoryProvider).fetch(userId),
);

final booksProvider = FutureProvider<List<Book>>(
  (ref) => ref.watch(booksRepositoryProvider).all(),
);

final shelfEntriesProvider = FutureProvider.family<List<ShelfEntry>, String>(
  (ref, userId) => ref.watch(shelfRepositoryProvider).forUser(userId),
);

final myGroupProvider = FutureProvider.family<ReadingGroup?, String>(
  (ref, userId) => ref.watch(groupsRepositoryProvider).myGroup(userId),
);

final groupMembersProvider = FutureProvider.family<List<GroupMember>, String>(
  (ref, groupId) => ref.watch(groupsRepositoryProvider).members(groupId),
);

final feedProvider = FutureProvider.family<List<FeedEntry>, ({String groupId, String userId})>(
  (ref, args) => ref.watch(feedRepositoryProvider).forGroup(args.groupId, currentUserId: args.userId),
);

final annotationsProvider = FutureProvider.family<List<BookAnnotation>, String>(
  (ref, bookId) => ref.watch(annotationsRepositoryProvider).forBook(bookId),
);

final badgesProvider = FutureProvider.family<List<BadgeProgress>, String>(
  (ref, userId) => ref.watch(badgesRepositoryProvider).forUser(userId),
);

final heatDaysProvider = FutureProvider.family<List<HeatDay>, String>(
  (ref, userId) => ref.watch(readingLogRepositoryProvider).recent(userId),
);

final activeQuestProvider = FutureProvider.family<Quest?, String>(
  (ref, userId) => ref.watch(questsRepositoryProvider).activeFor(userId),
);

final reviewCountProvider = FutureProvider.family<int, String>(
  (ref, userId) => ref.watch(reviewsRepositoryProvider).countForUser(userId),
);
