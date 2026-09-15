import 'package:file_picker/file_picker.dart';

import '../epub_parser.dart';

class EpubPickResult {
  final ParsedEpub epub;
  final String fileName;
  const EpubPickResult(this.epub, this.fileName);
}

/// Opens a native file picker scoped to `.epub`, reads it, and parses it
/// client-side. Returns null if the user cancels. Throws [FormatException]
/// (surface the message to the user) if the file isn't a readable EPUB.
Future<EpubPickResult?> pickAndParseEpub() async {
  final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['epub']);
  if (file == null) return null;
  final bytes = await file.readAsBytes();
  final parsed = EpubParser.parse(bytes, fallbackTitle: file.name.replaceAll('.epub', ''));
  return EpubPickResult(parsed, file.name);
}
