import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

import '../../../models/grocery.dart';
import '../../../utils/convert_util.dart';

class AnimatedShoppingList extends StatefulWidget {
  final List<Grocery> groceries;
  final void Function(Grocery) onTap;
  final void Function(Grocery) onEdit;
  final void Function(Grocery) onLongPress;

  /// Called immediately when the last item is removed locally, before the
  /// Firestore round-trip. Allows the parent to start its own removal animation
  /// in sync with the last grocery's slide-out.
  final VoidCallback? onEmpty;

  const AnimatedShoppingList({
    required this.groceries,
    required this.onTap,
    required this.onEdit,
    required this.onLongPress,
    this.onEmpty,
    super.key,
  });

  @override
  State<AnimatedShoppingList> createState() => _AnimatedShoppingListState();
}

class _AnimatedShoppingListState extends State<AnimatedShoppingList> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  /// Single source of truth for [AnimatedList]'s item count. Kept in sync via
  /// [_tapItem] (tap-driven removals) and [didUpdateWidget] (stream updates).
  late List<Grocery> _groceries;

  /// Ids removed by [_tapItem] whose write hasn't reached the stream yet, so
  /// an unrelated update in between doesn't re-insert them.
  final Set<String?> _pendingRemovals = {};

  @override
  void initState() {
    super.initState();
    _groceries = List.of(widget.groceries);
  }

  @override
  void didUpdateWidget(AnimatedShoppingList oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncWithNewList(widget.groceries);
  }

  /// Diffs [_groceries] against [newList] and updates [AnimatedList] accordingly.
  void _syncWithNewList(List<Grocery> allGroceries) {
    // Once the stream drops a pending id its write has landed.
    _pendingRemovals.removeWhere((id) => !allGroceries.any((g) => g.id == id));
    final newList =
        allGroceries.where((g) => !_pendingRemovals.contains(g.id)).toList();

    // Remove items that are no longer in the new list (iterate in reverse to
    // keep indices stable as we remove).
    for (int i = _groceries.length - 1; i >= 0; i--) {
      final grocery = _groceries[i];
      if (!newList.any((g) => g.id == grocery.id)) {
        _groceries.removeAt(i);
        _listKey.currentState?.removeItem(
          i,
          (ctx, animation) =>
              _buildSlideTile(grocery, animation, ctx, curve: Curves.easeIn),
          duration: const Duration(milliseconds: 150),
        );
      }
    }

    for (int i = 0; i < newList.length; i++) {
      final grocery = newList[i];
      final existingIndex = _groceries.indexWhere((g) => g.id == grocery.id);
      if (existingIndex == -1) {
        _groceries.insert(i, grocery);
        _listKey.currentState?.insertItem(
          i,
          duration: const Duration(milliseconds: 150),
        );
      } else {
        // Update in place so edits (name, amount, unit) are reflected.
        _groceries[existingIndex] = grocery;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      key: _listKey,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      initialItemCount: _groceries.length,
      itemBuilder: (context, index, animation) {
        return _buildSlideTile(_groceries[index], animation, context);
      },
    );
  }

  Widget _buildSlideTile(
    Grocery grocery,
    Animation<double> animation,
    BuildContext context, {
    Curve curve = Curves.easeOut,
  }) {
    final curved = CurvedAnimation(parent: animation, curve: curve);
    return SizeTransition(
      sizeFactor: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(curved),
        child: InkWell(
          onTap: () => _tapItem(_groceries.indexOf(grocery)),
          onLongPress: () => widget.onLongPress(grocery),
          child: ListTile(
            title: Text(grocery.name!, style: const TextStyle(fontSize: 18.0)),
            subtitle: _buildSubtitle(grocery),
            trailing: IconButton(
              icon: const Icon(EvaIcons.moreHorizontalOutline),
              onPressed: () => widget.onEdit(grocery),
            ),
            dense: true,
          ),
        ),
      ),
    );
  }

  /// Amount and the meals the item is for, e.g. "400 g · Lasagne, Chili".
  Widget? _buildSubtitle(Grocery grocery) {
    final parts = [
      if (grocery.amount != null && grocery.amount != 0)
        ConvertUtil.amountToString(grocery.amount, grocery.unit),
      if (grocery.sources.isNotEmpty)
        grocery.sources.map((e) => e.mealName).join(', '),
    ];
    return parts.isEmpty
        ? null
        : Text(
            parts.join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
  }

  void _tapItem(int index) {
    if (index < 0 || index >= _groceries.length) {
      return;
    }

    // Remove immediately so the Firestore stream update finds nothing to diff,
    // preventing a double removeItem animation.
    final grocery = _groceries.removeAt(index);
    _pendingRemovals.add(grocery.id);

    _listKey.currentState?.removeItem(
      index,
      (ctx, animation) =>
          _buildSlideTile(grocery, animation, ctx, curve: Curves.easeIn),
      duration: const Duration(milliseconds: 150),
    );

    // Write right away: Firestore's local cache then drops the item from the
    // stream before any later update, even if onEmpty unmounts this widget.
    widget.onTap(grocery);

    if (_groceries.isEmpty) {
      widget.onEmpty?.call();
    }
  }
}
