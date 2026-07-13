import 'dart:math';
import 'package:flutter/material.dart';
import '../models/gift_model.dart';

/// Overlay that shows floating gift animations.
/// Call [GiftOverlay.show] to trigger a gift.
class GiftOverlay extends StatefulWidget {
  final GiftItem gift;
  final String senderName;

  const GiftOverlay({super.key, required this.gift, required this.senderName});

  /// Show a gift animation on top of the current screen.
  static void show(BuildContext context, {required GiftItem gift, String sender = 'Someone'}) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => _GiftAnimation(
        gift: gift,
        sender: sender,
        onComplete: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }

  @override
  State<GiftOverlay> createState() => _GiftOverlayState();
}

class _GiftOverlayState extends State<GiftOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<double> _translateY;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _opacity = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.6, 1.0)),
    );
    _translateY = Tween(begin: 60.0, end: -200.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.3, end: 1.1), weight: 0.15),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 0.15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 0.7),
    ]).animate(_ctrl);

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(child: Container()); // stub — real animation is in _GiftAnimation
  }
}

/// Standalone animation widget (used as OverlayEntry builder).
class _GiftAnimation extends StatefulWidget {
  final GiftItem gift;
  final String sender;
  final VoidCallback onComplete;

  const _GiftAnimation({
    required this.gift,
    required this.sender,
    required this.onComplete,
  });

  @override
  State<_GiftAnimation> createState() => _GiftAnimationState();
}

class _GiftAnimationState extends State<_GiftAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<double> _translateY;
  late Animation<double> _scale;
  late double _startX;

  @override
  void initState() {
    super.initState();
    _startX = Random().nextDouble() * 200 - 100; // random horizontal offset

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _opacity = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.55, 1.0)),
    );
    _translateY = Tween(begin: 40.0, end: -280.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.2, end: 1.15), weight: 0.12),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 0.13),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 0.75),
    ]).animate(_ctrl);

    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onComplete();
    });

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Positioned(
          bottom: MediaQuery.of(context).size.height * 0.35,
          left: MediaQuery.of(context).size.width / 2 - 60 + _startX * (1 - _ctrl.value),
          child: IgnorePointer(
            child: Opacity(
              opacity: _opacity.value.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, _translateY.value),
                child: Transform.scale(
                  scale: _scale.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.gift.emoji, style: const TextStyle(fontSize: 48)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
