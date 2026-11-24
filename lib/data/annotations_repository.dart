import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/annotation.dart';

class AnnotationsRepository {
  final SupabaseClient _client;
  AnnotationsRepository(this._client);

  /// All annotations + reply threads visible to the caller for a book
  /// (own annotations, plus any from people they share a reading group
  /// with — enforced server-side by RLS, see supabase/migrations).
  Future<List<BookAnnotation>> forBook(String bookId) async {
    final rows = await _client
        .from('annotations')
        .select('*, author:profiles!annotations_user_id_fkey(display_name), '
            'annotation_replies(id, text, author:profiles!annotation_replies_user_id_fkey(display_name))')
        .eq('book_id', bookId)
        .order('created_at');

    return rows.map<BookAnnotation>((r) {
      final authorName = (r['author'] as Map?)?['display_name'] as String? ?? '?';
      final replies = ((r['annotation_replies'] as List?) ?? [])
          .map((rep) => AnnotationReply.fromMap(
                rep as Map<String, dynamic>,
                authorName: (rep['author'] as Map?)?['display_name'] as String? ?? '?',
              ))
          .toList();
      return BookAnnotation.fromMap(r, authorName: authorName).copyWith(replies: replies);
    }).toList();
  }

  Future<String> create({
    required String userId,
    required String bookId,
    required int paragraphIndex,
    required int sentenceIndex,
    required AnnotationType type,
    String? text,
  }) async {
    final row = await _client
        .from('annotations')
        .insert({
          'user_id': userId,
          'book_id': bookId,
          'paragraph_index': paragraphIndex,
          'sentence_index': sentenceIndex,
          'type': annotationTypeToString(type),
          'text': text,
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  /// Atomically toggles the underline at this position. Returns true if the
  /// sentence is now underlined, false if the underline was removed.
  /// Done server-side (via `toggle_underline` RPC) so rapid taps can't race
  /// a client-side read-then-write and leave duplicate rows.
  Future<bool> toggleUnderline({
    required String bookId,
    required int paragraphIndex,
    required int sentenceIndex,
  }) async {
    final result = await _client.rpc('toggle_underline', params: {
      'p_book_id': bookId,
      'p_paragraph_index': paragraphIndex,
      'p_sentence_index': sentenceIndex,
    });
    return result as bool;
  }

  Future<void> setEmoji({required String annotationId, required String emoji}) async {
    await _client.from('annotations').update({'emoji': emoji}).eq('id', annotationId);
  }

  Future<void> reply({
    required String annotationId,
    required String userId,
    required String text,
  }) async {
    await _client.from('annotation_replies').insert({
      'annotation_id': annotationId,
      'user_id': userId,
      'text': text,
    });
  }
}
