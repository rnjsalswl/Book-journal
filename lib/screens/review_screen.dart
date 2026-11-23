import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/book.dart';
import '../state/app_shell_state.dart';
import '../state/providers.dart';
import '../theme/pixel_colors.dart';
import '../theme/pixel_decorations.dart';
import '../theme/pixel_text.dart';
import '../widgets/pixel_button.dart';
import '../widgets/pixel_card.dart';
import '../widgets/pixel_toast.dart';

const _kMoods = ['멈춰 섰다', '따뜻했다', '서늘했다', '웃었다', '답답했다', '다시 읽고 싶다'];
const _kScopes = ['나만 보기', '수요일의 책상', '전체 공개'];

String _scopeToDb(String label) => switch (label) {
      '나만 보기' => 'private',
      '전체 공개' => 'public',
      _ => 'group',
    };

/// "감상문 작성" — matches `data-screen-label="감상문 작성"` in the prototype.
class ReviewScreen extends ConsumerStatefulWidget {
  final Book book;
  final String? quote;
  const ReviewScreen({super.key, required this.book, this.quote});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  int _stars = 4;
  final Set<String> _moods = {'멈춰 섰다'};
  String _scope = '수요일의 책상';
  final _text = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || _busy) return;
    if (_text.text.trim().isEmpty) {
      PixelToastHost.of(context).show('감상을 적어주세요');
      return;
    }
    setState(() => _busy = true);
    try {
      final scopeDb = _scopeToDb(_scope);
      String? groupId;
      if (scopeDb == 'group') {
        final group = await ref.read(groupsRepositoryProvider).myGroup(userId);
        groupId = group?.id;
      }
      await ref.read(reviewsRepositoryProvider).create(
            userId: userId,
            bookId: widget.book.id,
            stars: _stars,
            moods: _moods.toList(),
            quote: widget.quote,
            text: _text.text.trim(),
            scope: scopeDb,
            groupId: groupId,
          );
      await ref.read(shelfRepositoryProvider).markDone(userId: userId, bookId: widget.book.id);
      await ref.read(profileRepositoryProvider).addXp(userId, 40);

      final quest = await ref.read(questsRepositoryProvider).activeFor(userId);
      if (quest != null && quest.bookId == widget.book.id) {
        await ref.read(questsRepositoryProvider).complete(quest.id);
        await ref.read(badgesRepositoryProvider).bump('library_wanderer');
        ref.invalidate(activeQuestProvider(userId));
        ref.invalidate(badgesProvider(userId));
      }

      ref.invalidate(shelfEntriesProvider(userId));
      ref.invalidate(profileProvider(userId));
      ref.invalidate(reviewCountProvider(userId));
      ref.read(currentTabProvider.notifier).state = 1;
      if (mounted) {
        Navigator.of(context).pop();
        PixelToastHost.of(context).show('감상문을 서재에 꽂았어요 · +40 XP');
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
                  Expanded(child: Text('감상문 쓰기', style: PixelText.style(size: 15, color: PixelColors.accentCream))),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 22),
                children: [
                  PixelCard(
                    child: Row(
                      children: [
                        Container(width: 56, height: 80, color: widget.book.color),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.book.title, style: PixelText.style(size: 14)),
                              const SizedBox(height: 6),
                              Text(widget.book.author, style: PixelText.style(size: 11, color: PixelColors.textMuted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('별점', style: PixelText.style(size: 12)),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      for (var n = 1; n <= 5; n++) ...[
                        PixelButton(
                          width: 50,
                          height: 50,
                          background: n <= _stars ? PixelColors.accentSoft : PixelColors.paper,
                          foreground: n <= _stars ? PixelColors.wood : PixelColors.paperFaint,
                          onTap: () => setState(() => _stars = n),
                          child: Text('★', style: PixelText.style(size: 20, color: n <= _stars ? PixelColors.wood : PixelColors.paperFaint)),
                        ),
                        if (n < 5) const SizedBox(width: 7),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('읽고 난 기분', style: PixelText.style(size: 12)),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final m in _kMoods)
                        PixelButton(
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 13),
                          background: _moods.contains(m) ? PixelColors.moss : PixelColors.paper,
                          foreground: _moods.contains(m) ? PixelColors.mossOnDark : PixelColors.textPrimary,
                          onTap: () => setState(() => _moods.contains(m) ? _moods.remove(m) : _moods.add(m)),
                          child: Text(m, style: PixelText.style(size: 11, color: _moods.contains(m) ? PixelColors.mossOnDark : PixelColors.textPrimary)),
                        ),
                    ],
                  ),
                  if (widget.quote != null) ...[
                    const SizedBox(height: 16),
                    Text('리더에서 옮겨온 문장', style: PixelText.style(size: 12)),
                    const SizedBox(height: 9),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: PixelColors.paper,
                        border: const Border(
                          top: BorderSide(color: PixelColors.inkBorder, width: kPixelBorder),
                          bottom: BorderSide(color: PixelColors.inkBorder, width: kPixelBorder),
                          right: BorderSide(color: PixelColors.inkBorder, width: kPixelBorder),
                          left: BorderSide(color: PixelColors.accent, width: 10),
                        ),
                      ),
                      child: Text(widget.quote!, style: PixelText.style(size: 12, height: 1.9)),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text('감상', style: PixelText.style(size: 12)),
                  const SizedBox(height: 9),
                  Container(
                    decoration: pixelBox(background: PixelColors.paper, shadowOffset: 4),
                    padding: const EdgeInsets.all(11),
                    child: TextField(
                      controller: _text,
                      maxLines: 6,
                      style: PixelText.style(size: 12, height: 1.9),
                      decoration: InputDecoration.collapsed(
                        hintText: '이 책이 어디서 나를 멈추게 했는지 적어두세요',
                        hintStyle: PixelText.style(size: 12, color: PixelColors.paperFaint),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('사서 모루의 질문: 기다림이 좋았던 적이 있나요?', style: PixelText.style(size: 10, color: PixelColors.textMuted)),
                      Text('${_text.text.length}자', style: PixelText.style(size: 10, color: PixelColors.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('누구에게 보일까요', style: PixelText.style(size: 12)),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      for (final s in _kScopes) ...[
                        Expanded(
                          child: PixelButton(
                            height: 46,
                            background: _scope == s ? PixelColors.accent : PixelColors.paper,
                            foreground: _scope == s ? PixelColors.accentCream : PixelColors.textPrimary,
                            onTap: () => setState(() => _scope = s),
                            child: Text(s, style: PixelText.style(size: 11, color: _scope == s ? PixelColors.accentCream : PixelColors.textPrimary)),
                          ),
                        ),
                        if (s != _kScopes.last) const SizedBox(width: 7),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(
                color: PixelColors.paperWarm,
                border: Border(top: BorderSide(color: PixelColors.barkDark, width: 4)),
              ),
              child: PixelButton(
                height: 52,
                background: PixelColors.moss,
                foreground: PixelColors.mossOnDark,
                shadowOffset: 4,
                onTap: _busy ? null : _save,
                child: Text(
                  _busy ? '저장 중…' : '서재에 꽂기 · +40 XP',
                  style: PixelText.style(size: 14, color: PixelColors.mossOnDark),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
