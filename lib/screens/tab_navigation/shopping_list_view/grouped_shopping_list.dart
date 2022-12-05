import 'package:flutter/material.dart';
import 'package:sticky_headers/sticky_headers.dart';

import '../../../models/grocery.dart';
import 'animated_shopping_list.dart';

class GroupedShoppingList extends StatefulWidget {
  final List<ShoppingListGroup> groups;
  final void Function(Grocery) onTap;
  final void Function(Grocery) onEdit;
  final ScrollController? pageScrollController;

  const GroupedShoppingList({
    required this.groups,
    required this.onTap,
    required this.onEdit,
    this.pageScrollController,
    Key? key,
  }) : super(key: key);

  @override
  State<GroupedShoppingList> createState() => _GroupedShoppingListState();
}

class _GroupedShoppingListState extends State<GroupedShoppingList> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.groups.length,
      itemBuilder: (context, index) {
        final ShoppingListGroup group = widget.groups[index];
        return group.groceries.isEmpty
            ? const SizedBox()
            : StickyHeader(
                controller: widget.pageScrollController,
                header: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      ListTile(
                        dense: true,
                        title: Text(
                          group.name,
                          style: const TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                content: AnimatedShoppingList(
                  groceries: group.groceries,
                  onTap: widget.onTap,
                  onEdit: widget.onEdit,
                ),
              );
      },
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
