import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';

class ProfileRepository {
  final SupabaseClient _client;
  ProfileRepository(this._client);

  Future<Profile> fetch(String userId) async {
    final row = await _client.from('profiles').select().eq('id', userId).single();
    return Profile.fromMap(row);
  }

  /// Cheap name lookup used to label annotations/feed entries/replies.
  Future<Map<String, String>> namesFor(Iterable<String> userIds) async {
    final ids = userIds.toSet().toList();
    if (ids.isEmpty) return {};
    final rows = await _client.from('profiles').select('id, display_name').inFilter('id', ids);
    return {for (final r in rows) r['id'] as String: r['display_name'] as String};
  }

  Future<void> addXp(String userId, int amount) async {
    await _client.rpc('increment_profile_xp', params: {'p_user_id': userId, 'p_amount': amount});
  }

  Future<void> updateDisplayName(String userId, String name) async {
    await _client.from('profiles').update({'display_name': name}).eq('id', userId);
  }
}
