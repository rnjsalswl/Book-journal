import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import '../theme/pixel_colors.dart';
import '../theme/pixel_decorations.dart';
import '../theme/pixel_text.dart';
import '../widgets/pixel_card.dart';
import 'map/pixel_sprites.dart';

/// "나" tab — matches `data-screen-label="프로필"` in the prototype.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const SizedBox.shrink();
    final profileAsync = ref.watch(profileProvider(userId));
    final heatAsync = ref.watch(heatDaysProvider(userId));
    final badgesAsync = ref.watch(badgesProvider(userId));
    final reviewCountAsync = ref.watch(reviewCountProvider(userId));
    final shelfAsync = ref.watch(shelfEntriesProvider(userId));

    final profile = profileAsync.value;
    final doneCount = shelfAsync.value?.where((e) => e.status == 'done').length ?? 0;
    final annoCount = 0; // annotation totals are per-book; shown per-book in the reader instead.

    return ColoredBox(
      color: PixelColors.phoneBg,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            color: PixelColors.barkMid,
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 80,
                  decoration: BoxDecoration(color: PixelColors.wood, border: Border.all(color: PixelColors.inkBorder, width: kPixelBorder)),
                  child: const CustomPaint(painter: PixelSpritePainter(art: kPlayerSprite, scale: 3)),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile?.displayName ?? '…', style: PixelText.style(size: 18, color: PixelColors.accentCream)),
                      const SizedBox(height: 6),
                      Text('Lv.${profile?.level ?? 1} 책벌레 · ${profile?.floorAccess ?? 1}층 열람권', style: PixelText.style(size: 11, color: PixelColors.accentSoft)),
                      const SizedBox(height: 6),
                      Text(profile?.xpLabel ?? '', style: PixelText.style(size: 11, color: PixelColors.mossPale)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
              children: [
                Row(
                  children: [
                    Expanded(child: _StatCard(value: '$doneCount', label: '읽은 책')),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard(value: '${reviewCountAsync.value ?? 0}', label: '감상문')),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard(value: '$annoCount', label: '남긴 주석')),
                  ],
                ),
                const SizedBox(height: 16),
                Text('최근 30일 독서 기록', style: PixelText.style(size: 12)),
                const SizedBox(height: 9),
                PixelCard(
                  child: heatAsync.when(
                    data: (days) => GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 15, crossAxisSpacing: 3, mainAxisSpacing: 3),
                      itemCount: days.length,
                      itemBuilder: (context, i) => Container(
                        decoration: BoxDecoration(border: Border.all(color: PixelColors.paperMuted, width: 1), color: _heatColor(days[i].intensity)),
                      ),
                    ),
                    loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator())),
                    error: (e, _) => Text('불러오지 못했어요', style: PixelText.style(size: 11)),
                  ),
                ),
                const SizedBox(height: 16),
                Text('도전과제', style: PixelText.style(size: 12)),
                const SizedBox(height: 9),
                badgesAsync.when(
                  data: (badges) => Column(
                    children: [
                      for (final b in badges) ...[
                        Opacity(
                          opacity: b.opacity,
                          child: PixelCard(
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
                            child: Row(
                              children: [
                                Container(width: 32, height: 32, decoration: BoxDecoration(color: Color(b.colorHex), border: Border.all(color: PixelColors.inkBorder, width: kPixelBorder))),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(b.name, style: PixelText.style(size: 12)),
                                      const SizedBox(height: 4),
                                      Text('${b.description} — ${b.progress} / ${b.goal}', style: PixelText.style(size: 10, color: PixelColors.textMuted)),
                                    ],
                                  ),
                                ),
                                Text(b.stateLabel, style: PixelText.style(size: 10, color: PixelColors.textMuted)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 9),
                      ],
                    ],
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('불러오지 못했어요: $e', style: PixelText.style(size: 11)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _heatColor(int intensity) => switch (intensity) {
        3 => PixelColors.mossDeep,
        2 => PixelColors.moss,
        1 => PixelColors.heatMid,
        _ => PixelColors.heatLow,
      };
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return PixelCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        children: [
          Text(value, style: PixelText.style(size: 19, color: PixelColors.wood)),
          const SizedBox(height: 6),
          Text(label, style: PixelText.style(size: 10, color: PixelColors.textMuted)),
        ],
      ),
    );
  }
}
