import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_shell_state.dart';
import '../theme/pixel_colors.dart';
import '../theme/pixel_text.dart';
import 'feed_screen.dart';
import 'map_screen.dart';
import 'profile_screen.dart';
import 'shelf_screen.dart';

const _kTabLabels = ['서관', '내 서재', '교환일기', '나'];

/// Root shell once signed in: the four bottom-nav tabs, matching the
/// prototype's `nav` (서관/내 서재/교환일기/나). The reader and review
/// screens are pushed as full routes instead (they have their own back
/// arrow in the prototype too), rather than living in this tab set.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(currentTabProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: tab,
          children: const [
            MapScreen(),
            ShelfScreen(),
            FeedScreen(),
            ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: PixelColors.barkDark,
            border: Border(top: BorderSide(color: PixelColors.inkBorder, width: 4)),
          ),
          child: Row(
            children: [
              for (var i = 0; i < _kTabLabels.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => ref.read(currentTabProvider.notifier).state = i,
                    child: Container(
                      height: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: tab == i ? PixelColors.accent : Colors.transparent, width: 4)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(width: 14, height: 14, color: tab == i ? PixelColors.accentSoft : PixelColors.paperTaupe),
                          const SizedBox(height: 6),
                          Text(
                            _kTabLabels[i],
                            style: PixelText.style(size: 10, color: tab == i ? PixelColors.accentSoft : PixelColors.paperTaupe),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
