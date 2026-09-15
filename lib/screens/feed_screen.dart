import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/book.dart';
import '../models/feed_entry.dart';
import '../state/providers.dart';
import '../theme/pixel_colors.dart';
import '../theme/pixel_decorations.dart';
import '../theme/pixel_text.dart';
import '../widgets/pixel_button.dart';
import '../widgets/pixel_card.dart';
import '../widgets/pixel_toast.dart';
import 'reader_screen.dart';

/// "교환일기" tab — the "수요일의 책상" small-group feed. Matches
/// `data-screen-label="교환일기"` in the prototype.
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _draft = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  Future<void> _createGroup(String userId) async {
    setState(() => _busy = true);
    try {
      await ref.read(groupsRepositoryProvider).create(name: '수요일의 책상', createdBy: userId);
      ref.invalidate(myGroupProvider(userId));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _post(String userId, String groupId) async {
    final text = _draft.text.trim();
    if (text.isEmpty) {
      PixelToastHost.of(context).show('한 줄을 먼저 적어주세요');
      return;
    }
    await ref.read(feedRepositoryProvider).post(groupId: groupId, userId: userId, kind: '한 줄', text: text);
    _draft.clear();
    ref.invalidate(feedProvider((groupId: groupId, userId: userId)));
    if (mounted) PixelToastHost.of(context).show('책상에 올려두었어요');
  }

  Future<void> _react(String userId, String groupId, FeedEntry e) async {
    await ref.read(feedRepositoryProvider).toggleReaction(e.id);
    ref.invalidate(feedProvider((groupId: groupId, userId: userId)));
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const SizedBox.shrink();
    final groupAsync = ref.watch(myGroupProvider(userId));

    return ColoredBox(
      color: PixelColors.paperWarm,
      child: groupAsync.when(
        data: (group) {
          if (group == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('아직 참여한 교환일기 모임이 없어요', style: PixelText.style(size: 12, color: PixelColors.textMuted)),
                    const SizedBox(height: 14),
                    PixelButton(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      background: PixelColors.moss,
                      foreground: PixelColors.mossOnDark,
                      onTap: _busy ? null : () => _createGroup(userId),
                      child: Text('수요일의 책상 만들기', style: PixelText.style(size: 12, color: PixelColors.mossOnDark)),
                    ),
                  ],
                ),
              ),
            );
          }

          final membersAsync = ref.watch(groupMembersProvider(group.id));
          final feedAsync = ref.watch(feedProvider((groupId: group.id, userId: userId)));

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                color: PixelColors.barkMid,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name, style: PixelText.style(size: 17, color: PixelColors.accentCream)),
                    const SizedBox(height: 9),
                    membersAsync.when(
                      data: (members) => Row(
                        children: [
                          for (final m in members)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: PixelAvatarTag(initial: m.displayName.isEmpty ? '?' : m.displayName[0], color: PixelColors.people[m.displayName] ?? PixelColors.mossMid, size: 26, fontSize: 10),
                            ),
                          const SizedBox(width: 4),
                          Text('${members.length}명', style: PixelText.style(size: 10, color: PixelColors.accentSoft)),
                        ],
                      ),
                      loading: () => const SizedBox(height: 26),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: feedAsync.when(
                  data: (entries) {
                    final memberCount = membersAsync.value?.length ?? 0;
                    final today = DateTime.now();
                    final postedToday = entries
                        .where((e) => e.createdAt.year == today.year && e.createdAt.month == today.month && e.createdAt.day == today.day)
                        .map((e) => e.userId)
                        .toSet()
                        .length;
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                      children: [
                        for (final e in entries) ...[
                          _FeedCard(
                            entry: e,
                            onReact: () => _react(userId, group.id, e),
                            onOpenBook: e.bookId == null
                                ? null
                                : () async {
                                    final books = ref.read(booksProvider).value ?? [];
                                    Book? book;
                                    for (final b in books) {
                                      if (b.id == e.bookId) book = b;
                                    }
                                    if (book != null && mounted) {
                                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReaderScreen(book: book!)));
                                    }
                                  },
                          ),
                          const SizedBox(height: 12),
                        ],
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(border: Border.all(color: PixelColors.paperTaupe, width: 3)),
                          child: Text(
                            memberCount == 0
                                ? '모임원이 모이면 여기에 현황이 표시돼요'
                                : '$memberCount명 모두 오늘 한 줄을 남기면 모임 뱃지가 채워집니다 ($postedToday/$memberCount)',
                            textAlign: TextAlign.center,
                            style: PixelText.style(size: 10, color: PixelColors.textMuted, height: 1.6),
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('불러오지 못했어요: $e', style: PixelText.style(size: 12))),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: const BoxDecoration(
                  color: PixelColors.paperWarm,
                  border: Border(top: BorderSide(color: PixelColors.barkDark, width: 4)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(color: PixelColors.paper, border: Border.all(color: PixelColors.inkBorder, width: kPixelBorder)),
                        alignment: Alignment.centerLeft,
                        child: TextField(
                          controller: _draft,
                          style: PixelText.style(size: 12),
                          decoration: InputDecoration.collapsed(hintText: '오늘 읽은 데서 한 줄', hintStyle: PixelText.style(size: 12, color: PixelColors.paperFaint)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PixelButton(width: 66, height: 44, background: PixelColors.moss, foreground: PixelColors.mossOnDark, onTap: () => _post(userId, group.id), child: Text('남기기', style: PixelText.style(size: 12, color: PixelColors.mossOnDark))),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('불러오지 못했어요: $e', style: PixelText.style(size: 12))),
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  final FeedEntry entry;
  final VoidCallback onReact;
  final VoidCallback? onOpenBook;
  const _FeedCard({required this.entry, required this.onReact, this.onOpenBook});

  @override
  Widget build(BuildContext context) {
    return PixelCard(
      padding: const EdgeInsets.all(11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PixelAvatarTag(initial: entry.authorName.isEmpty ? '?' : entry.authorName[0], color: PixelColors.people[entry.authorName] ?? PixelColors.textMuted),
              const SizedBox(width: 8),
              Text(entry.authorName, style: PixelText.style(size: 13)),
              const SizedBox(width: 8),
              Text(entry.whenLabel(), style: PixelText.style(size: 10, color: PixelColors.textMuted)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                color: PixelColors.barkDark,
                child: Text(entry.kind, style: PixelText.style(size: 9, color: PixelColors.accentPale)),
              ),
            ],
          ),
          if (entry.sourceRef != null) ...[
            const SizedBox(height: 9),
            Container(
              padding: const EdgeInsets.only(left: 8),
              decoration: const BoxDecoration(border: Border(left: BorderSide(color: PixelColors.accent, width: 4))),
              child: Text(entry.sourceRef!, style: PixelText.style(size: 10, color: PixelColors.textMuted, height: 1.5)),
            ),
          ],
          const SizedBox(height: 9),
          Text(entry.text, style: PixelText.style(size: 12, height: 1.8)),
          const SizedBox(height: 7),
          Row(
            children: [
              PixelButton(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 11),
                background: entry.reactedByMe ? PixelColors.accentSoft : PixelColors.accentPale,
                onTap: onReact,
                child: Text('♥ ${entry.reactionCount}', style: PixelText.style(size: 11)),
              ),
              if (onOpenBook != null) ...[
                const SizedBox(width: 7),
                PixelButton(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  background: PixelColors.paper,
                  onTap: onOpenBook,
                  child: Text('그 페이지로', style: PixelText.style(size: 11)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
