import 'dart:async';
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import '../models/image_credit.dart';

/// Attribution for stock photos, shown as a small "i" button. First tap
/// expands it to the credit, second tap opens [ImageCredit.link]. Collapses
/// again on outside tap or after [_autoCollapse]. Renders nothing without a
/// credit.
class ImageCreditChip extends StatefulWidget {
  final ImageCredit? credit;

  const ImageCreditChip(this.credit, {super.key});

  @override
  State<ImageCreditChip> createState() => _ImageCreditChipState();
}

class _ImageCreditChipState extends State<ImageCreditChip>
    with SingleTickerProviderStateMixin {
  static const _size = 28.0;
  static const _autoCollapse = Duration(seconds: 4);

  late final AnimationController _controller;
  late final Animation<double> _width;
  late final Animation<double> _opacity;
  late final Animation<double> _iconSwap;
  late final Animation<double> _iconPop;
  Timer? _collapseTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _width = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    // Text fades in once there is room for it and out before the pill shrinks.
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 1, curve: Curves.easeOut),
      reverseCurve: const Interval(0.4, 1, curve: Curves.easeIn),
    );
    // "i" turns and shrinks away while the link arrow turns in and pops.
    _iconSwap = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _iconPop = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInBack,
    );
  }

  bool get _expanded =>
      _controller.status == AnimationStatus.forward ||
      _controller.status == AnimationStatus.completed;

  @override
  void dispose() {
    _collapseTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onTap(ImageCredit credit) {
    if (!_expanded) {
      _controller.forward();
      _collapseTimer?.cancel();
      _collapseTimer = Timer(_autoCollapse, _collapse);
      return;
    }
    launchUrl(Uri.parse(credit.link));
    _collapse();
  }

  void _collapse() {
    _collapseTimer?.cancel();
    if (mounted && _expanded) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final credit = widget.credit;
    if (credit == null) {
      return const SizedBox.shrink();
    }
    final name = credit.name;
    final label = name == null
        ? credit.source
        : '${'image_credit_photo_by'.tr(args: [name])} · ${credit.source}';
    const color = Colors.white;

    final pill = ClipRRect(
      borderRadius: BorderRadius.circular(kRadius * 1.25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.35),
          child: SizedBox(
            height: _size,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Flexible: in narrow slots (e.g. the create-screen picker)
                // the label ellipsizes instead of overflowing the row.
                Flexible(
                  child: ClipRect(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (_, child) => Align(
                        alignment: Alignment.centerRight,
                        widthFactor: _width.value,
                        child: child,
                      ),
                      child: FadeTransition(
                        opacity: _opacity,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 220),
                            child: Text(
                              label,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: color,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox.square(
                  dimension: _size,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      FadeTransition(
                        opacity: ReverseAnimation(_iconSwap),
                        child: RotationTransition(
                          turns: Tween<double>(begin: 0, end: 0.25)
                              .animate(_iconSwap),
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 1, end: 0.4)
                                .animate(_iconSwap),
                            child: const Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: color,
                            ),
                          ),
                        ),
                      ),
                      FadeTransition(
                        opacity: _iconSwap,
                        child: RotationTransition(
                          turns: Tween<double>(begin: -0.25, end: 0)
                              .animate(_iconSwap),
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.4, end: 1)
                                .animate(_iconPop),
                            child: const Icon(
                              Icons.north_east_rounded,
                              size: 15,
                              color: color,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return TapRegion(
      onTapOutside: (_) => _collapse(),
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          // Opaque + on top of the stack: taps never reach the image below.
          behavior: HitTestBehavior.opaque,
          onTap: () => _onTap(credit),
          child: Padding(
            // Grows the hit target to 44px without enlarging the visual.
            padding: const EdgeInsets.all(8),
            child: RepaintBoundary(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                builder: (_, t, child) => Opacity(
                  opacity: t,
                  child: Transform.scale(scale: 0.85 + 0.15 * t, child: child),
                ),
                child: pill,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
