import 'dart:async';
import 'package:flutter/widgets.dart';
import '../theme/pixel_colors.dart';
import '../theme/pixel_text.dart';

/// Global toast host — matches the prototype's bottom-center `{{ toast }}`
/// pill (`background:#201e1d;color:#ffe1d0;border:3px solid #c67139`).
/// Wrap the app body in a [PixelToastHost] once and call
/// `PixelToastHost.of(context).show(msg)` from anywhere below it.
class PixelToastHost extends StatefulWidget {
  final Widget child;
  const PixelToastHost({super.key, required this.child});

  static PixelToastHostState of(BuildContext context) {
    final state = context.findAncestorStateOfType<PixelToastHostState>();
    assert(state != null, 'No PixelToastHost found in context');
    return state!;
  }

  @override
  State<PixelToastHost> createState() => PixelToastHostState();
}

class PixelToastHostState extends State<PixelToastHost> {
  String? _message;
  Timer? _timer;

  void show(String message, {Duration duration = const Duration(milliseconds: 1900)}) {
    _timer?.cancel();
    setState(() => _message = message);
    _timer = Timer(duration, () {
      if (mounted) setState(() => _message = null);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_message != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 88,
            child: IgnorePointer(
              child: Center(
                child: AnimatedOpacity(
                  opacity: 1,
                  duration: const Duration(milliseconds: 160),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: PixelColors.inkBorder,
                      border: Border.all(color: PixelColors.accent, width: 3),
                    ),
                    child: Text(
                      _message!,
                      style: PixelText.style(size: 11, color: PixelColors.accentPale),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
