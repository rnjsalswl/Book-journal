import 'package:flutter/widgets.dart';

/// Palette lifted 1:1 from `Pixel Book Journal.dc.html` (the Claude Design
/// handoff prototype). Keep names close to how each hex was used there so
/// screens stay easy to cross-check against the source.
class PixelColors {
  PixelColors._();

  // App chrome
  static const canvasSurround = Color(0xFF2E2B25);
  static const phoneBg = Color(0xFFF5EAD8);
  static const inkBorder = Color(0xFF201E1D);
  static const frameShadow = Color(0xFF645C50);

  // Wood / bark browns (headers, nav, dialogue chrome)
  static const barkDark = Color(0xFF402310);
  static const barkMid = Color(0xFF643312);
  static const barkLight = Color(0xFF56422E);
  static const wood = Color(0xFF8C491A);
  static const woodLight = Color(0xFFB2622D);
  static const woodDeep = Color(0xFF474238);

  // Paper / cream surfaces
  static const paper = Color(0xFFF9F4ED);
  static const paperWarm = Color(0xFFEBDDC5);
  static const paperMuted = Color(0xFFDCD3C4);
  static const paperFaint = Color(0xFFC0B6A5);
  static const paperTaupe = Color(0xFFA19786);

  // Accent orange (CTA / selection / accent)
  static const accent = Color(0xFFC67139);
  static const accentSoft = Color(0xFFFFC6A5);
  static const accentPale = Color(0xFFFFE1D0);
  static const accentCream = Color(0xFFFFF2EB);

  // Moss green (positive / progress / primary action)
  static const moss = Color(0xFF8FA073);
  static const mossDeep = Color(0xFF56633F);
  static const mossMid = Color(0xFF728157);
  static const mossPale = Color(0xFFE1EECC);
  static const mossOnDark = Color(0xFFF0FAE1);
  static const heatLow = Color(0xFFEEE7DB);
  static const heatMid = Color(0xFFCCDBB2);

  // Text
  static const textPrimary = Color(0xFF201E1D);
  static const textMuted = Color(0xFF645C50);

  /// Named friends → avatar color, matches `PEOPLE` in the prototype script.
  static const Map<String, Color> people = {
    '민아': accent,
    '준호': mossDeep,
    '세연': wood,
    '도윤': mossMid,
  };

  /// Book spine colors, matches `SPINE` in the prototype script.
  static const List<Color> spines = [
    wood,
    mossDeep,
    barkMid,
    mossMid,
    barkDark,
    woodLight,
    woodDeep,
    moss,
    accent,
  ];

  /// Sprite pixel palette, matches `P_PAL` in the prototype script.
  static const Map<String, Color> spritePalette = {
    '0': inkBorder,
    '1': barkDark,
    '2': barkMid,
    '3': accentSoft,
    '4': wood,
    '5': accent,
    '6': woodDeep,
    '7': paperFaint,
    '8': mossDeep,
  };
}

/// Library map world themes — matches `THEMES` in the prototype script.
class MapWorldTheme {
  final String label;
  final Color wall;
  final Color wallHi;
  final Color wain;
  final Color floor;
  final Color floorHi;
  final Color shelf;
  final Color shelfHi;
  final Color lamp;
  final Color glow;

  const MapWorldTheme({
    required this.label,
    required this.wall,
    required this.wallHi,
    required this.wain,
    required this.floor,
    required this.floorHi,
    required this.shelf,
    required this.shelfHi,
    required this.lamp,
    required this.glow,
  });

  static const wood = MapWorldTheme(
    label: '원목 서관',
    wall: Color(0xFF56422E),
    wallHi: Color(0xFF6B5238),
    wain: Color(0xFF402310),
    floor: Color(0xFF8C491A),
    floorHi: Color(0xFFB2622D),
    shelf: Color(0xFF643312),
    shelfHi: Color(0xFF8C491A),
    lamp: Color(0xFFFFC6A5),
    glow: Color(0x24FFC6A5),
  );

  static const moonlight = MapWorldTheme(
    label: '달빛 서관',
    wall: Color(0xFF3B3A4E),
    wallHi: Color(0xFF4B4A63),
    wain: Color(0xFF272636),
    floor: Color(0xFF5B5C76),
    floorHi: Color(0xFF747590),
    shelf: Color(0xFF474238),
    shelfHi: Color(0xFF645C50),
    lamp: Color(0xFFE1EECC),
    glow: Color(0x1FE1EECC),
  );

  static const paper = MapWorldTheme(
    label: '종이 서관',
    wall: Color(0xFFA19786),
    wallHi: Color(0xFFC0B6A5),
    wain: Color(0xFF645C50),
    floor: Color(0xFFDCD3C4),
    floorHi: Color(0xFFEEE7DB),
    shelf: Color(0xFFC0B6A5),
    shelfHi: Color(0xFFDCD3C4),
    lamp: Color(0xFFFFF2EB),
    glow: Color(0x29FFF2EB),
  );

  static const all = [wood, moonlight, paper];

  static MapWorldTheme byLabel(String label) =>
      all.firstWhere((t) => t.label == label, orElse: () => wood);
}
