import 'package:flutter/material.dart';

/// Voice activity indicator — pulsing halo around speaking avatars.
///
/// Renders concentric animated rings + subtle scale pulse when [isSpeaking].
/// Intensity scales with [volume] (0–100). Fades out over ~400ms when silent.
class SpeakingAvatar extends StatefulWidget {
  final Widget child;
  final bool isSpeaking;
  final int volume;
  final double size;
  final Color glowColor;

  const SpeakingAvatar({
    super.key,
    required this.child,
    required this.isSpeaking,
    this.volume = 0,
    this.size = 64,
    this.glowColor = Colors.greenAccent,
  });

  @override
  State<SpeakingAvatar> createState() => _SpeakingAvatarState();
}

class _SpeakingAvatarState extends State<SpeakingAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (widget.isSpeaking) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(SpeakingAvatar old) {
    super.didUpdateWidget(old);
    if (widget.isSpeaking && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.isSpeaking && _ctrl.isAnimating) {
      // Fade out gracefully
      _ctrl.stop();
      _ctrl.reverse().then((_) {
        if (mounted) _ctrl.value = 0;
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double _intensity() {
    final v = widget.volume.clamp(0, 100);
    if (v <= 5) return 0.0;
    if (v >= 60) return 1.0;
    return (v - 5) / 55.0; // 0.0 → 1.0 for 5–60
  }

  @override
  Widget build(BuildContext context) {
    final intensity = _intensity();
    final isActive = widget.isSpeaking && intensity > 0;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value; // 0.0 → 1.0 looping
        final scale = isActive ? 1.0 + (0.06 + intensity * 0.06) * t : 1.0;
        final outerOpacity = isActive ? (0.3 + intensity * 0.4) * (1.0 - t) : 0.0;
        final midOpacity = isActive ? (0.15 + intensity * 0.25) * (1.0 - t * 0.6) : 0.0;

        return SizedBox(
          width: widget.size * 1.4,
          height: widget.size * 1.4,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ripple ring
              IgnorePointer(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 400),
                  opacity: outerOpacity,
                  child: Transform.scale(
                    scale: 0.7 + t * 0.6,
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.glowColor.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Mid glow
              IgnorePointer(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 400),
                  opacity: midOpacity,
                  child: Container(
                    width: widget.size * 1.05,
                    height: widget.size * 1.05,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.glowColor.withOpacity(intensity * 0.6),
                          blurRadius: 12 + intensity * 8,
                          spreadRadius: 1 + intensity * 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Avatar with scale
              Transform.scale(
                scale: scale,
                child: child!,
              ),
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}
