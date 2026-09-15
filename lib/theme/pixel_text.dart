import 'package:flutter/widgets.dart';
import 'pixel_colors.dart';

/// Text styling — the prototype sets `font-family:'Galmuri11'` once on
/// `body` and otherwise only varies `font-size`/`color`, so this mirrors
/// that: one base style, callers override size/color/weight per spot.
class PixelText {
  PixelText._();

  static const _family = 'Galmuri11';

  static TextStyle base = const TextStyle(
    fontFamily: _family,
    fontSize: 12,
    color: PixelColors.textPrimary,
    height: 1.3,
  );

  static TextStyle style({
    double size = 12,
    Color color = PixelColors.textPrimary,
    FontWeight weight = FontWeight.normal,
    double? height,
    double? letterSpacing,
  }) {
    return base.copyWith(
      fontSize: size,
      color: color,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}
