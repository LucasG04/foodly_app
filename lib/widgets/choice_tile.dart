import 'package:flutter/material.dart';

import '../constants.dart';

/// A choice tile, filled with the primary color when [selected]. [builder]
/// gets the matching content color. Lay several out with [ChoiceTileGrid].
class ChoiceTile extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final List<Widget> Function(Color color) builder;

  const ChoiceTile({
    required this.selected,
    required this.onTap,
    required this.builder,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    return Semantics(
      selected: selected,
      child: Material(
        color:
            selected ? theme.primaryColor : textColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(kRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(kRadius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: kPadding / 2,
              horizontal: kPadding / 4,
            ),
            child: Column(
              children: builder(selected ? Colors.white : textColor),
            ),
          ),
        ),
      ),
    );
  }
}

/// Equal-width [tiles], [columns] per row.
class ChoiceTileGrid extends StatelessWidget {
  final List<Widget> tiles;
  final int columns;

  const ChoiceTileGrid(this.tiles, {this.columns = 4, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var row = 0; row < tiles.length; row += columns)
          Padding(
            padding: EdgeInsets.only(top: row == 0 ? 0 : kPadding / 2),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = row; i < row + columns; i++) ...[
                    if (i > row) const SizedBox(width: kPadding / 2),
                    Expanded(
                      child: i < tiles.length ? tiles[i] : const SizedBox(),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
