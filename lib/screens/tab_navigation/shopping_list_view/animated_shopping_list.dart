import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

import '../../../models/grocery.dart';

class AnimatedShoppingList extends StatelessWidget {
  final List<Grocery> groceries;
  final void Function(Grocery) onRemove;
  final void Function(Grocery) onEdit;

  final GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();

  AnimatedShoppingList({
    @required this.groceries,
    @required this.onRemove,
    @required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      key: listKey,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      initialItemCount: groceries.length,
      itemBuilder: (context, index, animation) {
        return _buildSlideTile(index, animation);
      },
    );
  }

  Widget _buildSlideTile(int index, animation) {
    Grocery grocery = groceries[index];

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset(0, 0),
      ).animate(animation),
      child: InkWell(
        onTap: () => _removeItem(index),
        child: ListTile(
          title: Text(grocery.name, style: TextStyle(fontSize: 20.0)),
          subtitle: grocery.amount != null && grocery.amount.isNotEmpty
              ? Text(grocery.amount)
              : null,
          trailing: IconButton(
            icon: Icon(EvaIcons.moreHorizotnalOutline),
            onPressed: () => onEdit(grocery),
          ),
        ),
      ),
    );
  }

  // void _addItem(Grocery item) {
  //   listKey.currentState.insertItem(
  //     groceries.length + 1,
  //     duration: const Duration(milliseconds: 250),
  //   );
  //   final existingGroceries = groceries;
  //   groceries.clear();
  //   groceries.addAll(existingGroceries);
  //   groceries.add(item);
  // }

  void _removeItem(int index) {
    listKey.currentState.removeItem(
      index,
      (_, animation) => _buildSlideTile(index, animation),
      duration: const Duration(milliseconds: 250),
    );

    Future.delayed(
      const Duration(milliseconds: 250),
    ).then((_) => onRemove(groceries.removeAt(index)));
  }
}
