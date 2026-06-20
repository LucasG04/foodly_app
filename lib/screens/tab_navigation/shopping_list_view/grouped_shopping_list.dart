import 'package:flutter/material.dart';
import 'package:sticky_headers/sticky_headers.dart';

import '../../../models/grocery.dart';
import 'animated_shopping_list.dart';

class GroupedShoppingList extends StatefulWidget {
  final List<ShoppingListGroup> groups;
  final void Function(Grocery) onTap;
  final void Function(Grocery) onEdit;
  final void Function(Grocery) onLongPress;
  final ScrollController? pageScrollController;

  const GroupedShoppingList({
    required this.groups,
    required this.onTap,
    required this.onEdit,
    required this.onLongPress,
    this.pageScrollController,
    super.key,
  });

  @override
  State<GroupedShoppingList> createState() => _GroupedShoppingListState();
}

class _GroupedShoppingListState extends State<GroupedShoppingList> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  /// Local list of non-empty groups — the source of truth for the AnimatedList's
  /// internal item count. Reconciled against [widget.groups] in [didUpdateWidget].
  late List<ShoppingListGroup> _groups;

  @override
  void initState() {
    super.initState();
    _groups = widget.groups.where((g) => g.groceries.isNotEmpty).toList();
  }

  @override
  void didUpdateWidget(GroupedShoppingList oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncWithNewGroups(
      widget.groups.where((g) => g.groceries.isNotEmpty).toList(),
    );
  }

  /// Called by [AnimatedShoppingList] via [onEmpty] when its last item is tapped,
  /// so the group exits in sync with the grocery animation before the Firestore round-trip.
  void _removeGroup(ShoppingListGroup group) {
    final index = _groups.indexWhere((g) => g.groupId == group.groupId);
    if (index == -1) {
      return;
    }
    _groups.removeAt(index);
    _listKey.currentState?.removeItem(
      index,
      (ctx, animation) => _buildGroupExitTile(group, animation, ctx),
      duration: const Duration(milliseconds: 150),
    );
  }

  /// Header-only exit tile — omits [AnimatedShoppingList] to prevent Flutter
  /// from reusing state via [ValueKey] and triggering a spurious [insertItem].
  Widget _buildGroupExitTile(
      ShoppingListGroup group, Animation<double> animation, BuildContext context) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeIn);
    return SizeTransition(
      sizeFactor: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(curved),
        child: StickyHeader(
          controller: widget.pageScrollController,
          header: _buildGroupHeader(group, context),
          content: const SizedBox(),
        ),
      ),
    );
  }

  Widget _buildGroupHeader(ShoppingListGroup group, BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListTile(
        dense: true,
        title: Text(
          group.name,
          style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _syncWithNewGroups(List<ShoppingListGroup> newGroups) {
    // Reverse iteration keeps indices stable as we remove.
    // Groups already removed via [_removeGroup] are gone, so no double-removal.
    for (int i = _groups.length - 1; i >= 0; i--) {
      final group = _groups[i];
      if (!newGroups.any((g) => g.groupId == group.groupId)) {
        _groups.removeAt(i);
        _listKey.currentState?.removeItem(
          i,
          (ctx, animation) => _buildGroupExitTile(group, animation, ctx),
          duration: const Duration(milliseconds: 150),
        );
      }
    }

    for (int i = 0; i < newGroups.length; i++) {
      final group = newGroups[i];
      final existingIndex = _groups.indexWhere((g) => g.groupId == group.groupId);
      if (existingIndex == -1) {
        _groups.insert(i, group);
        _listKey.currentState?.insertItem(i, duration: const Duration(milliseconds: 150));
      } else {
        _groups[existingIndex] = group;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      key: _listKey,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      initialItemCount: _groups.length,
      itemBuilder: (context, index, animation) {
        return _buildGroupTile(_groups[index], animation, context);
      },
    );
  }

  Widget _buildGroupTile(
      ShoppingListGroup group, Animation<double> animation, BuildContext context) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
    return SizeTransition(
      sizeFactor: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(curved),
        child: StickyHeader(
          controller: widget.pageScrollController,
          header: _buildGroupHeader(group, context),
          content: AnimatedShoppingList(
            key: ValueKey(group.groupId),
            groceries: group.groceries,
            onTap: widget.onTap,
            onEdit: widget.onEdit,
            onLongPress: widget.onLongPress,
            onEmpty: () => _removeGroup(group),
          ),
        ),
      ),
    );
  }
}

class ShoppingListGroup {
  final String name;
  final String groupId;
  final List<Grocery> groceries;

  ShoppingListGroup({
    required this.name,
    required this.groupId,
    required this.groceries,
  });
}
