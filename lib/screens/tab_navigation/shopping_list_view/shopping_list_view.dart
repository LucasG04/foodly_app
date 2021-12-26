import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:share/share.dart';

import '../../../constants.dart';
import '../../../models/grocery.dart';
import '../../../models/shopping_list.dart';
import '../../../providers/state_providers.dart';
import '../../../services/shopping_list_service.dart';
import '../../../utils/basic_utils.dart';
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
                    final listId = shoppingListSnap.data!.id!;
                    return StreamBuilder<List<Grocery>>(
                      stream: ShoppingListService.streamShoppingList(listId),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final List<Grocery> todoItems =
                              snapshot.data!.where((e) => !e.bought!).toList();
                          final List<Grocery> boughtItems =
                              snapshot.data!.where((e) => e.bought!).toList();

                          return SingleChildScrollView(
                            child: Column(
                              children: [
                                const SizedBox(height: kPadding),
                                Padding(
                                  padding: const EdgeInsets.only(left: 5.0),
                                  child: PageTitle(
                                    text: 'shopping_list_title'.tr(),
                                    actions: [
                                      IconButton(
                                        onPressed: () => _shareList(todoItems),
                                        icon: const Icon(EvaIcons.shareOutline),
                                      ),
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
                                  ),
                                ),
                                const SizedBox(height: kPadding),
                                SizedBox(
                                  width: BasicUtils.contentWidth(
                                    context,
                                    smallMultiplier: 1,
                                  ),
                                  child: ExpansionTile(
                                    title: Text(
                                      'shopping_list_already_bought',
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ).tr(),
                                    children: [
                                      AnimatedShoppingList(
                                        groceries: boughtItems,
                                        onEdit: (e) => _editGrocery(listId, e),
                                        onTap: (item) {
                                          item.bought = false;
                                          ShoppingListService.updateGrocery(
                                              listId, item);
                                        },
                                      ),
                                      if (boughtItems.isNotEmpty)
                                        Center(
                                          child: TextButton(
                                            onPressed: () => ShoppingListService
                                                .deleteAllBoughtGrocery(listId),
                                            style: ButtonStyle(
                                              shadowColor: MaterialStateProperty
                                                  .all<Color>(
                                                Theme.of(context).errorColor,
                                              ),
                                              overlayColor:
                                                  MaterialStateProperty.all<
                                                      Color>(
                                                Theme.of(context)
                                                    .errorColor
                                                    .withOpacity(0.1),
                                              ),
                                            ),
                                            child: Text(
                                              'shopping_list_remove_all',
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .errorColor,
                                              ),
                                            ).tr(),
                                          ),
                                        )
                                      else
                                        const SizedBox(),
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

  void _editGrocery(String listId, [Grocery? grocery]) {
    showBarModalBottomSheet<void>(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(10.0),
        ),
      ),
      context: context,
      builder: (modalContext) => EditGroceryModal(
        shoppingListId: listId,
        grocery: grocery,
      ),
    );
  }

  void _shareList(List<Grocery> groceries) {
    if (groceries.isEmpty) {
      return;
    }
    final list = groceries
        .map((e) => e.amount == null
            ? '\n- ${e.name}'
            : e.unit == null
                ? '\n- ${e.amount} ${e.name}'
                : '\n- ${e.amount} ${e.unit} ${e.name}')
        .toList();
    Share.share(list.join());
  }
}
