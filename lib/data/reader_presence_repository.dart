import 'package:supabase_flutter/supabase_flutter.dart';

/// Ephemeral "friend is reading here" presence for one book, via Supabase
/// Realtime Presence (no table — it's not meant to be durable). Matches
/// the prototype's `readingNow`/`presenceHere` — a small avatar row up top
/// and a "민아가 지금 이 부분을 읽고 있어요" line inline in the text.
class ReaderPresenceRepository {
  final SupabaseClient _client;
  ReaderPresenceRepository(this._client);

  RealtimeChannel? _channel;

  /// Joins the presence channel for [bookId] and calls [onChange] with
  /// `{userId: {displayName, paragraphIndex}}` for every other reader
  /// whenever the shared state changes.
  Future<void> join({
    required String bookId,
    required String userId,
    required String displayName,
    required int initialParagraphIndex,
    required void Function(Map<String, ReaderPosition>) onChange,
  }) async {
    await leave();
    final channel = _client.channel(
      'reader:$bookId',
      opts: const RealtimeChannelConfig(self: false),
    );
    _channel = channel;

    void emit() {
      final others = <String, ReaderPosition>{};
      for (final state in channel.presenceState()) {
        for (final p in state.presences) {
          final uid = p.payload['user_id'] as String?;
          if (uid == null || uid == userId) continue;
          others[uid] = ReaderPosition(
            displayName: p.payload['display_name'] as String? ?? '?',
            paragraphIndex: (p.payload['paragraph_index'] as num?)?.toInt() ?? 0,
          );
        }
      }
      onChange(others);
    }

    channel
        .onPresenceSync((_) => emit())
        .onPresenceJoin((_) => emit())
        .onPresenceLeave((_) => emit())
        .subscribe((status, error) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        await channel.track({
          'user_id': userId,
          'display_name': displayName,
          'paragraph_index': initialParagraphIndex,
        });
      }
    });
  }

  Future<void> updatePosition(int paragraphIndex, {required String userId, required String displayName}) async {
    final channel = _channel;
    if (channel == null) return;
    await channel.track({
      'user_id': userId,
      'display_name': displayName,
      'paragraph_index': paragraphIndex,
    });
  }

  Future<void> leave() async {
    final channel = _channel;
    if (channel == null) return;
    await _client.removeChannel(channel);
    _channel = null;
  }
}

class ReaderPosition {
  final String displayName;
  final int paragraphIndex;
  const ReaderPosition({required this.displayName, required this.paragraphIndex});
}
