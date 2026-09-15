import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import '../theme/pixel_colors.dart';
import '../theme/pixel_text.dart';
import '../widgets/pixel_button.dart';
import '../widgets/pixel_card.dart';
import 'add_book_screen.dart';
import 'map/overlays.dart';

const _kTabs = ['전체', '읽는 중', '다 읽음', '함께'];

/// "내 서재" tab — matches `data-screen-label="내 서재"` in the prototype.
class ShelfScreen extends ConsumerStatefulWidget {
  const ShelfScreen({super.key});

  @override
  ConsumerState<ShelfScreen> createState() => _ShelfScreenState();
}

class _ShelfScreenState extends ConsumerState<ShelfScreen> {
  String _tab = '전체';

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const SizedBox.shrink();
    final shelfAsync = ref.watch(shelfEntriesProvider(userId));
    final reviewCountAsync = ref.watch(reviewCountProvider(userId));

    return ColoredBox(
      color: PixelColors.phoneBg,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            color: PixelColors.barkMid,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('내 서재', style: PixelText.style(size: 17, color: PixelColors.accentCream))),
                    PixelButton(
                      width: 36,
                      height: 36,
                      background: PixelColors.moss,
                      foreground: PixelColors.mossOnDark,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddBookScreen())),
                      child: Text('+', style: PixelText.style(size: 18, color: PixelColors.mossOnDark)),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                shelfAsync.when(
                  data: (entries) {
                    final shared = entries.where((e) => e.sharedGroupId != null).length;
                    final reviews = reviewCountAsync.value ?? 0;
                    return Text(
                      '책 ${entries.length}권 · 감상문 $reviews편 · 함께 읽는 중 $shared권',
                      style: PixelText.style(size: 11, color: PixelColors.accentSoft),
                    );
                  },
                  loading: () => Text('불러오는 중…', style: PixelText.style(size: 11, color: PixelColors.accentSoft)),
                  error: (e, _) => Text('불러오지 못했어요', style: PixelText.style(size: 11, color: PixelColors.accentSoft)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: PixelColors.paperWarm,
              border: Border(bottom: BorderSide(color: PixelColors.barkDark, width: 4)),
            ),
            child: Row(
              children: [
                for (final t in _kTabs) ...[
                  Expanded(
                    child: PixelButton(
                      height: 38,
                      shadowOffset: 3,
                      background: _tab == t ? PixelColors.accent : PixelColors.paper,
                      foreground: _tab == t ? PixelColors.accentCream : PixelColors.textPrimary,
                      onTap: () => setState(() => _tab = t),
                      child: Text(t, style: PixelText.style(size: 11, color: _tab == t ? PixelColors.accentCream : PixelColors.textPrimary)),
                    ),
                  ),
                  if (t != _kTabs.last) const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          Expanded(
            child: shelfAsync.when(
              data: (entries) {
                final filtered = entries.where((e) {
                  switch (_tab) {
                    case '읽는 중':
                      return e.status == 'reading';
                    case '다 읽음':
                      return e.status == 'done';
                    case '함께':
                      return e.sharedGroupId != null;
                    default:
                      return true;
                  }
                }).toList();
                if (filtered.isEmpty) {
                  return Center(child: Text('아직 책이 없어요', style: PixelText.style(size: 12, color: PixelColors.textMuted)));
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final e = filtered[i];
                    return PixelButton(
                      shadowOffset: 4,
                      padding: const EdgeInsets.all(8),
                      onTap: () => showBookDetailSheet(context, ref, e.book),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            height: 108,
                            padding: const EdgeInsets.all(7),
                            color: e.book.color,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.book.title, style: PixelText.style(size: 11, height: 1.4, color: PixelColors.accentCream)),
                                Text(e.book.author, style: PixelText.style(size: 9, color: PixelColors.accentPale)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          PixelProgressBar(value: e.pct / 100.0),
                          const SizedBox(height: 6),
                          Text(e.metaLabel, style: PixelText.style(size: 10, color: PixelColors.textMuted)),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('불러오지 못했어요: $e', style: PixelText.style(size: 12))),
            ),
          ),
        ],
      ),
    );
  }
}
