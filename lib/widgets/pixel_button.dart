import 'package:flutter/widgets.dart';
import 'package:flutter/gestures.dart';
import '../theme/pixel_colors.dart';
import '../theme/pixel_decorations.dart';
import '../theme/pixel_text.dart';

/// A button in the prototype's "hard border + offset shadow" style. The
/// shadow collapses and the button nudges down by [shadowOffset] while
/// pressed, so tapping reads as physically depressing a key — the tactile
/// feel the D-pad/A button art implies.
class PixelButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final GestureTapDownCallback? onTapDown;
  final GestureTapUpCallback? onTapUp;
  final GestureTapCancelCallback? onTapCancel;
  final Color background;
  final Color foreground;
  final double borderWidth;
  final double shadowOffset;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;
  final BorderRadiusGeometry? borderRadius;

  const PixelButton({
    super.key,
    required this.child,
    this.onTap,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.background = PixelColors.paper,
    this.foreground = PixelColors.textPrimary,
    this.borderWidth = kPixelBorder,
    this.shadowOffset = 3,
    this.padding = EdgeInsets.zero,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: widget.background,
      border: Border.all(color: PixelColors.inkBorder, width: widget.borderWidth),
      borderRadius: widget.borderRadius,
      boxShadow: widget.shadowOffset <= 0
          ? null
          : [
              BoxShadow(
                color: PixelColors.inkBorder,
                offset: Offset(0, _pressed ? 0 : widget.shadowOffset),
                blurRadius: 0,
              ),
            ],
    );

    return Listener(
      onPointerDown: (_) {
        _setPressed(true);
        widget.onTapDown?.call(TapDownDetails());
      },
      onPointerUp: (_) {
        _setPressed(false);
        widget.onTapUp?.call(TapUpDetails(kind: PointerDeviceKind.touch));
      },
      onPointerCancel: (_) {
        _setPressed(false);
        widget.onTapCancel?.call();
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 60),
          width: widget.width,
          height: widget.height,
          padding: widget.padding,
          transform: Matrix4.translationValues(
            0,
            _pressed && widget.shadowOffset > 0 ? widget.shadowOffset : 0,
            0,
          ),
          decoration: decoration,
          alignment: Alignment.center,
          // `width: double.infinity` here (not on the AnimatedContainer
          // itself) makes the button's content span the button's full
          // width while keeping height intrinsic — Align (from the
          // `alignment` above) otherwise gives children loose constraints,
          // so a Column child would shrink to its own width instead of
          // filling card-style buttons (book tiles, list rows).
          child: SizedBox(
            width: double.infinity,
            child: DefaultTextStyle.merge(
              style: PixelText.style(color: widget.foreground),
              textAlign: TextAlign.center,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
