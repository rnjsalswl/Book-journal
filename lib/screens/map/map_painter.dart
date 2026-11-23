import 'package:flutter/rendering.dart';

import '../../theme/pixel_colors.dart';
import 'map_game_state.dart';
import 'pixel_sprites.dart';
import 'stations.dart';

/// Virtual resolution the whole scene is composed at (matches the
/// prototype's `<canvas width="240" height="300">`), then scaled up to
/// fill the widget — vector fills stay crisp at any scale, so this keeps
/// the exact pixel-art proportions without needing a bitmap.
const double kVirtualW = 240;
const double kVirtualH = 300;
const double kGroundY = 212;

class MapPainter extends CustomPainter {
  final MapGameState game;
  const MapPainter(this.game) : super(repaint: game);

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / kVirtualW;
    final scaleY = size.height / kVirtualH;
    canvas.save();
    canvas.scale(scaleX, scaleY);

    final t = game.theme;
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = t.wall;
    canvas.drawRect(const Rect.fromLTWH(0, 0, kVirtualW, kVirtualH), paint);

    final cam = (game.px - kVirtualW / 2).round().toDouble().clamp(0, kWorldWidth - kVirtualW).toDouble();
    canvas.save();
    canvas.translate(-cam, 0);

    paint.color = t.wallHi;
    canvas.drawRect(const Rect.fromLTWH(0, 0, kWorldWidth, 14), paint);
    paint.color = PixelColors.inkBorder;
    canvas.drawRect(const Rect.fromLTWH(0, 14, kWorldWidth, 2), paint);
    paint.color = const Color(0x17201E1D);
    for (double x = 0; x < kWorldWidth; x += 8) {
      canvas.drawRect(Rect.fromLTWH(x, 16, 1, kGroundY - 16), paint);
    }

    // hanging lamps + light pools
    for (double x = 60; x < kWorldWidth; x += 124) {
      paint.color = PixelColors.inkBorder;
      canvas.drawRect(Rect.fromLTWH(x, 0, 2, 20), paint);
      paint.color = t.lamp;
      canvas.drawRect(Rect.fromLTWH(x - 5, 20, 12, 5), paint);
      paint.color = t.glow;
      canvas.drawRect(Rect.fromLTWH(x - 24, 25, 50, kGroundY - 25), paint);
    }

    // upper gallery (decorative tier)
    for (final s in kStations) {
      if (s.kind != StationKind.table) _drawShelf(canvas, paint, s.x, t, s.x + 9, 44);
    }
    paint.color = t.wain;
    canvas.drawRect(const Rect.fromLTWH(0, 106, kWorldWidth, 11), paint);
    paint.color = t.shelfHi;
    canvas.drawRect(const Rect.fromLTWH(0, 106, kWorldWidth, 2), paint);
    paint.color = PixelColors.inkBorder;
    canvas.drawRect(const Rect.fromLTWH(0, 115, kWorldWidth, 2), paint);
    for (double x = 4; x < kWorldWidth; x += 10) {
      paint.color = t.shelfHi;
      canvas.drawRect(Rect.fromLTWH(x, 96, 2, 10), paint);
    }
    paint.color = t.shelfHi;
    canvas.drawRect(const Rect.fromLTWH(0, 94, kWorldWidth, 2), paint);

    // main tier
    for (final s in kStations) {
      if (s.kind == StationKind.shelf) _drawShelf(canvas, paint, s.x, t, s.x, 146);
      if (s.kind == StationKind.npc) {
        drawPixelSprite(canvas, kLibrarianSprite, s.x - 8, 172, scale: 2);
        paint.color = t.shelf;
        canvas.drawRect(Rect.fromLTWH(s.x - 26, 196, 54, 16), paint);
        paint.color = t.shelfHi;
        canvas.drawRect(Rect.fromLTWH(s.x - 26, 196, 54, 3), paint);
        paint.color = PixelColors.inkBorder;
        canvas.drawRect(Rect.fromLTWH(s.x - 26, 209, 54, 3), paint);
        paint.color = PixelColors.mossDeep;
        canvas.drawRect(Rect.fromLTWH(s.x + 12, 189, 8, 7), paint);
        paint.color = PixelColors.paperFaint;
        canvas.drawRect(Rect.fromLTWH(s.x - 22, 191, 11, 5), paint);
        paint.color = t.lamp;
        canvas.drawRect(Rect.fromLTWH(s.x - 20, 150, 40, 3), paint);
        paint.color = PixelColors.inkBorder;
        canvas.drawRect(Rect.fromLTWH(s.x - 20, 153, 40, 2), paint);
      }
      if (s.kind == StationKind.table) {
        paint.color = t.shelfHi;
        canvas.drawRect(Rect.fromLTWH(s.x - 28, 188, 56, 5), paint);
        paint.color = PixelColors.inkBorder;
        canvas.drawRect(Rect.fromLTWH(s.x - 24, 193, 4, 19), paint);
        canvas.drawRect(Rect.fromLTWH(s.x + 20, 193, 4, 19), paint);
        paint.color = PixelColors.accent;
        canvas.drawRect(Rect.fromLTWH(s.x - 20, 181, 12, 7), paint);
        paint.color = PixelColors.phoneBg;
        canvas.drawRect(Rect.fromLTWH(s.x - 5, 184, 14, 4), paint);
        paint.color = PixelColors.mossDeep;
        canvas.drawRect(Rect.fromLTWH(s.x + 13, 178, 7, 10), paint);
        paint.color = t.lamp;
        canvas.drawRect(Rect.fromLTWH(s.x - 3, 150, 6, 5), paint);
        paint.color = PixelColors.inkBorder;
        canvas.drawRect(Rect.fromLTWH(s.x - 1, 138, 2, 12), paint);
      }
      if (s.kind != StationKind.table) {
        paint.color = PixelColors.inkBorder;
        canvas.drawRect(Rect.fromLTWH(s.x - 18, 136, 36, 8), paint);
        paint.color = t.lamp;
        canvas.drawRect(Rect.fromLTWH(s.x - 17, 137, 34, 6), paint);
      }
    }

