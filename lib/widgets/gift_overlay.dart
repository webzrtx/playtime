import 'package:flutter/material.dart';
import 'package:svgaplayer_flutter/svgaplayer_flutter.dart';
import '../models/gift_model.dart';

/// Fullscreen SVGA gift animation overlay.
/// Falls back to emoji-only animation for gifts without an SVGA file.
class GiftOverlay extends StatefulWidget {
  final GiftItem gift;
  final String senderName;

  const GiftOverlay({super.key, required this.gift, required this.senderName});

  static void show(BuildContext context,
      {required GiftItem gift, String sender = 'Someone'}) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _GiftOverlayWidget(
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

class _GiftOverlayState extends State<GiftOverlay> {
  @override
  Widget build(BuildContext context) =>
      const SizedBox.expand(child: SizedBox.shrink());
}

/// The actual animated overlay.
class _GiftOverlayWidget extends StatefulWidget {
  final GiftItem gift;
  final String sender;
  final VoidCallback onComplete;

  const _GiftOverlayWidget({
    required this.gift,
    required this.sender,
    required this.onComplete,
  });

  @override
  State<_GiftOverlayWidget> createState() => _GiftOverlayWidgetState();
}

class _GiftOverlayWidgetState extends State<_GiftOverlayWidget>
    with SingleTickerProviderStateMixin {
  SVGAAnimationController? _svgaCtrl;
  MovieEntity? _movie;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.gift.svgaPath != null) {
      _svgaCtrl = SVGAAnimationController(vsync: this);
      _loadSvga();
    } else {
      // No SVGA — use simple emoji fallback with timer
      Future.delayed(const Duration(milliseconds: 2200), widget.onComplete);
    }
  }

  Future<void> _loadSvga() async {
    try {
      final movie =
          await SVGAParser.shared.decodeFromAssets(widget.gift.svgaPath!);
      if (!mounted) return;
      _movie = movie;
      _svgaCtrl!.videoItem = movie;
      _svgaCtrl!
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) widget.onComplete();
        })
        ..forward();
      setState(() => _loading = false);
    } catch (e) {
      debugPrint('[GiftOverlay] SVGA load failed: $e');
      if (mounted) {
        setState(() => _loading = false);
        Future.delayed(const Duration(milliseconds: 2200), widget.onComplete);
      }
    }
  }

  @override
  void dispose() {
    _svgaCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // SVGA path
    if (widget.gift.svgaPath != null) {
      if (_loading || _movie == null) {
        return const SizedBox.expand(
          child: Center(child: CircularProgressIndicator(color: Colors.white54)),
        );
      }
      return SizedBox.expand(
        child: Stack(
          children: [
            // Sender label at the bottom
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.15,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${widget.sender} sent ${widget.gift.label}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            // SVGA animation centered
            Center(
              child: SVGAImage(
                _svgaCtrl!,
                fit: BoxFit.contain,
                clearsAfterStop: true,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ],
        ),
      );
    }

    // Fallback: simple emoji float-up animation
    return _EmojiFallback(
      emoji: widget.gift.emoji,
      sender: widget.sender,
      giftLabel: widget.gift.label,
      onComplete: widget.onComplete,
    );
  }
}

/// Emoji-only fallback animation (used when no SVGA file is available).
class _EmojiFallback extends StatefulWidget {
  final String emoji;
  final String sender;
  final String giftLabel;
  final VoidCallback onComplete;

  const _EmojiFallback({
    required this.emoji,
    required this.sender,
    required this.giftLabel,
    required this.onComplete,
  });

  @override
  State<_EmojiFallback> createState() => _EmojiFallbackState();
}

class _EmojiFallbackState extends State<_EmojiFallback>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<double> _translateY;
  late final Animation<double> _scale;
  final double _startX =
      (DateTime.now().millisecondsSinceEpoch % 200 - 100).toDouble();

  @override
  void initState() {
    super.initState();
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

    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onComplete();
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
      builder: (_, __) => Stack(
        children: [
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.35,
            left: MediaQuery.of(context).size.width / 2 -
                60 +
                _startX * (1 - _ctrl.value),
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
                        Text(widget.emoji,
                            style: const TextStyle(fontSize: 48)),
                        const SizedBox(height: 6),
                        Text(
                          '${widget.sender} sent ${widget.giftLabel}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
