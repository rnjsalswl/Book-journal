import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/badge_progress.dart';

class BadgesRepository {
  final SupabaseClient _client;
  BadgesRepository(this._client);

  Future<List<BadgeProgress>> forUser(String userId) async {
    final rows = await _client
        .from('badges')
        .select('id, key, name, description, color, goal, user_badges(progress, unlocked_at)')
        .order('goal');

    return rows.map<BadgeProgress>((r) {
      // RLS on user_badges already restricts this embed to the caller's own
      // progress row, so at most one entry comes back per badge.
      final mine = ((r['user_badges'] as List?) ?? []).cast<Map<String, dynamic>>();
      final progress = mine.isNotEmpty ? (mine.first['progress'] as num).toInt() : 0;
      final unlockedAt =
          mine.isNotEmpty && mine.first['unlocked_at'] != null ? DateTime.parse(mine.first['unlocked_at'] as String) : null;
      return BadgeProgress(
        badgeId: r['id'] as String,
        key: r['key'] as String,
        name: r['name'] as String,
        description: r['description'] as String,
        colorHex: _hexToArgb(r['color'] as String),
        goal: (r['goal'] as num).toInt(),
        progress: progress,
        unlockedAt: unlockedAt,
      );
    }).toList();
  }

  Future<void> bump(String badgeKey, {int delta = 1}) async {
    await _client.rpc('bump_badge_progress', params: {'p_badge_key': badgeKey, 'p_delta': delta});
  }

  int _hexToArgb(String hex) => int.parse('FF${hex.replaceFirst('#', '')}', radix: 16);
}
