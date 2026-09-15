class FeedEntry {
  final String id;
  final String groupId;
  final String userId;
  final String authorName;
  final String? bookId;
  final String kind; // 밑줄 | 말풍선 | 포스트잇 | 한 줄
  final String? sourceRef;
  final String text;
  final DateTime createdAt;
  final int reactionCount;
  final bool reactedByMe;

  const FeedEntry({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.authorName,
    this.bookId,
    required this.kind,
    this.sourceRef,
    required this.text,
    required this.createdAt,
    this.reactionCount = 0,
    this.reactedByMe = false,
  });

  factory FeedEntry.fromMap(
    Map<String, dynamic> m, {
    required String authorName,
    int reactionCount = 0,
    bool reactedByMe = false,
  }) =>
      FeedEntry(
        id: m['id'] as String,
        groupId: m['group_id'] as String,
        userId: m['user_id'] as String,
        authorName: authorName,
        bookId: m['book_id'] as String?,
        kind: m['kind'] as String,
        sourceRef: m['source_ref'] as String?,
        text: m['text'] as String,
        createdAt: DateTime.parse(m['created_at'] as String),
        reactionCount: reactionCount,
        reactedByMe: reactedByMe,
      );

  FeedEntry copyWith({int? reactionCount, bool? reactedByMe}) => FeedEntry(
        id: id,
        groupId: groupId,
        userId: userId,
        authorName: authorName,
        bookId: bookId,
        kind: kind,
        sourceRef: sourceRef,
        text: text,
        createdAt: createdAt,
        reactionCount: reactionCount ?? this.reactionCount,
        reactedByMe: reactedByMe ?? this.reactedByMe,
      );

  String whenLabel() {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return '방금';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 2) return '어제';
    return '${diff.inDays}일 전';
  }
}

class GroupMember {
  final String userId;
  final String displayName;

  const GroupMember({required this.userId, required this.displayName});
}
