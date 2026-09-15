import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/epub_import.dart';
import '../data/reader_presence_repository.dart';
import '../models/annotation.dart';
import '../models/book.dart';
import '../state/providers.dart';
import '../theme/pixel_colors.dart';
import '../theme/pixel_decorations.dart';
import '../theme/pixel_text.dart';
import '../widgets/pixel_button.dart';
import '../widgets/pixel_card.dart';
import '../widgets/pixel_toast.dart';
import 'reader/reader_content.dart';
import 'review_screen.dart';

/// "e-book 리더" — tap a sentence to underline it, drop a speech-bubble
/// comment or a post-it, react with an emoji, or reply in-thread. Matches
/// `data-screen-label="e-book 리더"` in the prototype.
class ReaderScreen extends ConsumerStatefulWidget {
  final Book book;
  const ReaderScreen({super.key, required this.book});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  int? _selectedFlat;
  String? _tool; // underline | bubble | postit | emoji
  final _annoDraft = TextEditingController();
  String? _replyTargetId;
  final _replyDraft = TextEditingController();
  String? _lastUnderlineQuote;
  Map<String, ReaderPosition> _presence = {};
  late final ReaderPresenceRepository _presenceRepo;
  bool _attaching = false;
  ReaderContent _rc = const ReaderContent([]);

