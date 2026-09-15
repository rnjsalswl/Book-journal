class ReadingGroup {
  final String id;
  final String name;
  final String? currentBookId;
  final List<String> memberIds;

  const ReadingGroup({
    required this.id,
    required this.name,
    this.currentBookId,
    this.memberIds = const [],
  });

  factory ReadingGroup.fromMap(Map<String, dynamic> m, {List<String> memberIds = const []}) =>
      ReadingGroup(
        id: m['id'] as String,
        name: m['name'] as String,
        currentBookId: m['current_book_id'] as String?,
        memberIds: memberIds,
      );
}

class Quest {
  final String id;
  final String? bookId;
  final String status; // active | done

  const Quest({required this.id, this.bookId, required this.status});

  factory Quest.fromMap(Map<String, dynamic> m) => Quest(
        id: m['id'] as String,
        bookId: m['book_id'] as String?,
        status: m['status'] as String,
      );
}
