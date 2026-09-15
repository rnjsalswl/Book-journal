class Review {
  final String id;
  final String userId;
  final String bookId;
  final int stars;
  final List<String> moods;
  final String? quote;
  final String text;
  final String scope; // private | group | public
  final String? groupId;
  final int xpAwarded;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.stars,
    required this.moods,
    this.quote,
    required this.text,
    required this.scope,
    this.groupId,
    required this.xpAwarded,
    required this.createdAt,
  });

  factory Review.fromMap(Map<String, dynamic> m) => Review(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        bookId: m['book_id'] as String,
        stars: (m['stars'] as num).toInt(),
        moods: (m['moods'] as List).cast<String>(),
        quote: m['quote'] as String?,
        text: m['text'] as String,
        scope: m['scope'] as String,
        groupId: m['group_id'] as String?,
        xpAwarded: (m['xp_awarded'] as num?)?.toInt() ?? 40,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}
