import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/review.dart';

class ReviewsRepository {
  final SupabaseClient _client;
  ReviewsRepository(this._client);

  Future<Review> create({
    required String userId,
    required String bookId,
    required int stars,
    required List<String> moods,
    String? quote,
    required String text,
    required String scope, // private | group | public
    String? groupId,
    int xpAwarded = 40,
  }) async {
    final row = await _client
        .from('reviews')
        .insert({
          'user_id': userId,
          'book_id': bookId,
          'stars': stars,
          'moods': moods,
          'quote': quote,
          'text': text,
          'scope': scope,
          'group_id': groupId,
          'xp_awarded': xpAwarded,
        })
        .select()
        .single();
    return Review.fromMap(row);
  }

  Future<int> countForUser(String userId) async {
    final rows = await _client.from('reviews').select('id').eq('user_id', userId);
    return rows.length;
  }
}
