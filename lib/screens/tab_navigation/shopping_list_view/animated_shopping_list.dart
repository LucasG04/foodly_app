import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../models/grocery.dart';
import '../../../utils/convert_util.dart';

class AnimatedShoppingList extends StatelessWidget {
  final List<Grocery> groceries;
  final void Function(Grocery) onTap;
  final void Function(Grocery) onDelete;
  final void Function(Grocery) onEdit;

  final GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();

  AnimatedShoppingList({
    @required this.groceries,
    @required this.onTap,
    @required this.onDelete,
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
        return _buildSlideTile(index, animation, context);
      },
    );
  }

  Widget _buildSlideTile(int index, animation, context) {
    Grocery grocery = groceries[index];

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset(0, 0),
      ).animate(animation),
      child: InkWell(
        onTap: () => _tapItem(index),
        child: Slidable(
          actionPane: SlidableDrawerActionPane(),
          child: ListTile(
            title: Text(grocery.name, style: TextStyle(fontSize: 18.0)),
            subtitle: grocery.amount != null && grocery.amount != 0
                ? Text(ConvertUtil.amountToString(grocery.amount, grocery.unit))
                : null,
            trailing: IconButton(
              icon: Icon(EvaIcons.moreHorizotnalOutline),
              onPressed: () => onEdit(grocery),
            ),
            dense: true,
          ),
          secondaryActions: [
            IconSlideAction(
              caption: 'delete'.tr(),
              color: Theme.of(context).errorColor,
              icon: EvaIcons.closeCircleOutline,
              onTap: () => _deleteItem(index),
            ),
          ],
        ),
      ),
    );
  }

  void _tapItem(int index) {
    listKey.currentState.removeItem(
      index,
      (ctx, animation) => _buildSlideTile(index, animation, ctx),
      duration: const Duration(milliseconds: 250),
    );

    Future.delayed(
      const Duration(milliseconds: 250),
    ).then((_) => onTap(groceries.removeAt(index)));
  }

  void _deleteItem(int index) {
    listKey.currentState.removeItem(
      index,
      (ctx, animation) => _buildSlideTile(index, animation, ctx),
      duration: const Duration(milliseconds: 250),
    );

    Future.delayed(
      const Duration(milliseconds: 250),
    ).then((_) => onDelete(groceries.removeAt(index)));
  }
}
