import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/book.dart';
import '../../state/app_shell_state.dart';
import '../../state/providers.dart';
import '../../theme/pixel_colors.dart';
import '../../theme/pixel_decorations.dart';
import '../../theme/pixel_text.dart';
import '../../widgets/pixel_button.dart';
import '../../widgets/pixel_card.dart';
import '../../widgets/pixel_toast.dart';
import '../reader_screen.dart';
import '../review_screen.dart';
import 'dialogue_data.dart';
import 'pixel_sprites.dart';
import 'stations.dart';

Future<void> showLibrarianDialogue(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x80201E1D),
    isDismissible: true,
    builder: (ctx) => _DialogueSheet(ref: ref),
  );
}

class _DialogueSheet extends StatefulWidget {
  final WidgetRef ref;
  const _DialogueSheet({required this.ref});

  @override
  State<_DialogueSheet> createState() => _DialogueSheetState();
}

class _DialogueSheetState extends State<_DialogueSheet> {
  int step = 0;

  Future<void> _pick(DialogueAction a) async {
    if (a.kind == DialogueActionKind.next) {
      setState(() => step = 1);
    } else if (a.kind == DialogueActionKind.alt) {
      setState(() => step = 2);
    } else if (a.kind == DialogueActionKind.close) {
      Navigator.of(context).pop();
    } else {
      final ref = widget.ref;
      final userId = ref.read(currentUserIdProvider);
      Navigator.of(context).pop();
      if (userId == null) return;
      final books = await ref.read(booksRepositoryProvider).byCategory('sf');
      if (books.isEmpty) return;
      await ref.read(questsRepositoryProvider).give(userId: userId, bookId: books.first.id);
      ref.invalidate(activeQuestProvider(userId));
      if (mounted) PixelToastHost.of(context).show('퀘스트를 받았어요 · SF 서가');
    }
  }

