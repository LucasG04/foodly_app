import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:foodly/models/grocery.dart';

class AnimatedShoppingList extends StatefulWidget {
  final List<Grocery> groceries;
  final void Function(Grocery) onRemove;

  AnimatedShoppingList({
    @required this.groceries,
    @required this.onRemove,
  });

  @override
  _AnimatedShoppingListState createState() => _AnimatedShoppingListState();
}

class _AnimatedShoppingListState extends State<AnimatedShoppingList> {
  GlobalKey<AnimatedListState> listKey = new GlobalKey<AnimatedListState>();

  @override
  Widget build(BuildContext context) {
    // widget.groceries.addAll([
    //   Grocery(name: 'Bier'),
    //   Grocery(name: 'Lachschinken'),
    //   Grocery(name: 'Zucchini'),
    //   Grocery(name: 'Flasche Korn'),
    //   Grocery(name: 'Chips'),
    //   Grocery(name: 'Halm'),
    //   Grocery(name: 'Birne'),
    //   Grocery(name: 'Apfel'),
    // ]);
    print(widget.groceries.length);
    return AnimatedList(
      key: listKey,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      initialItemCount: widget.groceries.length,
      itemBuilder: (context, index, animation) {
        return _buildSlideTile(context, index, animation);
      },
    );
  }

  Widget _buildSlideTile(BuildContext context, int index, animation) {
    Grocery grocery = widget.groceries[index];

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset(0, 0),
      ).animate(animation),
      child: InkWell(
        onTap: () => _removeItem(index),
        child: ListTile(
          title: Text(grocery.name, style: TextStyle(fontSize: 20.0)),
          trailing: IconButton(
            icon: Icon(EvaIcons.moreHorizotnalOutline),
            onPressed: () => print('edit grocery'),
          ),
        ),
      ),
    );
  }

  void _addItem(Grocery item) {
    listKey.currentState.insertItem(
      widget.groceries.length + 1,
      duration: const Duration(milliseconds: 250),
    );
    final existingGroceries = widget.groceries;
    widget.groceries.clear();
    widget.groceries.addAll(existingGroceries);
    widget.groceries.add(item);
  }

  void _removeItem(int index) {
    listKey.currentState.removeItem(
      index,
      (_, animation) => _buildSlideTile(context, index, animation),
      duration: const Duration(milliseconds: 250),
    );

    Future.delayed(
      const Duration(milliseconds: 250),
    ).then((_) => widget.groceries.removeAt(index));
  }
}
