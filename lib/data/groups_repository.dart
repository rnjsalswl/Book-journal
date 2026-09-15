import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/group.dart';
import '../models/feed_entry.dart';

class GroupsRepository {
  final SupabaseClient _client;
  GroupsRepository(this._client);

  /// The "수요일의 책상" style group the current user belongs to. The
  /// prototype assumes exactly one small group (3-6 people); a user can
  /// join more than one in the schema, but the UI surfaces the first.
  Future<ReadingGroup?> myGroup(String userId) async {
    final membership = await _client
        .from('group_members')
        .select('group_id, groups(id, name, current_book_id)')
        .eq('user_id', userId)
        .limit(1)
        .maybeSingle();
    if (membership == null) return null;
    final g = membership['groups'] as Map<String, dynamic>;
    final memberIds = await _memberIds(g['id'] as String);
    return ReadingGroup.fromMap(g, memberIds: memberIds);
  }

  Future<List<GroupMember>> members(String groupId) async {
    final rows = await _client
        .from('group_members')
        .select('user_id, profiles(display_name)')
        .eq('group_id', groupId);
    return rows
        .map<GroupMember>((r) => GroupMember(
              userId: r['user_id'] as String,
              displayName: (r['profiles'] as Map?)?['display_name'] as String? ?? '?',
            ))
        .toList();
  }

  Future<ReadingGroup> create({
    required String name,
    required String createdBy,
    String? currentBookId,
  }) async {
    final row = await _client
        .from('groups')
        .insert({'name': name, 'created_by': createdBy, 'current_book_id': currentBookId})
        .select()
        .single();
    await _client.from('group_members').insert({'group_id': row['id'], 'user_id': createdBy});
    return ReadingGroup.fromMap(row, memberIds: [createdBy]);
  }

  Future<void> invite({required String groupId, required String userId}) async {
    await _client.from('group_members').insert({'group_id': groupId, 'user_id': userId});
  }

  Future<List<String>> _memberIds(String groupId) async {
    final rows = await _client.from('group_members').select('user_id').eq('group_id', groupId);
    return rows.map<String>((r) => r['user_id'] as String).toList();
  }
}
