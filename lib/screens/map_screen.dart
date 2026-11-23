import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import '../theme/pixel_colors.dart';
import '../theme/pixel_text.dart';
import '../widgets/pixel_card.dart';
import '../widgets/pixel_toast.dart';
import 'map/map_game_state.dart';
import 'map/map_painter.dart';
import 'map/overlays.dart';
import 'map/stations.dart';
import 'review_screen.dart';

/// "서관" tab — the side-scrolling library map, matches
/// `data-screen-label="도서관 맵"` in the prototype.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

String _initials(String? name) {
  if (name == null || name.isEmpty) return '..';
  return name.length <= 2 ? name : name.substring(0, 2);
}

class _MapScreenState extends ConsumerState<MapScreen> with SingleTickerProviderStateMixin {
  late final MapGameState game;

  @override
  void initState() {
    super.initState();
    game = MapGameState();
    game.start(this);
  }

  @override
  void dispose() {
    game.dispose();
    super.dispose();
  }

  Future<void> _interact() async {
    final near = game.nearest();
    if (near == null) {
      PixelToastHost.of(context).show('가까이 가서 A를 눌러보세요');
      return;
    }
    if (near.kind == StationKind.npc) {
      game.blocked = true;
      await showLibrarianDialogue(context, ref);
      game.blocked = false;
    } else if (near.kind == StationKind.table) {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;
      final shelf = await ref.read(shelfRepositoryProvider).forUser(userId);
      final reading = shelf.where((e) => e.status == 'reading').toList();
      if (reading.isEmpty) {
        if (mounted) PixelToastHost.of(context).show('먼저 서가에서 읽고 있는 책을 골라주세요');
        return;
      }
      if (mounted) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReviewScreen(book: reading.first.book)));
      }
    } else {
      game.blocked = true;
      await showShelfBrowseSheet(context, ref, station: near);
      game.blocked = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final profileAsync = userId == null ? null : ref.watch(profileProvider(userId));
    final questAsync = userId == null ? null : ref.watch(activeQuestProvider(userId));
    final booksAsync = ref.watch(booksProvider);

    final profile = profileAsync?.value;

    String questText = '사서 모루에게 말을 걸어 오늘의 책을 받으세요';
    final quest = questAsync?.value;
    if (quest != null) {
      String? title;
      for (final b in booksAsync.value ?? const []) {
        if (b.id == quest.bookId) {
          title = b.title;
          break;
        }
      }
      questText = 'SF·판타지 서가에서 「${title ?? '오늘의 책'}」을 찾아 감상문을 남기세요';
    }

    return ColoredBox(
      color: PixelColors.barkDark,
      child: Column(
        children: [
          // top bar — avatar chip + level + XP
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: PixelColors.barkMid,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: PixelColors.accent,
                    border: Border.all(color: PixelColors.inkBorder, width: 3),
                  ),
                  child: Text(
                    _initials(profile?.displayName),
                    style: PixelText.style(size: 11, color: PixelColors.accentCream),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Lv.${profile?.level ?? 1} 책벌레', style: PixelText.style(size: 12, color: PixelColors.accentCream)),
                          Text(profile?.xpLabel ?? '0 / 200 XP', style: PixelText.style(size: 12, color: PixelColors.accentCream)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      PixelProgressBar(value: profile?.xpProgress ?? 0, height: 10, track: PixelColors.barkDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // quest banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: PixelColors.mossPale,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  color: PixelColors.mossDeep,
                  child: Text('퀘스트', style: PixelText.style(size: 10, color: PixelColors.mossOnDark)),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(questText, style: PixelText.style(size: 11, height: 1.5))),
              ],
            ),
          ),
          // world canvas
          Expanded(
            child: ColoredBox(
              color: PixelColors.inkBorder,
              child: Center(
                child: AspectRatio(
                  aspectRatio: kVirtualW / kVirtualH,
                  child: CustomPaint(painter: MapPainter(game), size: Size.infinite),
                ),
              ),
            ),
          ),
          // prompt bar
          ListenableBuilder(
            listenable: game,
            builder: (context, _) {
              final near = game.nearest();
              return Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 46),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: const BoxDecoration(
                  color: PixelColors.barkDark,
                  border: Border(top: BorderSide(color: PixelColors.inkBorder, width: 4)),
                ),
                child: Text(
                  near != null ? '${near.name} — A로 ${near.action}' : '◀ ▶ 로 서관을 걸어보세요',
                  textAlign: TextAlign.center,
                  style: PixelText.style(size: 11, color: PixelColors.accentPale, height: 1.5),
                ),
              );
            },
          ),
          // controls
          Container(
            color: PixelColors.barkLight,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _HoldButton(label: '◀', onHold: game.setLeft),
                    const SizedBox(width: 10),
                    _HoldButton(label: '▶', onHold: game.setRight),
                  ],
                ),
                Column(
                  children: [
                    _ActionButton(onTap: _interact),
                    const SizedBox(height: 6),
                    ListenableBuilder(
                      listenable: game,
                      builder: (context, _) => Text(
                        game.nearest()?.action ?? '조사',
                        style: PixelText.style(size: 10, color: PixelColors.paperMuted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HoldButton extends StatefulWidget {
  final String label;
  final ValueChanged<bool> onHold;
  const _HoldButton({required this.label, required this.onHold});

  @override
  State<_HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<_HoldButton> {
  bool _pressed = false;

  void _set(bool v) {
    widget.onHold(v);
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        width: 62,
        height: 62,
        alignment: Alignment.center,
        transform: Matrix4.translationValues(0, _pressed ? 5 : 0, 0),
        decoration: BoxDecoration(
          color: PixelColors.paperMuted,
          border: Border.all(color: PixelColors.inkBorder, width: 4),
          boxShadow: _pressed
              ? null
              : const [BoxShadow(color: PixelColors.inkBorder, offset: Offset(0, 5), blurRadius: 0)],
        ),
        child: Text(widget.label, style: PixelText.style(size: 18)),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final VoidCallback onTap;
  const _ActionButton({required this.onTap});

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 60),
          width: 72,
          height: 72,
          alignment: Alignment.center,
          transform: Matrix4.translationValues(0, _pressed ? 5 : 0, 0),
          decoration: BoxDecoration(
            color: PixelColors.moss,
            shape: BoxShape.circle,
            border: Border.all(color: PixelColors.inkBorder, width: 4),
            boxShadow: _pressed
                ? null
                : const [BoxShadow(color: PixelColors.inkBorder, offset: Offset(0, 5), blurRadius: 0)],
          ),
          child: Text('A', style: PixelText.style(size: 20, color: PixelColors.mossOnDark)),
        ),
      ),
    );
  }
}
