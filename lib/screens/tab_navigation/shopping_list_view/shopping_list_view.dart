import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../constants.dart';
import '../../../models/grocery.dart';
import '../../../models/shopping_list.dart';
import '../../../providers/state_providers.dart';
import '../../../services/settings_service.dart';
import '../../../services/shopping_list_service.dart';
import '../../../utils/basic_utils.dart';
import '../../../utils/main_snackbar.dart';
import '../../../utils/widget_utils.dart';
import '../../../widgets/page_title.dart';
import '../../../widgets/small_circular_progress_indicator.dart';
import '../../../widgets/user_information.dart';
import 'animated_shopping_list.dart';
import 'edit_grocery_modal.dart';

class ShoppingListView extends StatefulWidget {
  const ShoppingListView({Key? key}) : super(key: key);
  @override
  State<ShoppingListView> createState() => _ShoppingListViewState();
}

class _ShoppingListViewState extends State<ShoppingListView>
    with AutomaticKeepAliveClientMixin {
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
                  if (!shoppingListSnap.hasData) {
                    return _buildLoader();
                  }

                  final listId = shoppingListSnap.data!.id!;
                  return StreamBuilder<List<Grocery>>(
                    stream: ShoppingListService.streamShoppingList(listId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return _buildLoader();
                      }
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
                            if (todoItems.isEmpty && boughtItems.isEmpty)
                              _buildEmptyShoppingList(),
                            SizedBox(
                              width: BasicUtils.contentWidth(
                                context,
                                smallMultiplier: 1,
                              ),
                              child: AnimatedShoppingList(
                                groceries: todoItems,
                                onEdit: (e) => _editGrocery(listId, e),
                                onTap: (item) => _removeBoughtGrocery(
                                    listId, item, boughtItems),
                              ),
                            ),
                            const SizedBox(height: kPadding),
                            if (boughtItems.isNotEmpty)
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
                                    Center(
                                      child: TextButton(
                                        onPressed: () => ShoppingListService
                                            .deleteAllBoughtGrocery(listId),
                                        style: ButtonStyle(
                                          shadowColor:
                                              MaterialStateProperty.all<Color>(
                                            Theme.of(context).errorColor,
                                          ),
                                          overlayColor:
                                              MaterialStateProperty.all<Color>(
                                            Theme.of(context)
                                                .errorColor
                                                .withOpacity(0.1),
                                          ),
                                        ),
                                        child: Text(
                                          'shopping_list_remove_all',
                                          style: TextStyle(
                                            color: Theme.of(context).errorColor,
                                          ),
                                        ).tr(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              )
            : _buildLoader();
      },
    );
  }

  Widget _buildLoader() {
    return const Center(
      child: SmallCircularProgressIndicator(),
    );
  }

  Widget _buildEmptyShoppingList() {
    return UserInformation(
      assetPath: 'assets/images/undraw_empty_cart.png',
      message: 'shopping_list_empty_subtitle'.tr(),
    );
  }

  void _editGrocery(String listId, [Grocery? grocery]) {
    WidgetUtils.showFoodlyBottomSheet<void>(
      context: context,
      builder: (_) => EditGroceryModal(
        shoppingListId: listId,
        grocery: grocery,
      ),
    );
  }

  void _shareList(List<Grocery> groceries) {
    if (groceries.isEmpty) {
      MainSnackbar(
        message: 'shopping_list_share_error'.tr(),
        isError: true,
      ).show(context);
      return;
    }
    final list = groceries
        .map((e) => e.amount == null
            ? '- ${e.name}'
            : e.unit == null
                ? '- ${e.amount} ${e.name}'
                : '- ${e.amount} ${e.unit} ${e.name}')
        .toList();
    final listAsString = list.join('\n');
    Share.share(listAsString, subject: listAsString);
  }

  void _removeBoughtGrocery(
      String listId, Grocery grocery, List<Grocery> boughtItems) {
    if (!SettingsService.removeBoughtImmediately) {
      grocery.bought = true;
      ShoppingListService.updateGrocery(listId, grocery);
      _checkBoughtItems(listId, boughtItems);
      return;
    }

    ShoppingListService.deleteGrocery(listId, grocery.id!);
    MainSnackbar(
      message: 'shopping_list_grocery_removed'.tr(args: [grocery.name!]),
      seconds: 3,
      isCountdown: true,
      action: IconButton(
        icon: Icon(EvaIcons.undoOutline, color: Theme.of(context).primaryColor),
        onPressed: () {
          ShoppingListService.addGrocery(listId, grocery);
          Navigator.of(context).maybePop();
        },
      ),
    ).show(context);
  }

  void _checkBoughtItems(String listId, List<Grocery> boughtGroceries) {
    if (_shouldAskForRemovingOfBought(boughtGroceries.length)) {
      showDialog<void>(
        context: context,
        builder: (_) => Platform.isIOS
            ? _buildIOSAlertDialog(listId)
            : _buildAlertDialog(listId),
      );
    }
  }

  bool _shouldAskForRemovingOfBought(int amount) {
    return amount > 49 && amount % 10 == 0;
  }

  CupertinoAlertDialog _buildIOSAlertDialog(String listId) {
    return CupertinoAlertDialog(
      title: Text('shopping_dialog_title'.tr()),
      content: Column(
        children: [
          const SizedBox(height: kPadding / 2),
          Text('shopping_dialog_description'.tr()),
          const SizedBox(height: kPadding / 4),
          Text('shopping_dialog_settings_info'.tr()),
        ],
      ),
      actions: <Widget>[
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('shopping_dialog_action_cancel'.tr().toUpperCase()),
        ),
        CupertinoDialogAction(
          onPressed: () {
            ShoppingListService.deleteAllBoughtGrocery(listId);
            Navigator.of(context).pop();
          },
          isDefaultAction: true,
          child: Text('update_dialog_action_delete'.tr().toUpperCase()),
        ),
      ],
    );
  }

  AlertDialog _buildAlertDialog(String listId) {
    return AlertDialog(
      title: Text('shopping_dialog_title'.tr()),
      content: Column(
        children: [
          const SizedBox(height: kPadding / 2),
          Text('shopping_dialog_description'.tr()),
          const SizedBox(height: kPadding / 4),
          Text('shopping_dialog_settings_info'.tr()),
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: Text('shopping_dialog_action_cancel'.tr()),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: Text(
            'update_dialog_action_delete'.tr(),
            style: TextStyle(color: Theme.of(context).primaryColor),
          ),
          onPressed: () {
            ShoppingListService.deleteAllBoughtGrocery(listId);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
