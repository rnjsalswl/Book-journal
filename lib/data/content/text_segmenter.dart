import 'package:html/parser.dart' as html_parser;

/// Splits an HTML/XHTML fragment into paragraphs of sentences. Shared by
/// every [BookContentSource] that has to turn raw markup into the
/// paragraphs-of-sentences shape annotations' `(paragraph_index,
/// sentence_index)` coordinates point into — today that's just the EPUB
/// importer, but a future library e-book API source would reuse this too,
/// so text from either origin segments identically.
List<List<String>> segmentHtmlToParagraphs(String html) {
  final doc = html_parser.parse(html);
  final blocks = doc.querySelectorAll('p, h1, h2, h3, h4, li, blockquote');
  final source = blocks.isNotEmpty ? blocks : [doc.body ?? doc.documentElement!];

  final paragraphs = <List<String>>[];
  for (final block in source) {
    final text = block.text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty) continue;
    final sentences = splitSentences(text);
    if (sentences.isNotEmpty) paragraphs.add(sentences);
  }
  return paragraphs;
}

final _sentenceEnd = RegExp(r'(?<=[.!?…。！？])\s+');

/// Splits one paragraph of plain text into sentences (Korean/English
/// enders `. ! ?` kept attached to the sentence they close).
List<String> splitSentences(String paragraph) {
  return paragraph
      .split(_sentenceEnd)
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}