  Future<void> _attachEpub() async {
    setState(() => _attaching = true);
    try {
      final result = await pickAndParseEpub();
      if (result == null) return;
      await ref.read(bookContentStoreProvider).save(bookId: widget.book.id, paragraphs: result.epub.paragraphs);
      ref.invalidate(bookContentProvider(widget.book.id));
      if (mounted) PixelToastHost.of(context).show('이 기기에 본문을 연결했어요');
    } catch (e) {
      if (mounted) PixelToastHost.of(context).show('EPUB을 읽지 못했어요: $e');
    } finally {
      if (mounted) setState(() => _attaching = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _presenceRepo = ref.read(readerPresenceRepositoryProvider);
    _joinPresence();
  }

  Future<void> _joinPresence() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final profile = await ref.read(profileRepositoryProvider).fetch(userId);
    if (!mounted) return;
    await _presenceRepo.join(
      bookId: widget.book.id,
      userId: userId,
      displayName: profile.displayName,
      initialParagraphIndex: 0,
      onChange: (others) {
        if (mounted) setState(() => _presence = others);
      },
    );
  }

  @override
  void dispose() {
    _presenceRepo.leave();
    _annoDraft.dispose();
    _replyDraft.dispose();
    super.dispose();
  }

  void _select(int pi, int si) {
    setState(() {
      _selectedFlat = _rc.flatIndex(pi, si);
      _tool = null;
      _annoDraft.clear();
      _replyTargetId = null;
    });
    final userId = ref.read(currentUserIdProvider);
    if (userId != null) {
      ref.read(profileRepositoryProvider).fetch(userId).then((p) {
        _presenceRepo.updatePosition(pi, userId: userId, displayName: p.displayName);
      });
    }
  }

  BookAnnotation? _annotationAt(List<BookAnnotation> annos, int pi, int si, {bool underlineOnly = false, bool excludeUnderline = false}) {
    for (final a in annos) {
      if (a.paragraphIndex != pi || a.sentenceIndex != si) continue;
      if (underlineOnly && a.type != AnnotationType.underline) continue;
      if (excludeUnderline && a.type == AnnotationType.underline) continue;
      return a;
    }
    return null;
  }

  Future<void> _toggleUnderline(int pi, int si, {required String userId}) async {
    final repo = ref.read(annotationsRepositoryProvider);
    final annos = ref.read(annotationsProvider(widget.book.id)).value ?? [];
    final mine = annos.where((a) => a.type == AnnotationType.underline && a.userId == userId && a.paragraphIndex == pi && a.sentenceIndex == si);
    if (mine.isNotEmpty) {
      await repo.removeUnderline(userId: userId, bookId: widget.book.id, paragraphIndex: pi, sentenceIndex: si);
      if (mounted) PixelToastHost.of(context).show('밑줄을 지웠어요');
    } else {
      await repo.create(userId: userId, bookId: widget.book.id, paragraphIndex: pi, sentenceIndex: si, type: AnnotationType.underline);
      _lastUnderlineQuote = _rc.textAt(pi, si);
      if (mounted) PixelToastHost.of(context).show('밑줄을 그었어요');
    }
    ref.invalidate(annotationsProvider(widget.book.id));
    if (mounted) setState(() => _selectedFlat = null);
  }

  Future<void> _saveAnno(String userId) async {
    final text = _annoDraft.text.trim();
    if (text.isEmpty) {
      PixelToastHost.of(context).show('내용을 적어주세요');
      return;
    }
    final (pi, si) = _rc.fromFlat(_selectedFlat!);
    final type = _tool == 'postit' ? AnnotationType.postit : AnnotationType.bubble;
    await ref.read(annotationsRepositoryProvider).create(
          userId: userId,
          bookId: widget.book.id,
          paragraphIndex: pi,
          sentenceIndex: si,
          type: type,
          text: text,
        );
    ref.invalidate(annotationsProvider(widget.book.id));
    setState(() {
      _selectedFlat = null;
      _tool = null;
      _annoDraft.clear();
    });
    if (mounted) PixelToastHost.of(context).show(type == AnnotationType.postit ? '포스트잇을 붙였어요' : '말풍선을 남겼어요');
  }

  Future<void> _pickEmoji(String emoji, List<BookAnnotation> annos) async {
    if (_selectedFlat == null) return;
    final (pi, si) = _rc.fromFlat(_selectedFlat!);
    final target = _annotationAt(annos, pi, si, excludeUnderline: true);
    if (target != null) {
      await ref.read(annotationsRepositoryProvider).setEmoji(annotationId: target.id, emoji: emoji);
      ref.invalidate(annotationsProvider(widget.book.id));
      if (mounted) PixelToastHost.of(context).show('반응 $emoji 을 붙였어요');
    }
    setState(() {
      _selectedFlat = null;
      _tool = null;
    });
  }

  Future<void> _saveReply(String userId) async {
    final text = _replyDraft.text.trim();
    if (text.isEmpty) {
      PixelToastHost.of(context).show('답글을 적어주세요');
      return;
    }
    await ref.read(annotationsRepositoryProvider).reply(annotationId: _replyTargetId!, userId: userId, text: text);
    ref.invalidate(annotationsProvider(widget.book.id));
    setState(() {
      _replyTargetId = null;
      _replyDraft.clear();
    });
    if (mounted) PixelToastHost.of(context).show('스레드에 답글을 달았어요');
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final annosAsync = ref.watch(annotationsProvider(widget.book.id));
    final annos = annosAsync.value ?? [];
    final presenceByPara = <int, List<String>>{};
    for (final p in _presence.values) {
      presenceByPara.putIfAbsent(p.paragraphIndex, () => []).add(p.displayName);
    }

    final contentAsync = ref.watch(bookContentProvider(widget.book.id));
    final paragraphs = contentAsync.value;
    _rc = ReaderContent(paragraphs ?? const []);

    return Scaffold(
      backgroundColor: PixelColors.paper,
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
                  Expanded(
                    child: Text(widget.book.title, style: PixelText.style(size: 13, color: PixelColors.accentCream)),
                  ),
                  if (_presence.isNotEmpty)
                    Row(
                      children: _presence.values
                          .map((p) => Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: PixelAvatarTag(initial: p.displayName.isEmpty ? '?' : p.displayName[0], color: PixelColors.moss, size: 26, fontSize: 9),
                              ))
                          .toList(),
                    ),
                ],
              ),
            ),
            Expanded(
              child: contentAsync.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : paragraphs == null
                      ? _NoContentView(busy: _attaching, onAttach: _attachEpub)
                      : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                itemCount: paragraphs.length,
                itemBuilder: (context, pi) {
                  final sentences = paragraphs[pi];
                  final readers = presenceByPara[pi];
                  final marks = annos.where((a) => a.type != AnnotationType.underline && a.paragraphIndex == pi).toList();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (readers != null && readers.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Container(width: 8, height: 8, color: PixelColors.moss),
                                const SizedBox(width: 7),
                                Text('${readers.join(', ')}가 지금 이 부분을 읽고 있어요',
                                    style: PixelText.style(size: 9, color: PixelColors.mossDeep)),
                              ],
                            ),
                          ),
                        Text.rich(
                          TextSpan(
                            children: [
                              for (var si = 0; si < sentences.length; si++)
                                _sentenceSpan(pi, si, sentences[si], annos),
                            ],
                          ),
                          style: PixelText.style(size: 14, height: 2.1),
                        ),
                        for (final m in marks) _AnnotationCard(annotation: m, onEmoji: () {
                          setState(() {
                            _selectedFlat = _rc.flatIndex(m.paragraphIndex, m.sentenceIndex);
                            _tool = 'emoji';
                          });
                        }, onReply: () {
                          setState(() {
                            _replyTargetId = m.id;
                            _replyDraft.clear();
                          });
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (userId != null && paragraphs != null) _buildBottomBar(userId, annos),
          ],
        ),
      ),
    );
  }

  InlineSpan _sentenceSpan(int pi, int si, String text, List<BookAnnotation> annos) {
    final underline = _annotationAt(annos, pi, si, underlineOnly: true);
    final other = _annotationAt(annos, pi, si, excludeUnderline: true);
    final isSelected = _selectedFlat == _rc.flatIndex(pi, si);
    Color? bg;
    if (underline != null) {
      bg = PixelColors.accentPale;
    } else if (other != null) {
      bg = PixelColors.mossOnDark;
    }
    return TextSpan(
      text: '$text ',
      style: PixelText.style(size: 14, height: 2.1).copyWith(
        backgroundColor: bg,
        decoration: underline != null
            ? TextDecoration.underline
            : (other != null ? TextDecoration.underline : TextDecoration.none),
        decorationColor: underline != null ? PixelColors.accent : PixelColors.moss,
        decorationThickness: 2.2,
        decorationStyle: TextDecorationStyle.solid,
        color: isSelected ? PixelColors.accent : PixelColors.textPrimary,
      ),
      recognizer: (TapGestureRecognizer()..onTap = () => _select(pi, si)),
    );
  }

  Widget _buildBottomBar(String userId, List<BookAnnotation> annos) {
    if (_replyTargetId != null) {
      String replyTo = '';
      for (final a in annos) {
        if (a.id == _replyTargetId) replyTo = a.authorName;
      }
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: const BoxDecoration(
          color: PixelColors.barkDark,
          border: Border(top: BorderSide(color: PixelColors.inkBorder, width: 4)),
        ),
        child: Row(
          children: [
            Expanded(child: _TextInput(controller: _replyDraft, hint: '$replyTo에게 답글')),
            const SizedBox(width: 8),
            PixelButton(width: 58, height: 42, background: PixelColors.moss, foreground: PixelColors.mossOnDark, onTap: () => _saveReply(userId), child: Text('등록', style: PixelText.style(size: 12, color: PixelColors.mossOnDark))),
          ],
        ),
      );
    }

    if (_selectedFlat != null) {
      final (pi, si) = _rc.fromFlat(_selectedFlat!);
      final preview = _rc.textAt(pi, si);
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: const BoxDecoration(
          color: PixelColors.barkDark,
          border: Border(top: BorderSide(color: PixelColors.inkBorder, width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('선택한 문장 · ${preview.length > 16 ? '${preview.substring(0, 16)}…' : preview}',
                style: PixelText.style(size: 9, color: PixelColors.accentPale)),
            const SizedBox(height: 8),
            Row(
              children: [
                _toolButton('underline', '형광펜\n밑줄', () => _toggleUnderline(pi, si, userId: userId)),
                const SizedBox(width: 6),
                _toolButton('bubble', '말풍선\n코멘트', () => setState(() => _tool = 'bubble')),
                const SizedBox(width: 6),
                _toolButton('postit', '포스트잇\n메모', () => setState(() => _tool = 'postit')),
                const SizedBox(width: 6),
                _toolButton('emoji', '이모지\n반응', () => setState(() => _tool = 'emoji')),
              ],
            ),
            if (_tool == 'bubble' || _tool == 'postit') ...[
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(
                    child: _TextInput(
                      controller: _annoDraft,
                      hint: _tool == 'postit' ? '메모 (친구에게도 보여요)' : '이 문장에 하고 싶은 말',
                    ),
                  ),
                  const SizedBox(width: 8),
                  PixelButton(width: 58, height: 42, background: PixelColors.moss, foreground: PixelColors.mossOnDark, onTap: () => _saveAnno(userId), child: Text('붙임', style: PixelText.style(size: 12, color: PixelColors.mossOnDark))),
                ],
              ),
            ],
            if (_tool == 'emoji') ...[
              const SizedBox(height: 9),
              Row(
                children: [
                  for (final e in const ['♥', '!', '?', '★', '☾']) ...[
                    Expanded(
                      child: PixelButton(
                        height: 42,
                        background: PixelColors.paper,
                        onTap: () => _pickEmoji(e, annos),
                        child: Text(e, style: PixelText.style(size: 16)),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                ],
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: PixelColors.paperWarm,
        border: Border(top: BorderSide(color: PixelColors.barkDark, width: 4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text('문장을 누르면 밑줄 · 말풍선 · 포스트잇을 붙일 수 있어요',
                style: PixelText.style(size: 10, color: PixelColors.textMuted, height: 1.5)),
          ),
          PixelButton(
            height: 42,
            background: PixelColors.accent,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ReviewScreen(book: widget.book, quote: _lastUnderlineQuote)),
            ),
            child: Text('감상문', style: PixelText.style(size: 11, color: PixelColors.accentCream)),
          ),
        ],
      ),
    );
  }

  Widget _toolButton(String id, String label, VoidCallback onTap) {
    final active = _tool == id;
    return Expanded(
      child: PixelButton(
        height: 46,
        background: active ? PixelColors.accent : PixelColors.paperMuted,
        foreground: active ? PixelColors.accentCream : PixelColors.textPrimary,
        onTap: onTap,
        child: Text(label, textAlign: TextAlign.center, style: PixelText.style(size: 10, height: 1.3, color: active ? PixelColors.accentCream : PixelColors.textPrimary)),
      ),
    );
  }
}

class _NoContentView extends StatelessWidget {
  final bool busy;
  final VoidCallback onAttach;
  const _NoContentView({required this.busy, required this.onAttach});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('이 기기엔 이 책의 본문이 없어요', style: PixelText.style(size: 13), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              '가지고 계신 EPUB을 연결하면 이 기기에서만 저장돼서 읽을 수 있어요. 밑줄·댓글은 서버에 위치로만 저장되니, 같은 책을 올린 친구와는 그대로 겹쳐서 보여요.',
              textAlign: TextAlign.center,
              style: PixelText.style(size: 11, color: PixelColors.textMuted, height: 1.6),
            ),
            const SizedBox(height: 18),
            PixelButton(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              background: PixelColors.moss,
              foreground: PixelColors.mossOnDark,
              onTap: busy ? null : onAttach,
              child: Text(busy ? '읽는 중…' : 'EPUB 연결하기', style: PixelText.style(size: 12, color: PixelColors.mossOnDark)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _TextInput({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: PixelColors.paper, border: Border.all(color: PixelColors.inkBorder, width: kPixelBorder)),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: controller,
        style: PixelText.style(size: 12),
        decoration: InputDecoration.collapsed(hintText: hint, hintStyle: PixelText.style(size: 12, color: PixelColors.paperFaint)),
      ),
    );
  }
}

class _AnnotationCard extends StatelessWidget {
  final BookAnnotation annotation;
  final VoidCallback onEmoji;
  final VoidCallback onReply;
  const _AnnotationCard({required this.annotation, required this.onEmoji, required this.onReply});

  @override
  Widget build(BuildContext context) {
    final isPostit = annotation.type == AnnotationType.postit;
    return Padding(
      padding: EdgeInsets.only(top: 12, left: isPostit ? 26 : 0),
      child: Transform.rotate(
        angle: isPostit ? -0.024 : 0,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PixelAvatarTag(initial: annotation.authorName.isEmpty ? '?' : annotation.authorName[0], color: PixelColors.people[annotation.authorName] ?? PixelColors.textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                decoration: isPostit
                    ? pixelPostitBox(background: PixelColors.accentSoft)
                    : pixelBox(background: PixelColors.paperWarm, shadowOffset: 3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${isPostit ? '포스트잇' : '말풍선'} · ${annotation.authorName}${annotation.emoji != null ? '  ${annotation.emoji}' : ''}',
                      style: PixelText.style(size: 9, color: PixelColors.textMuted),
                    ),
                    const SizedBox(height: 6),
                    Text(annotation.text ?? '', style: PixelText.style(size: 12, height: 1.75)),
                    for (final r in annotation.replies)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.only(top: 8),
                          decoration: const BoxDecoration(border: Border(top: BorderSide(color: PixelColors.paperMuted, width: 2))),
                          child: RichText(
                            text: TextSpan(
                              style: PixelText.style(size: 11, height: 1.7),
                              children: [
                                TextSpan(text: r.authorName, style: PixelText.style(size: 11, color: PixelColors.people[r.authorName] ?? PixelColors.textMuted)),
                                TextSpan(text: ' ${r.text}'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        PixelButton(height: 30, padding: const EdgeInsets.symmetric(horizontal: 8), background: PixelColors.phoneBg, borderWidth: kPixelHairline, shadowOffset: 0, onTap: onEmoji, child: Text(annotation.emoji != null ? '${annotation.emoji} 1' : '반응', style: PixelText.style(size: 10))),
                        const SizedBox(width: 6),
                        PixelButton(height: 30, padding: const EdgeInsets.symmetric(horizontal: 8), background: PixelColors.phoneBg, borderWidth: kPixelHairline, shadowOffset: 0, onTap: onReply, child: Text('답글', style: PixelText.style(size: 10))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
