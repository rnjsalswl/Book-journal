/// Sample e-book body text (the opening of "모래의 도시", the prototype's
/// demo book), split into paragraphs of sentences so annotations can point
/// at a precise (paragraph, sentence) pair.
///
/// There's no real e-book ingestion pipeline yet — ingesting/paginating
/// actual book text is a separate feature. This placeholder is shown for
/// whichever book is opened so the annotation/review flow has real text to
/// operate on end to end.
const List<List<String>> kReaderParagraphs = [
  [
    '도시의 모든 문은 바깥쪽으로만 열렸다.',
    '그래서 사람들은 집에 들어갈 때마다 잠시 바깥에 서서 기다리는 습관을 갖게 되었다.',
    '나는 그 기다림을 좋아했다.',
  ],
  [
    '여름이면 모래가 창틀에 쌓였고, 어머니는 하루에 두 번 그것을 쓸어냈다.',
    '모래는 치워도 다시 왔다.',
    '어머니는 그것이 도시가 숨 쉬는 방식이라고 말했다.',
  ],
  [
    '열여섯이 되던 해, 나는 처음으로 문을 안쪽으로 당겨보았다.',
    '문은 열리지 않았고 손잡이만 떨어졌다.',
    '그날 이후 나는 기다리는 일을 다르게 생각하게 되었다.',
  ],
];

class ReaderContent {
  static int flatIndex(int paragraphIndex, int sentenceIndex) {
    var base = 0;
    for (var i = 0; i < paragraphIndex; i++) {
      base += kReaderParagraphs[i].length;
    }
    return base + sentenceIndex;
  }

  static (int paragraphIndex, int sentenceIndex) fromFlat(int flat) {
    var remaining = flat;
    for (var pi = 0; pi < kReaderParagraphs.length; pi++) {
      final len = kReaderParagraphs[pi].length;
      if (remaining < len) return (pi, remaining);
      remaining -= len;
    }
    return (kReaderParagraphs.length - 1, kReaderParagraphs.last.length - 1);
  }

  static String textAt(int paragraphIndex, int sentenceIndex) =>
      kReaderParagraphs[paragraphIndex][sentenceIndex];
}
