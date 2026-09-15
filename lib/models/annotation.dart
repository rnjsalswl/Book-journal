enum AnnotationType { underline, bubble, postit }

AnnotationType annotationTypeFromString(String s) => switch (s) {
      'underline' => AnnotationType.underline,
      'postit' => AnnotationType.postit,
      _ => AnnotationType.bubble,
    };

String annotationTypeToString(AnnotationType t) => switch (t) {
      AnnotationType.underline => 'underline',
      AnnotationType.bubble => 'bubble',
      AnnotationType.postit => 'postit',
    };

class AnnotationReply {
  final String id;
  final String authorName;
  final String text;

  const AnnotationReply({required this.id, required this.authorName, required this.text});

  factory AnnotationReply.fromMap(Map<String, dynamic> m, {required String authorName}) =>
      AnnotationReply(id: m['id'] as String, authorName: authorName, text: m['text'] as String);
}

/// A mark on one sentence of the reader — underline, speech-bubble comment,
/// or post-it note, matching `state.annos[]` in the prototype.
class BookAnnotation {
  final String id;
  final String bookId;
  final String userId;
  final String authorName;
  final int paragraphIndex;
  final int sentenceIndex;
  final AnnotationType type;
  final String? text;
  final String? emoji;
  final List<AnnotationReply> replies;

  const BookAnnotation({
    required this.id,
    required this.bookId,
    required this.userId,
    required this.authorName,
    required this.paragraphIndex,
    required this.sentenceIndex,
    required this.type,
    this.text,
    this.emoji,
    this.replies = const [],
  });

  factory BookAnnotation.fromMap(Map<String, dynamic> m, {required String authorName}) => BookAnnotation(
        id: m['id'] as String,
        bookId: m['book_id'] as String,
        userId: m['user_id'] as String,
        authorName: authorName,
        paragraphIndex: (m['paragraph_index'] as num).toInt(),
        sentenceIndex: (m['sentence_index'] as num).toInt(),
        type: annotationTypeFromString(m['type'] as String),
        text: m['text'] as String?,
        emoji: m['emoji'] as String?,
      );

  BookAnnotation copyWith({String? emoji, List<AnnotationReply>? replies}) => BookAnnotation(
        id: id,
        bookId: bookId,
        userId: userId,
        authorName: authorName,
        paragraphIndex: paragraphIndex,
        sentenceIndex: sentenceIndex,
        type: type,
        text: text,
        emoji: emoji ?? this.emoji,
        replies: replies ?? this.replies,
      );
}
