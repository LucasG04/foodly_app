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
  void _syncWithNewList(List<Grocery> newList) {
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
            subtitle: grocery.amount != null && grocery.amount != 0
                ? Text(ConvertUtil.amountToString(grocery.amount, grocery.unit))
                : null,
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

  void _tapItem(int index) {
    if (index < 0 || index >= _groceries.length) {
      return;
    }

    // Remove immediately so the Firestore stream update finds nothing to diff,
    // preventing a double removeItem animation.
    final grocery = _groceries.removeAt(index);
    // Capture before onEmpty can trigger group removal and unmount this widget.
    final onTap = widget.onTap;

    _listKey.currentState?.removeItem(
      index,
      (ctx, animation) => _buildSlideTile(grocery, animation, ctx, curve: Curves.easeIn),
      duration: const Duration(milliseconds: 150),
    );

    Future<void>.delayed(const Duration(milliseconds: 150)).then((_) => onTap(grocery));

    if (_groceries.isEmpty) {
      widget.onEmpty?.call();
    }
  }
}
