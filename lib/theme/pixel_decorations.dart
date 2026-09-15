import 'package:flutter/widgets.dart';
import 'pixel_colors.dart';

/// The prototype's whole visual language is: solid background, a hard
/// 2-4px ink border, and a hard (unblurred, unspread) drop shadow offset
/// straight down — e.g. `border:3px solid #201e1d;box-shadow:0 4px 0
/// #201e1d`. A `BoxShadow` with `blurRadius: 0` reproduces that exactly.
BoxDecoration pixelBox({
  required Color background,
  Color border = PixelColors.inkBorder,
  double borderWidth = 3,
  Color? shadowColor = PixelColors.inkBorder,
  double shadowOffset = 4,
  double angleDeg = 0,
}) {
  return BoxDecoration(
    color: background,
    border: Border.all(color: border, width: borderWidth),
    boxShadow: shadowColor == null
        ? null
        : [
            BoxShadow(
              color: shadowColor,
              offset: Offset(0, shadowOffset),
              blurRadius: 0,
              spreadRadius: 0,
            ),
          ],
  );
}

/// A postit-style shadow: soft-alpha, diagonal, with a slight rotation
/// applied by the caller via [Transform.rotate] — matches
/// `box-shadow:5px 5px 0 rgba(32,30,29,.28)` on postit annotations.
BoxDecoration pixelPostitBox({required Color background}) {
  return BoxDecoration(
    color: background,
    border: Border.all(color: PixelColors.inkBorder, width: 3),
    boxShadow: const [
      BoxShadow(
        color: Color(0x47201E1D),
        offset: Offset(5, 5),
        blurRadius: 0,
        spreadRadius: 0,
      ),
    ],
  );
}

const double kPixelHairline = 2;
const double kPixelBorder = 3;
const double kPixelBorderThick = 4;
