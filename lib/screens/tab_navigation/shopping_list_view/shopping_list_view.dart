import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/all.dart';
import 'package:foodly/utils/basic_utils.dart';

import '../../../constants.dart';
import '../../../models/grocery.dart';
import '../../../models/shopping_list.dart';
import '../../../providers/state_providers.dart';
import '../../../services/shopping_list_service.dart';
import '../../../widgets/page_title.dart';
import '../../../widgets/small_circular_progress_indicator.dart';
import 'animated_shopping_list.dart';
import 'edit_grocery_modal.dart';

class ShoppingListView extends StatefulWidget {
  @override
  _ShoppingListViewState createState() => _ShoppingListViewState();
}

class _ShoppingListViewState extends State<ShoppingListView>
    with AutomaticKeepAliveClientMixin {
  List<Grocery> todoItems = [];
  List<Grocery> boughtItems = [];

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer(
      builder: (context, watch, child) {
        final planId = watch(planProvider).state?.id;
        return planId != null
            ? FutureBuilder<ShoppingList>(
                future: ShoppingListService.getShoppingListByPlanId(planId),
                builder: (_, shoppingListSnap) {
                  if (shoppingListSnap.hasData) {
                    final listId = shoppingListSnap.data.id;
                    return StreamBuilder<List<Grocery>>(
                      stream: ShoppingListService.streamShoppingList(listId),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final List<Grocery> todoItems =
                              snapshot.data.where((e) => !e.bought).toList();
                          final List<Grocery> boughtItems =
                              snapshot.data.where((e) => e.bought).toList();

                          return SingleChildScrollView(
                            child: Column(
                              children: [
                                SizedBox(height: kPadding),
                                Padding(
                                  padding: const EdgeInsets.only(left: 5.0),
                                  child: PageTitle(
                                    text: 'Einkaufsliste',
                                    actions: [
                                      IconButton(
                                        icon: Icon(EvaIcons.plusCircleOutline),
                                        onPressed: () => _editGrocery(listId),
                                        splashRadius: 25.0,
                                      )
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: BasicUtils.contentWidth(
                                    context,
                                    smallMultiplier: 1,
                                  ),
                                  child: AnimatedShoppingList(
                                    groceries: todoItems,
                                    onEdit: (e) => _editGrocery(listId, e),
                                    onTap: (item) {
                                      item.bought = true;
                                      ShoppingListService.updateGrocery(
                                          listId, item);
                                    },
                                    onDelete: (item) {
                                      ShoppingListService.deleteGrocery(
                                          listId, item.id);
                                    },
                                  ),
                                ),
                                SizedBox(height: kPadding),
                                SizedBox(
                                  width: BasicUtils.contentWidth(
                                    context,
                                    smallMultiplier: 1,
                                  ),
                                  child: ExpansionTile(
                                    title: Text(
                                      'BEREITS GEKAUFT',
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    children: [
                                      AnimatedShoppingList(
                                        groceries: boughtItems,
                                        onEdit: (e) => _editGrocery(listId, e),
                                        onTap: (item) {
                                          item.bought = false;
                                          ShoppingListService.updateGrocery(
                                              listId, item);
                                        },
                                        onDelete: (item) {
                                          ShoppingListService.deleteGrocery(
                                              listId, item.id);
                                        },
                                      ),
                                      boughtItems.length > 0
                                          ? Center(
                                              child: TextButton(
                                                onPressed: () =>
                                                    ShoppingListService
                                                        .deleteAllBoughtGrocery(
                                                            listId),
                                                child: Text(
                                                  'Alle entfernen',
                                                  style: TextStyle(
                                                    color: Theme.of(context)
                                                        .errorColor,
                                                  ),
                                                ),
                                                style: ButtonStyle(
                                                  shadowColor:
                                                      MaterialStateProperty.all<
                                                          Color>(
                                                    Theme.of(context)
                                                        .errorColor,
                                                  ),
                                                  overlayColor:
                                                      MaterialStateProperty.all<
                                                          Color>(
                                                    Theme.of(context)
                                                        .errorColor
                                                        .withOpacity(0.1),
                                                  ),
                                                ),
                                              ),
                                            )
                                          : SizedBox(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else {
                          return Center(
                            child: SmallCircularProgressIndicator(),
                          );
                        }
                      },
                    );
                  } else {
                    return Center(
                      child: SmallCircularProgressIndicator(),
                    );
                  }
                },
              )
            : Center(child: SmallCircularProgressIndicator());
      },
    );
  }

  void _editGrocery(String listId, [Grocery grocery]) {
    showModalBottomSheet(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(10.0),
        ),
      ),
      isScrollControlled: true,
      context: context,
      builder: (modalContext) => EditGroceryModal(
        shoppingListId: listId,
        grocery: grocery,
      ),
    );
  }
}
