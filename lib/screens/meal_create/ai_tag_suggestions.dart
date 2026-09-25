import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../utils/tag_candidates.dart';
import '../../widgets/tag_chip.dart';

/// Sticky AI tag suggestions. While the AI works: skeleton chips with
/// shimmering labels; then sparkle-marked chips that toggle in place.
/// Collapses when there's nothing to suggest or while [hidden].
class AiTagSuggestions extends StatelessWidget {
  final Future<List<String>>? suggestions;
  final List<String> selected;
  final ValueChanged<String> onToggle;
  final String semanticsLabel;
  final bool hidden;

  const AiTagSuggestions({
    required this.suggestions,
    required this.selected,
    required this.onToggle,
    this.semanticsLabel = '',
    this.hidden = false,
    super.key,
  });

  static const _collapsed = SizedBox(width: double.infinity);

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: MediaQuery.of(context).disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: suggestions == null
          ? _collapsed
          : FutureBuilder<List<String>>(
              future: suggestions,
              // Stays mounted while hidden, so un-hiding doesn't reload.
              builder: (context, snapshot) {
                if (hidden) {
                  return _collapsed;
                }
                if (snapshot.connectionState != ConnectionState.done) {
                  return _wrap(const [
                    _PlaceholderChips(key: ValueKey('ai-tags-loading')),
                  ]);
                }
                final tags = snapshot.data ?? const <String>[];
                if (tags.isEmpty) {
                  return _collapsed;
                }
                final selectedKeys = selected.map(normalizeTag).toSet();
                return _wrap([
                  for (final (i, tag) in tags.indexed)
                    _FadeIn(
                      key: ValueKey('fade-$tag'),
                      delay: Duration(milliseconds: 40 * i),
                      child: TagChip(
                        key: ValueKey('ai-tag-$tag'),
                        label: tag,
                        style: TagChipStyle.suggested,
                        selected: selectedKeys.contains(normalizeTag(tag)),
                        onTap: () => onToggle(tag),
                      ),
                    ),
                ]);
              },
            ),
    );
  }

  Widget _wrap(List<Widget> children) {
    return Semantics(
      container: true,
      label: semanticsLabel,
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(top: kPadding / 2),
        child: Wrap(
          spacing: kPadding / 2,
          runSpacing: kPadding / 2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: children,
        ),
      ),
    );
  }
}

/// Loading skeletons: real suggested chips whose labels are shimmering boxes.
class _PlaceholderChips extends StatefulWidget {
  const _PlaceholderChips({super.key});

  @override
  State<_PlaceholderChips> createState() => _PlaceholderChipsState();
}

class _PlaceholderChipsState extends State<_PlaceholderChips>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: Wrap(
          spacing: kPadding / 2,
          runSpacing: kPadding / 2,
          children: [
            for (final width in const [44.0, 68.0, 52.0])
              TagChip(
                label: '',
                style: TagChipStyle.suggested,
                onTap: () {},
                placeholder: _ShimmerBox(width: width, animation: _controller),
              ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double width;
  final Animation<double> animation;

  const _ShimmerBox({required this.width, required this.animation});

  @override
  Widget build(BuildContext context) {
    final base = Colors.grey.shade300;
    final highlight = Colors.grey.shade100;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => Container(
        width: width,
        height: 12,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          gradient: LinearGradient(
            colors: [base, highlight, base],
            stops: const [0.35, 0.5, 0.65],
            begin: Alignment(-3 + 4 * animation.value, 0),
            end: Alignment(-1 + 4 * animation.value, 0),
          ),
        ),
      ),
    );
  }
}

class _FadeIn extends StatelessWidget {
  final Duration delay;
  final Widget child;
  const _FadeIn({required this.delay, required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return child;
    }
    final total = 200 + delay.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(
        delay.inMilliseconds / total,
        1,
        curve: Curves.easeOutCubic,
      ),
      builder: (_, t, c) => Opacity(
        opacity: t,
        child: Transform.scale(scale: 0.94 + 0.06 * t, child: c),
      ),
      child: child,
    );
  }
}
