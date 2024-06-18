import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

import '../../../models/grocery.dart';
import '../../../utils/convert_util.dart';

class AnimatedShoppingList extends StatelessWidget {
  final List<Grocery> groceries;
  final void Function(Grocery) onTap;
  final void Function(Grocery) onEdit;
  final void Function(Grocery) onLongPress;

  final GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();

  AnimatedShoppingList({
    required this.groceries,
    required this.onTap,
    required this.onEdit,
    required this.onLongPress,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      key: listKey,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      initialItemCount: groceries.length,
      itemBuilder: (context, index, animation) {
        return _buildSlideTile(index, animation, context);
      },
    );
  }

  Widget _buildSlideTile(
      int index, Animation<double> animation, BuildContext context) {
    final Grocery grocery = groceries[index];

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(animation),
      child: InkWell(
        onTap: () => _tapItem(index),
        onLongPress: () => onLongPress(grocery),
        child: ListTile(
          title: Text(grocery.name!, style: const TextStyle(fontSize: 18.0)),
          subtitle: grocery.amount != null && grocery.amount != 0
              ? Text(ConvertUtil.amountToString(grocery.amount, grocery.unit))
              : null,
          trailing: IconButton(
            icon: const Icon(EvaIcons.moreHorizontalOutline),
            onPressed: () => onEdit(grocery),
          ),
          dense: true,
        ),
      ),
    );
  }

  void _tapItem(int index) {
    try {
      listKey.currentState!.removeItem(
        index,
        (ctx, animation) => _buildSlideTile(index, animation, ctx),
        duration: const Duration(milliseconds: 250),
      );
      // ignore: empty_catches
    } catch (e) {}

    Future<void>.delayed(
      const Duration(milliseconds: 250),
    ).then((_) {
      try {
        onTap(groceries.removeAt(index));
      } catch (e) {
        return;
      }
    });
  }
}