    // floor
    paint.color = t.floor;
    canvas.drawRect(Rect.fromLTWH(0, kGroundY, kWorldWidth, kVirtualH - kGroundY), paint);
    paint.color = t.floorHi;
    canvas.drawRect(const Rect.fromLTWH(0, kGroundY, kWorldWidth, 3), paint);
    paint.color = const Color(0x33201E1D);
    for (double x = 0; x < kWorldWidth; x += 15) {
      canvas.drawRect(Rect.fromLTWH(x, kGroundY + 3, 1, kVirtualH - kGroundY - 3), paint);
    }
    paint.color = const Color(0x23201E1D);
    canvas.drawRect(const Rect.fromLTWH(0, kGroundY + 28, kWorldWidth, 2), paint);
    paint.color = const Color(0x19201E1D);
    canvas.drawRect(const Rect.fromLTWH(0, kGroundY + 58, kWorldWidth, 2), paint);

    final near = game.nearest();
    if (near != null) {
      final yy = near.kind == StationKind.shelf ? 126.0 : 156.0;
      paint.color = const Color(0xE6FFC6A5);
      canvas.drawRect(
        Rect.fromLTWH(near.x - 2, yy + ((game.tick ~/ 18) % 2 != 0 ? 0 : 3), 5, 5),
        paint,
      );
    }

    final bob = game.walking && (game.tick ~/ 7) % 2 != 0 ? 1.0 : 0.0;
    paint.color = const Color(0x42201E1D);
    canvas.drawRect(Rect.fromLTWH(game.px.roundToDouble() - 9, kGroundY + 2, 18, 3), paint);
    drawPixelSprite(
      canvas,
      kPlayerSprite,
      game.px.roundToDouble() - 8,
      kGroundY - kPlayerSprite.length * 2 + bob,
      flip: game.dir < 0,
      scale: 2,
    );

    canvas.restore();
    canvas.restore();
  }

  void _drawShelf(Canvas canvas, Paint paint, double x, MapWorldTheme t, double seed, double top) {
    const h = 62.0, w = 74.0;
    final left = x - w / 2;
    paint.color = t.shelf;
    canvas.drawRect(Rect.fromLTWH(left, top, w, h), paint);
    paint.color = t.shelfHi;
    canvas.drawRect(Rect.fromLTWH(left, top, w, 3), paint);
    canvas.drawRect(Rect.fromLTWH(left, top, 3, h), paint);
    paint.color = PixelColors.inkBorder;
    canvas.drawRect(Rect.fromLTWH(left, top + h - 3, w, 3), paint);

    for (var row = 0; row < 3; row++) {
      final by = top + 6 + row * 19;
      paint.color = PixelColors.inkBorder;
      canvas.drawRect(Rect.fromLTWH(left + 3, by + 15, w - 6, 2), paint);
      var bx = left + 5;
      var i = 0;
      while (bx < left + w - 7) {
        final r1 = pixelHash(seed + row * 7.3, i * 3.1);
        final bw = 2 + (r1 * 3).floor();
        final bh = 11 + (pixelHash(seed + i, row.toDouble()) * 4).floor();
        final spineIdx = (pixelHash(seed * 1.7 + i, row * 2.3) * PixelColors.spines.length).floor();
        paint.color = PixelColors.spines[spineIdx.clamp(0, PixelColors.spines.length - 1).toInt()];
        canvas.drawRect(Rect.fromLTWH(bx, by + 15 - bh, bw.toDouble(), bh.toDouble()), paint);
        paint.color = const Color(0x80FFF2EB);
        canvas.drawRect(Rect.fromLTWH(bx, by + 15 - bh + 3, bw.toDouble(), 1), paint);
        bx += bw + 1;
        i++;
      }
    }
  }

  @override
  bool shouldRepaint(covariant MapPainter oldDelegate) => true;
}
