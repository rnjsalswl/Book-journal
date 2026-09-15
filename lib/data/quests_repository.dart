import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/group.dart';

class QuestsRepository {
  final SupabaseClient _client;
  QuestsRepository(this._client);

  Future<Quest?> activeFor(String userId) async {
    final row = await _client
        .from('quests')
        .select()
        .eq('user_id', userId)
        .eq('status', 'active')
        .order('given_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row == null ? null : Quest.fromMap(row);
  }

  Future<Quest> give({required String userId, required String bookId}) async {
    final row = await _client
        .from('quests')
        .insert({'user_id': userId, 'book_id': bookId})
        .select()
        .single();
    return Quest.fromMap(row);
  }

  Future<void> complete(String questId) async {
    await _client
        .from('quests')
        .update({'status': 'done', 'completed_at': DateTime.now().toIso8601String()})
        .eq('id', questId);
  }
}
