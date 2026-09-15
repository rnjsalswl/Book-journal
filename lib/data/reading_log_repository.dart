import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/badge_progress.dart';

class ReadingLogRepository {
  final SupabaseClient _client;
  ReadingLogRepository(this._client);

  /// Last [days] days of reading minutes for the profile heatmap.
  Future<List<HeatDay>> recent(String userId, {int days = 30}) async {
    final since = DateTime.now().subtract(Duration(days: days - 1));
    final rows = await _client
        .from('reading_log')
        .select('day, minutes')
        .eq('user_id', userId)
        .gte('day', since.toIso8601String().split('T').first)
        .order('day');

    final byDay = {
      for (final r in rows) DateTime.parse(r['day'] as String): (r['minutes'] as num).toInt(),
    };
    return List.generate(days, (i) {
      final day = since.add(Duration(days: i));
      final key = DateTime(day.year, day.month, day.day);
      return HeatDay(day: key, minutes: byDay[key] ?? 0);
    });
  }

  Future<void> logMinutes(String userId, {int minutes = 1}) async {
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day).toIso8601String().split('T').first;
    await _client.rpc('increment_reading_minutes', params: {
      'p_user_id': userId,
      'p_day': day,
      'p_minutes': minutes,
    });
  }
}
