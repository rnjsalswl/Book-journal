import 'package:flutter/rendering.dart';
import '../../theme/pixel_colors.dart';

/// 8-wide pixel-art rows, one palette-index char per pixel. Matches
/// `PLAYER`/`LIBRARIAN`/`P_PAL` in the prototype script exactly.
const List<String> kPlayerSprite = [
  '..2222..',
  '.244442.',
  '.243342.',
  '.244442.',
  '..3333..',
  '.155551.',
  '15555551',
  '15555551',
  '.155551.',
  '.16..61.',
  '.166661.',
  '.16..61.',
  '.11..11.',
  '.00..00.',
];

const List<String> kLibrarianSprite = [
  '..2222..',
  '.277772.',
  '.273372.',
  '.277772.',
  '..3333..',
  '.188881.',
  '18888881',
  '18888881',
  '.188881.',
  '.18..81.',
  '.188881.',
  '.18..81.',
  '.11..11.',
  '.00..00.',
];

/// Draws one sprite into [canvas] at [x],[y] using [scale]-px "pixels".
/// [flip] mirrors it horizontally (matches the player facing left/right).
void drawPixelSprite(
  Canvas canvas,
  List<String> art,
  double x,
  double y, {
  bool flip = false,
  double scale = 1,
}) {
  final paint = Paint()..style = PaintingStyle.fill;
  for (var r = 0; r < art.length; r++) {
    final row = art[r];
    for (var c = 0; c < 8; c++) {
      final color = PixelColors.spritePalette[row[c]];
      if (color == null) continue;
      paint.color = color;
      final px = x + (flip ? 7 - c : c) * scale;
      final py = y + r * scale;
      canvas.drawRect(Rect.fromLTWH(px, py, scale, scale), paint);
    }
  }
}

/// Renders a sprite onto a small fixed-size image for use outside the map
/// canvas (profile avatar, librarian portrait in the dialogue box).
class PixelSpritePainter extends CustomPainter {
  final List<String> art;
  final double scale;

  const PixelSpritePainter({required this.art, this.scale = 2});

  @override
  void paint(Canvas canvas, Size size) {
    final artWidth = 8 * scale;
    final artHeight = art.length * scale;
    final ox = (size.width - artWidth) / 2;
    final oy = size.height - artHeight - scale;
    drawPixelSprite(canvas, art, ox, oy, scale: scale);
  }

  @override
  bool shouldRepaint(covariant PixelSpritePainter oldDelegate) =>
      oldDelegate.art != art || oldDelegate.scale != scale;
}