  @override
  Widget build(BuildContext context) {
    final node = kLibrarianDialogue[step];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: PixelCard(
        background: PixelColors.paper,
        borderWidth: 4,
        shadowOffset: 6,
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 60,
                  height: 75,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: PixelColors.mossDeep,
                      border: Border.all(color: PixelColors.inkBorder, width: kPixelBorder),
                    ),
                    child: CustomPaint(painter: const PixelSpritePainter(art: kLibrarianSprite, scale: 3)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('사서 모루 · 서관지기', style: PixelText.style(size: 11, color: PixelColors.wood)),
                      const SizedBox(height: 8),
                      Text(node.text, style: PixelText.style(size: 13, height: 1.9)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                for (final a in node.actions) ...[
                  Expanded(
                    child: PixelButton(
                      height: 46,
                      background: node.actions.indexOf(a) == 0 ? PixelColors.moss : PixelColors.paperWarm,
                      foreground: node.actions.indexOf(a) == 0 ? PixelColors.mossOnDark : PixelColors.textPrimary,
                      onTap: () => _pick(a),
                      child: Text(a.label, style: PixelText.style(size: 12)),
                    ),
                  ),
                  if (a != node.actions.last) const SizedBox(width: 8),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showShelfBrowseSheet(
  BuildContext context,
  WidgetRef ref, {
  required Station station,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x80201E1D),
    isScrollControlled: true,
    builder: (ctx) => _BrowseSheet(station: station, ref: ref),
  );
}

class _BrowseSheet extends ConsumerWidget {
  final Station station;
  final WidgetRef ref;
  const _BrowseSheet({required this.station, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef _) {
    final booksAsync = ref.watch(booksProvider);
    return FractionallySizedBox(
      heightFactor: 0.76,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: PixelColors.barkMid,
            child: Row(
              children: [
                Expanded(child: Text(station.name, style: PixelText.style(size: 15, color: PixelColors.accentCream))),
                PixelButton(
                  width: 40,
                  height: 40,
                  background: PixelColors.paperMuted,
                  shadowOffset: 0,
                  onTap: () => Navigator.of(context).pop(),
                  child: Text('✕', style: PixelText.style(size: 14)),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: PixelColors.phoneBg,
              child: booksAsync.when(
                data: (books) {
                  final list = books.where((b) => b.category == station.category).toList();
                  return ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final book = list[i];
                      return PixelButton(
                        shadowOffset: 4,
                        padding: const EdgeInsets.all(10),
                        onTap: () {
                          Navigator.of(context).pop();
                          showBookDetailSheet(context, ref, book);
                        },
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 62,
                              decoration: BoxDecoration(
                                color: book.color,
                                border: Border.all(color: PixelColors.inkBorder, width: kPixelBorder),
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(book.title, style: PixelText.style(size: 13)),
                                  const SizedBox(height: 5),
                                  Text(book.author, style: PixelText.style(size: 10, color: PixelColors.textMuted)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('불러오지 못했어요: $e', style: PixelText.style(size: 11))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showBookDetailSheet(BuildContext context, WidgetRef ref, Book book) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x8C201E1D),
    builder: (ctx) => _BookDetailSheet(book: book, ref: ref),
  );
}

class _BookDetailSheet extends ConsumerWidget {
  final Book book;
  final WidgetRef ref;
  const _BookDetailSheet({required this.book, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef _) {
    final userId = ref.watch(currentUserIdProvider);
    final shelfAsync = userId == null
        ? const AsyncValue<List<ShelfEntry>>.data([])
        : ref.watch(shelfEntriesProvider(userId));
    final shelfList = shelfAsync.value ?? const <ShelfEntry>[];
    ShelfEntry? entry;
    for (final e in shelfList) {
      if (e.book.id == book.id) {
        entry = e;
        break;
      }
    }
    final pct = (entry?.pct ?? 0) / 100.0;

    return Padding(
      padding: const EdgeInsets.all(22),
      child: PixelCard(
        background: PixelColors.paper,
        borderWidth: 4,
        shadowOffset: 6,
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 62,
                  height: 88,
                  decoration: BoxDecoration(
                    color: book.color,
                    border: Border.all(color: PixelColors.inkBorder, width: kPixelBorder),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(book.title, style: PixelText.style(size: 15, height: 1.4)),
                      const SizedBox(height: 6),
                      Text(book.author, style: PixelText.style(size: 11, color: PixelColors.textMuted)),
                      const SizedBox(height: 8),
                      PixelProgressBar(value: pct),
                      const SizedBox(height: 6),
                      Text(
                        entry == null ? '아직 펼치지 않은 책' : entry.metaLabel,
                        style: PixelText.style(size: 10, color: PixelColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            PixelButton(
              height: 48,
              background: PixelColors.moss,
              foreground: PixelColors.mossOnDark,
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReaderScreen(book: book)));
              },
              child: Text('e-book 열기', style: PixelText.style(size: 13, color: PixelColors.mossOnDark)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: PixelButton(
                    height: 46,
                    background: PixelColors.accentSoft,
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReviewScreen(book: book)));
                    },
                    child: Text('감상문 쓰기', style: PixelText.style(size: 11)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PixelButton(
                    height: 46,
                    background: PixelColors.phoneBg,
                    onTap: () async {
                      final uid = ref.read(currentUserIdProvider);
                      Navigator.of(context).pop();
                      if (uid == null) return;
                      final group = await ref.read(groupsRepositoryProvider).myGroup(uid);
                      if (group == null) {
                        if (context.mounted) PixelToastHost.of(context).show('아직 참여한 모임이 없어요');
                        return;
                      }
                      await ref.read(shelfRepositoryProvider).upsertProgress(
                            userId: uid,
                            bookId: book.id,
                            currentPage: entry?.currentPage ?? 0,
                            totalPages: book.totalPages,
                            status: entry?.status ?? 'reading',
                            sharedGroupId: group.id,
                          );
                      ref.invalidate(shelfEntriesProvider(uid));
                      ref.read(currentTabProvider.notifier).state = 2;
                      if (context.mounted) PixelToastHost.of(context).show('수요일의 책상에 초대장을 보냈어요');
                    },
                    child: Text('교환일기 초대', style: PixelText.style(size: 11)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            PixelButton(
              height: 40,
              background: Colors.transparent,
              shadowOffset: 0,
              onTap: () => Navigator.of(context).pop(),
              child: Text('닫기', style: PixelText.style(size: 11, color: PixelColors.textMuted)),
            ),
          ],
        ),
      ),
    );
  }
}
