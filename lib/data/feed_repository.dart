import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/feed_entry.dart';

class FeedRepository {
  final SupabaseClient _client;
  FeedRepository(this._client);

  Future<List<FeedEntry>> forGroup(String groupId, {required String currentUserId}) async {
    final rows = await _client
        .from('feed_entries')
        .select('*, author:profiles!feed_entries_user_id_fkey(display_name), '
            'feed_reactions(user_id)')
        .eq('group_id', groupId)
        .order('created_at', ascending: false);

    return rows.map<FeedEntry>((r) {
      final authorName = (r['author'] as Map?)?['display_name'] as String? ?? '?';
      final reactions = ((r['feed_reactions'] as List?) ?? []).cast<Map>();
      return FeedEntry.fromMap(
        r,
        authorName: authorName,
        reactionCount: reactions.length,
        reactedByMe: reactions.any((x) => x['user_id'] == currentUserId),
      );
    }).toList();
  }

  Future<void> post({
    required String groupId,
    required String userId,
    String? bookId,
    required String kind,
    String? sourceRef,
    required String text,
  }) async {
    await _client.from('feed_entries').insert({
      'group_id': groupId,
      'user_id': userId,
      'book_id': bookId,
      'kind': kind,
      'source_ref': sourceRef,
      'text': text,
    });
  }

  /// Returns true if the reaction was added, false if it was removed.
  Future<bool> toggleReaction(String feedEntryId) async {
    final res = await _client.rpc('toggle_feed_reaction', params: {'p_feed_entry_id': feedEntryId});
    return res as bool;
  }
}
