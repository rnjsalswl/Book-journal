import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';

import '../../theme/pixel_colors.dart';
import 'stations.dart';

/// Deterministic pseudo-random in [0,1) — matches `hash(a,b)` in the
/// prototype script, used to scatter book-spine widths/colors on shelves
/// so they look hand-placed instead of uniform.
double pixelHash(double a, double b) {
  final n = (a * 12.9898 + b * 78.233).clamp(-1e6, 1e6).toDouble();
  final s = n * 43758.5453;
  return s - s.floorToDouble();
}

/// Drives the library-map side-scroller: player position, walk animation,
/// and which station (if any) is close enough to interact with. A plain
/// `ChangeNotifier` ticked once per frame so the `CustomPainter` can repaint
/// without the surrounding widget tree rebuilding — matches the
/// prototype's `requestAnimationFrame` loop.
class MapGameState extends ChangeNotifier {
  double px = 120;
  int dir = 1;
  bool walking = false;
  int tick = 0;
  MapWorldTheme theme = MapWorldTheme.wood;
  bool blocked = false;

  bool _left = false;
  bool _right = false;
  Ticker? _ticker;
  Duration _last = Duration.zero;

  void start(TickerProvider vsync) {
    _ticker?.dispose();
    _ticker = vsync.createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final dtMs = (elapsed - _last).inMilliseconds;
    _last = elapsed;
    tick++;

    var moved = false;
    if (!blocked) {
      final step = 1.6 * (dtMs <= 0 ? 1 : dtMs / 16.0);
      if (_left) {
        px -= step;
        dir = -1;
        moved = true;
      }
      if (_right) {
        px += step;
        dir = 1;
        moved = true;
      }
    }
    px = px.clamp(14, kWorldWidth - 14).toDouble();
    walking = moved;
    notifyListeners();
  }

  void setLeft(bool v) => _left = v;
  void setRight(bool v) => _right = v;

  Station? nearest() {
    Station? best;
    var bestDist = 999.0;
    for (final s in kStations) {
      final d = (s.x - px).abs();
      if (d < bestDist) {
        bestDist = d;
        best = s;
      }
    }
    return bestDist < 40 ? best : null;
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }
}
