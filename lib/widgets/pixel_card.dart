import 'package:flutter/widgets.dart';
import '../theme/pixel_colors.dart';
import '../theme/pixel_decorations.dart';

/// A flat panel in the "paper card, ink border, hard drop shadow" style
/// used for book tiles, feed cards, stat tiles, dialogue boxes, etc.
class PixelCard extends StatelessWidget {
  final Widget child;
  final Color background;
  final EdgeInsetsGeometry padding;
  final double borderWidth;
  final double shadowOffset;
  final Color? shadowColor;

  const PixelCard({
    super.key,
    required this.child,
    this.background = PixelColors.paper,
    this.padding = const EdgeInsets.all(11),
    this.borderWidth = kPixelBorder,
    this.shadowOffset = 4,
    this.shadowColor = PixelColors.inkBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: pixelBox(
        background: background,
        borderWidth: borderWidth,
        shadowOffset: shadowOffset,
        shadowColor: shadowColor,
      ),
      child: child,
    );
  }
}

/// A small square progress bar, matches the XP / reading-progress bars
/// (`height:10px;background:#dcd3c4;border:2px solid #201e1d` with a moss
/// fill inside).
class PixelProgressBar extends StatelessWidget {
  final double value; // 0..1
  final double height;
  final Color track;
  final Color fill;

  const PixelProgressBar({
    super.key,
    required this.value,
    this.height = 10,
    this.track = PixelColors.paperMuted,
    this.fill = PixelColors.moss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: track,
        border: Border.all(color: PixelColors.inkBorder, width: kPixelHairline),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value.clamp(0, 1).toDouble(),
        child: Container(color: fill),
      ),
    );
  }
}

/// The small square initial-avatar used for people throughout the app
/// (member row, feed cards, annotation authors, friend presence).
class PixelAvatarTag extends StatelessWidget {
  final String initial;
  final Color color;
  final double size;
  final double fontSize;

  const PixelAvatarTag({
    super.key,
    required this.initial,
    required this.color,
    this.size = 28,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: PixelColors.inkBorder, width: kPixelBorder),
      ),
      child: Text(
        initial,
        style: TextStyle(
          fontFamily: 'Galmuri11',
          fontSize: fontSize,
          color: PixelColors.accentCream,
        ),
      ),
    );
  }
}
