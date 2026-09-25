import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

enum TagChipStyle { neutral, suggested, create }

/// The app's tag chip (FilterChip), used by `TagFilterModal` and the meal tag
/// picker. Suggested (AI) chips carry a sparkle, the create chip a plus.
class TagChip extends StatelessWidget {
  final String label;
  final bool selected;
  final TagChipStyle style;
  final VoidCallback onTap;

  /// Replaces the text label, e.g. a loading skeleton.
  final Widget? placeholder;

  const TagChip({
    required this.label,
    required this.onTap,
    this.selected = false,
    this.style = TagChipStyle.neutral,
    this.placeholder,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilterChip(
      // Selected chips all show just the checkmark.
      avatar: selected
          ? null
          : switch (style) {
              TagChipStyle.neutral => null,
              TagChipStyle.suggested =>
                Icon(Icons.auto_awesome_rounded, color: theme.primaryColor),
              TagChipStyle.create =>
                Icon(EvaIcons.plus, color: theme.primaryColor),
            },
      label: placeholder ??
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: selected ? Colors.white : Colors.black),
          ),
      backgroundColor:
          selected ? theme.primaryColor : theme.scaffoldBackgroundColor,
      selected: selected,
      selectedColor: theme.primaryColor,
      selectedShadowColor: theme.primaryColor.withValues(alpha: 0.3),
      checkmarkColor: Colors.white,
      onSelected: (_) => onTap(),
    );
  }
}
