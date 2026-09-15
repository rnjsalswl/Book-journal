import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:xml/xml.dart';

class ParsedEpub {
  final String title;
  final String author;
  final List<List<String>> paragraphs;

  const ParsedEpub({required this.title, required this.author, required this.paragraphs});
}

/// A minimal, dependency-light EPUB2/EPUB3 reader: enough to pull a title,
/// an author, and the book's plain-text body (as paragraphs of sentences,
/// the same shape the reader annotates by paragraph/sentence index) out of
/// a real .epub file. It does not render layout, images, or styling —
/// just the text, which is all the reader needs.
class EpubParser {
  static ParsedEpub parse(List<int> bytes, {String fallbackTitle = '제목 없는 책'}) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final filesByPath = <String, ArchiveFile>{
      for (final f in archive.files.where((f) => f.isFile)) f.name: f,
    };

    final opfPath = _findOpfPath(filesByPath);
    final opfDoc = XmlDocument.parse(_readText(filesByPath[opfPath]!));
    final opfDir = opfPath.contains('/') ? opfPath.substring(0, opfPath.lastIndexOf('/') + 1) : '';

    final title = _firstText(opfDoc, 'title') ?? fallbackTitle;
    final author = _firstText(opfDoc, 'creator') ?? '작자 미상';

    // manifest: id -> href
    final manifest = <String, String>{};
    for (final item in opfDoc.findAllElements('item')) {
      final id = item.getAttribute('id');
      final href = item.getAttribute('href');
      if (id != null && href != null) manifest[id] = href;
    }

    // spine: reading order of manifest ids
    final spineIds = opfDoc
        .findAllElements('spine')
        .expand((s) => s.findElements('itemref'))
        .map((e) => e.getAttribute('idref'))
        .whereType<String>()
        .toList();

    final paragraphs = <List<String>>[];
    for (final id in spineIds) {
      final href = manifest[id];
      if (href == null) continue;
      final path = _resolve(opfDir, href);
      final file = filesByPath[path];
      if (file == null) continue;
      paragraphs.addAll(_extractParagraphs(_readText(file)));
    }

    return ParsedEpub(title: title.trim(), author: author.trim(), paragraphs: paragraphs);
  }

  static String _findOpfPath(Map<String, ArchiveFile> files) {
    final container = files['META-INF/container.xml'];
    if (container != null) {
      final doc = XmlDocument.parse(_readText(container));
      final rootfiles = doc.findAllElements('rootfile');
      if (rootfiles.isNotEmpty) {
        final path = rootfiles.first.getAttribute('full-path');
        if (path != null) return path;
      }
    }
    // fall back to scanning for any .opf file
    final opf = files.keys.firstWhere((k) => k.toLowerCase().endsWith('.opf'), orElse: () => '');
    if (opf.isEmpty) throw const FormatException('EPUB에서 콘텐츠 목록(.opf)을 찾지 못했어요');
    return opf;
  }

  static String? _firstText(XmlDocument doc, String localName) {
    for (final el in doc.findAllElements(localName)) {
      final t = el.innerText.trim();
      if (t.isNotEmpty) return t;
    }
    return null;
  }

  static String _resolve(String baseDir, String href) {
    if (href.startsWith('/')) return href.substring(1);
    final parts = <String>[...baseDir.split('/'), ...href.split('/')]..removeWhere((p) => p.isEmpty);
    final out = <String>[];
    for (final p in parts) {
      if (p == '.') continue;
      if (p == '..') {
        if (out.isNotEmpty) out.removeLast();
      } else {
        out.add(p);
      }
    }
    return out.join('/');
  }

  static String _readText(ArchiveFile file) => utf8.decode(file.content, allowMalformed: true);

  /// Strips XHTML down to paragraph blocks, then splits each block into
  /// sentences (Korean/English enders `. ! ?` kept with the sentence).
  static List<List<String>> _extractParagraphs(String xhtml) {
    final doc = html_parser.parse(xhtml);
    final blocks = doc.querySelectorAll('p, h1, h2, h3, h4, li, blockquote');
    final source = blocks.isNotEmpty ? blocks : [doc.body ?? doc.documentElement!];

    final paragraphs = <List<String>>[];
    for (final block in source) {
      final text = block.text.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (text.isEmpty) continue;
      final sentences = _splitSentences(text);
      if (sentences.isNotEmpty) paragraphs.add(sentences);
    }
    return paragraphs;
  }

  static final _sentenceEnd = RegExp(r'(?<=[.!?…。！？])\s+');

  static List<String> _splitSentences(String paragraph) {
    return paragraph
        .split(_sentenceEnd)
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
}
