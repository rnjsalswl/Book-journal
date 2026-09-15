import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/epub_parser.dart';
import '../data/local/epub_import.dart';
import '../state/providers.dart';
import '../theme/pixel_colors.dart';
import '../theme/pixel_decorations.dart';
import '../theme/pixel_text.dart';
import '../widgets/pixel_button.dart';
import '../widgets/pixel_card.dart';
import '../widgets/pixel_toast.dart';

const _kCategories = [
  ('novel', '소설'),
  ('essay', '에세이'),
  ('sf', 'SF·판타지'),
  ('poem', '시'),
  ('new', '신간'),
];

const _kSpineColors = [
  PixelColors.wood,
  PixelColors.mossDeep,
  PixelColors.barkMid,
  PixelColors.mossMid,
  PixelColors.woodLight,
];

/// Pick an EPUB, parse it on-device, and add it to the shared book
/// catalog. The parsed body text never leaves this device — see
/// lib/data/local/book_content_store.dart. Only the title/author/category
/// (and the reader's underline/comment *coordinates* later on) sync to
/// Supabase.
class AddBookScreen extends ConsumerStatefulWidget {
  const AddBookScreen({super.key});

  @override
  ConsumerState<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends ConsumerState<AddBookScreen> {
  ParsedEpub? _parsed;
  String? _fileName;
  final _title = TextEditingController();
  final _author = TextEditingController();
  String _category = 'novel';
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    setState(() => _error = null);
    try {
      final result = await pickAndParseEpub();
      if (result == null) return;
      setState(() {
        _parsed = result.epub;
        _fileName = result.fileName;
        _title.text = result.epub.title;
        _author.text = result.epub.author;
      });
    } catch (e) {
      setState(() => _error = 'EPUB을 읽지 못했어요: $e');
    }
  }

  Future<void> _save() async {
    final parsed = _parsed;
    final userId = ref.read(currentUserIdProvider);
    if (parsed == null || userId == null || _busy) return;
    if (_title.text.trim().isEmpty) {
      PixelToastHost.of(context).show('제목을 입력하세요');
      return;
    }
    setState(() => _busy = true);
    try {
      final color = _kSpineColors[_title.text.hashCode.abs() % _kSpineColors.length];
      final colorHex = '#${color.toARGB32().toRadixString(16).substring(2)}';
      final book = await ref.read(booksRepositoryProvider).create(
            title: _title.text.trim(),
            author: _author.text.trim().isEmpty ? '작자 미상' : _author.text.trim(),
            category: _category,
            colorHex: colorHex,
            totalPages: parsed.paragraphs.length.clamp(1, 1 << 30),
          );
      await ref.read(bookContentStoreProvider).save(bookId: book.id, paragraphs: parsed.paragraphs);
      await ref.read(shelfRepositoryProvider).upsertProgress(
            userId: userId,
            bookId: book.id,
            currentPage: 0,
            totalPages: book.totalPages,
            status: 'reading',
          );
      ref.invalidate(booksProvider);
      ref.invalidate(shelfEntriesProvider(userId));
      if (mounted) {
        Navigator.of(context).pop();
        PixelToastHost.of(context).show('책을 서재에 올렸어요 (본문은 이 기기에만 저장돼요)');
      }
    } catch (e) {
      if (mounted) PixelToastHost.of(context).show('저장하지 못했어요: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PixelColors.phoneBg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(
                color: PixelColors.barkDark,
                border: Border(bottom: BorderSide(color: PixelColors.inkBorder, width: 4)),
              ),
              child: Row(
                children: [
                  PixelButton(
                    width: 40,
                    height: 40,
                    background: PixelColors.paperMuted,
                    onTap: () => Navigator.of(context).pop(),
                    child: Text('←', style: PixelText.style(size: 14)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text('책 올리기 · EPUB', style: PixelText.style(size: 15, color: PixelColors.accentCream))),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 22),
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: PixelColors.mossPale, border: Border.all(color: PixelColors.inkBorder, width: kPixelHairline)),
                    child: Text(
                      '올린 책의 원문은 이 기기(브라우저)에만 저장돼요. 서버에는 제목·저자 같은 정보와, 밑줄·댓글의 "몇 번째 문단·문장"이라는 위치 정보만 올라가요 — 실제 문장 내용은 올라가지 않아요.',
                      style: PixelText.style(size: 10, color: PixelColors.mossDeep, height: 1.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  PixelButton(
                    height: 52,
                    background: PixelColors.moss,
                    foreground: PixelColors.mossOnDark,
                    onTap: _pick,
                    child: Text(
                      _fileName == null ? 'EPUB 파일 선택' : '다른 파일 선택',
                      style: PixelText.style(size: 13, color: PixelColors.mossOnDark),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(_error!, style: PixelText.style(size: 11, color: PixelColors.accent)),
                  ],
                  if (_parsed != null) ...[
                    const SizedBox(height: 10),
                    PixelCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_fileName ?? '', style: PixelText.style(size: 11, color: PixelColors.textMuted)),
                          const SizedBox(height: 6),
                          Text('문단 ${_parsed!.paragraphs.length}개 인식됨', style: PixelText.style(size: 11, color: PixelColors.textMuted)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('제목', style: PixelText.style(size: 12)),
                    const SizedBox(height: 8),
                    _Field(controller: _title),
                    const SizedBox(height: 14),
                    Text('저자', style: PixelText.style(size: 12)),
                    const SizedBox(height: 8),
                    _Field(controller: _author),
                    const SizedBox(height: 14),
                    Text('분류', style: PixelText.style(size: 12)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        for (final (id, label) in _kCategories)
                          PixelButton(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            background: _category == id ? PixelColors.accent : PixelColors.paper,
                            foreground: _category == id ? PixelColors.accentCream : PixelColors.textPrimary,
                            onTap: () => setState(() => _category = id),
                            child: Text(label, style: PixelText.style(size: 11, color: _category == id ? PixelColors.accentCream : PixelColors.textPrimary)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    PixelButton(
                      height: 52,
                      background: PixelColors.accent,
                      foreground: PixelColors.accentCream,
                      shadowOffset: 4,
                      onTap: _busy ? null : _save,
                      child: Text(_busy ? '저장 중…' : '서재에 추가', style: PixelText.style(size: 14, color: PixelColors.accentCream)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  const _Field({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: PixelColors.paper, border: Border.all(color: PixelColors.inkBorder, width: kPixelBorder)),
      alignment: Alignment.centerLeft,
      child: TextField(controller: controller, style: PixelText.style(size: 12), decoration: const InputDecoration.collapsed(hintText: '')),
    );
  }
}
