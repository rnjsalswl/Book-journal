// Verifies the two content paths that feed the reader:
//  1. Bundled seed books load correctly through BookContentStore (the
//     librarian's quest books ship with real text, no upload needed).
//  2. EpubParser correctly reads a genuine EPUB container end-to-end — a
//     real in-memory-built .epub (zip + container.xml + OPF + XHTML), not
//     just unit-level string manipulation. This is the same code path a
//     user's uploaded .epub goes through in lib/data/local/epub_import.dart.

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_book_journal/data/epub_parser.dart';
import 'package:pixel_book_journal/data/local/book_content_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<int> _buildTestEpub({required String title, required String author, required List<String> chapterHtml}) {
  final archive = Archive();

  archive.addFile(ArchiveFile.string(
    'mimetype',
    'application/epub+zip',
  ));

  archive.addFile(ArchiveFile.string(
    'META-INF/container.xml',
    '<?xml version="1.0"?>'
        '<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">'
        '<rootfiles><rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/></rootfiles>'
        '</container>',
  ));

  final manifestItems = <String>[];
  final spineItems = <String>[];
  for (var i = 0; i < chapterHtml.length; i++) {
    final id = 'chap$i';
    manifestItems.add('<item id="$id" href="$id.xhtml" media-type="application/xhtml+xml"/>');
    spineItems.add('<itemref idref="$id"/>');
    archive.addFile(ArchiveFile.string(
      'OEBPS/$id.xhtml',
      '<?xml version="1.0" encoding="UTF-8"?>'
          '<html xmlns="http://www.w3.org/1999/xhtml"><body>${chapterHtml[i]}</body></html>',
    ));
  }

  archive.addFile(ArchiveFile.string(
    'OEBPS/content.opf',
    '<?xml version="1.0" encoding="UTF-8"?>'
        '<package xmlns="http://www.idpf.org/2007/opf" version="3.0">'
        '<metadata xmlns:dc="http://purl.org/dc/elements/1.1/">'
        '<dc:title>$title</dc:title>'
        '<dc:creator>$author</dc:creator>'
        '</metadata>'
        '<manifest>${manifestItems.join()}</manifest>'
        '<spine>${spineItems.join()}</spine>'
        '</package>',
  ));

  return ZipEncoder().encode(archive);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EpubParser against a real EPUB container', () {
    test('extracts title, author, and paragraphs across chapters', () {
      final bytes = _buildTestEpub(
        title: '테스트 도서',
        author: '테스트 저자',
        chapterHtml: [
          '<p>첫 번째 문단입니다. 두 문장이 있어요.</p><p>두 번째 문단.</p>',
          '<p>둘째 장의 첫 문단! 느낌표로 끝나는 문장인가?</p>',
        ],
      );

      final parsed = EpubParser.parse(bytes);

      expect(parsed.title, '테스트 도서');
      expect(parsed.author, '테스트 저자');
      // 3 <p> blocks total across both spine chapters, read in spine order.
      expect(parsed.paragraphs.length, 3);
      expect(parsed.paragraphs[0], ['첫 번째 문단입니다.', '두 문장이 있어요.']);
      expect(parsed.paragraphs[1], ['두 번째 문단.']);
      expect(parsed.paragraphs[2], ['둘째 장의 첫 문단!', '느낌표로 끝나는 문장인가?']);
    });

    test('correctly decodes multi-byte UTF-8 (Korean) text, not mojibake', () {
      final bytes = _buildTestEpub(title: '한글', author: '홍길동', chapterHtml: ['<p>안녕하세요.</p>']);
      final parsed = EpubParser.parse(bytes);
      expect(parsed.paragraphs.single, ['안녕하세요.']);
    });
  });

  group('BookContentStore seed assets', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('loads the SF quest book bundled with the app', () async {
      final store = BookContentStore();
      final content = await store.fetch('00000000-0000-0000-0000-000000000004');
      expect(content, isNotNull);
      expect(content!.isNotEmpty, isTrue);
      expect(content.first.first, contains('그 별은 지도에 없었다'));
    });

    test('loads the "new arrivals" quest book bundled with the app', () async {
      final store = BookContentStore();
      final content = await store.fetch('00000000-0000-0000-0000-000000000006');
      expect(content, isNotNull);
      expect(content!.first.first, contains('할머니는 매일 같은 시간에'));
    });

    test('returns null for a book with no local or bundled content', () async {
      final store = BookContentStore();
      final content = await store.fetch('nonexistent-book-id');
      expect(content, isNull);
    });
  });
}
