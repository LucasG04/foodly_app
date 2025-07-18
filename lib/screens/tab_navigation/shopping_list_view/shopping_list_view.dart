import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../constants.dart';
import '../../../models/grocery.dart';
import '../../../models/ingredient.dart';
import '../../../models/shopping_list_sort.dart';
import '../../../providers/data_provider.dart';
import '../../../providers/state_providers.dart';
import '../../../services/app_review_service.dart';
import '../../../services/settings_service.dart';
import '../../../services/shopping_list_service.dart';
import '../../../utils/basic_utils.dart';
import '../../../utils/convert_util.dart';
import '../../../utils/main_snackbar.dart';
import '../../../utils/of_context_mixin.dart';
import '../../../utils/permission_utils.dart';
import '../../../utils/widget_utils.dart';
import '../../../widgets/ingredient_edit_modal.dart';
import '../../../widgets/page_title.dart';
import '../../../widgets/small_circular_progress_indicator.dart';
import '../../../widgets/user_information.dart';
import 'animated_shopping_list.dart';
import 'edit_grocery_suggestion_sheet.dart';
import 'grouped_shopping_list.dart';

class ShoppingListView extends ConsumerStatefulWidget {
  const ShoppingListView({super.key});
  @override
  ConsumerState<ShoppingListView> createState() => _ShoppingListViewState();
}

class _ShoppingListViewState extends ConsumerState<ShoppingListView>
    with AutomaticKeepAliveClientMixin, OfContextMixin {
  final _scrollController = ScrollController();

  final shoppingListStreamProvider =
      StreamProvider.family<List<Grocery>, String>(
    (ref, shoppingListId) {
      return ShoppingListService.streamShoppingList(shoppingListId);
    },
  );

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer(
      builder: (context, ref, _) {
        final shoppingListId = ref.watch(shoppingListIdProvider);
        final groceryGroups = ref.watch(dataGroceryGroupsProvider);
        if (shoppingListId == null || groceryGroups == null) {
          return _buildLoader();
        }

        final shoppingListAsyncValue =
            ref.watch(shoppingListStreamProvider(shoppingListId));

        return shoppingListAsyncValue.when(
          data: (data) {
            final List<Grocery> todoItems =
                data.where((e) => !e.bought).toList();
            final List<Grocery> boughtItems =
                data.where((e) => e.bought).toList();
            boughtItems.sort(
              (a, b) => b.lastBoughtEdited.compareTo(a.lastBoughtEdited),
            );

            BasicUtils.afterBuild(() {
              // scroll one pixel up with _scrollController to avoid ui bug
              if (_scrollController.hasClients) {
                _scrollController.jumpTo(_scrollController.offset + 0.1);
              }
            });

            return _buildShoppingList(
              context,
              todoItems,
              boughtItems,
              shoppingListId,
            );
          },
          loading: () => _buildLoader(),
          // TODO: add better error message
          error: (error, stack) => _buildEmptyShoppingList(),
        );
      },
    );
  }

  SingleChildScrollView _buildShoppingList(BuildContext context,
      List<Grocery> todoItems, List<Grocery> boughtItems, String listId) {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        children: [
          const SizedBox(height: kPadding),
          _buildPageTitle(todoItems),
          if (todoItems.isEmpty && boughtItems.isEmpty)
            _buildEmptyShoppingList(),
          SizedBox(
            width: BasicUtils.contentWidth(
              context,
              smallMultiplier: 1,
            ),
            child: StreamBuilder(
                stream: SettingsService.streamShoppingListSort(),
                builder: (context, _) {
                  return StreamBuilder(
                      stream: SettingsService.streamProductGroupOrder(),
                      builder: (context, snapshot) {
                        if (SettingsService.shoppingListSort ==
                            ShoppingListSort.group) {
                          var groceriesWithGroups =
                              _groceriesToGroups(todoItems);
                          groceriesWithGroups =
                              _sortGroceriesWithGroups(groceriesWithGroups);
                          return GroupedShoppingList(
                            groups: groceriesWithGroups,
                            pageScrollController: _scrollController,
                            onEdit: (e) => _editGrocery(listId, e),
                            onTap: (item) => _removeBoughtGrocery(
                              listId,
                              item,
                              todoItems,
                              boughtItems,
                            ),
                            onLongPress: _editGrocerySuggestion,
                          );
                        }
                        return AnimatedShoppingList(
                          groceries: todoItems,
                          onEdit: (e) => _editGrocery(listId, e),
                          onTap: (item) => _removeBoughtGrocery(
                            listId,
                            item,
                            todoItems,
                            boughtItems,
                          ),
                          onLongPress: _editGrocerySuggestion,
                        );
                      });
                }),
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
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ).tr(),
                children: [
                  AnimatedShoppingList(
                    groceries: boughtItems,
                    onEdit: (e) => _editGrocery(listId, e),
                    onTap: (item) {
                      ShoppingListService.groceryToggleBought(
                        listId,
                        item,
                      );
                    },
                    onLongPress: _editGrocerySuggestion,
                  ),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        ShoppingListService.deleteAllBoughtGrocery(listId);
                      },
                      style: ButtonStyle(
                        shadowColor: WidgetStateProperty.all<Color>(
                          theme.colorScheme.error,
                        ),
                        overlayColor: WidgetStateProperty.all<Color>(
                          theme.colorScheme.error.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Text(
                        'shopping_list_remove_all',
                        style: TextStyle(
                          color: theme.colorScheme.error,
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
  }

  Padding _buildPageTitle(List<Grocery> todoItems) {
    return Padding(
      padding: const EdgeInsets.only(left: 5.0),
      child: PageTitle(
        text: 'shopping_list_title'.tr(),
        checkConnectivity: true,
        actions: [
          Builder(
            builder: (BuildContext ctx) => IconButton(
              onPressed: () => _shareList(todoItems, ctx),
              icon: const Icon(EvaIcons.shareOutline),
            ),
          ),
        ],
      ),
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

  List<ShoppingListGroup> _groceriesToGroups(List<Grocery> groceries) {
    final groceriesCopy = List.of(groceries);
    final groups = ref.read(dataGroceryGroupsProvider) ?? [];
    final uncategorized = groceriesCopy;
    final listGroups = groups.map(
      (group) {
        final items = groceriesCopy.where((g) => g.group == group.id).toList();
        items.sort((a, b) => (a.name ?? '')
            .toLowerCase()
            .compareTo((b.name ?? '').toLowerCase()));
        uncategorized.removeWhere((g) => items.contains(g));
        return ShoppingListGroup(
          groupId: group.id,
          name: group.name,
          groceries: items,
        );
      },
    ).toList();

    if (uncategorized.isEmpty) {
      return listGroups;
    }

    // handle uncategorized groceries
    final uncategorizedIndex =
        listGroups.indexWhere((element) => element.groupId == '99');
    if (uncategorizedIndex != -1) {
      listGroups[uncategorizedIndex].groceries.addAll(uncategorized);
      listGroups[uncategorizedIndex].groceries.sort((a, b) =>
          (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()));
    } else {
      uncategorized.sort((a, b) =>
          (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()));
      listGroups.add(
        ShoppingListGroup(
          groupId: 'null',
          name: 'shopping_list_uncategorized'.tr(),
          groceries: uncategorized,
        ),
      );
    }

    return listGroups;
  }

  List<ShoppingListGroup> _sortGroceriesWithGroups(
      List<ShoppingListGroup> groups) {
    final groupOrder = SettingsService.productGroupOrder;
    final List<ShoppingListGroup> sorted = [];
    for (final groupId in groupOrder) {
      final group = groups.firstWhere((e) => e.groupId == groupId);
      sorted.add(group);
    }

    final List<ShoppingListGroup> unSorted = groups
        .where((element) => !groupOrder.contains(element.groupId))
        .toList();
    return [...sorted, ...unSorted];
  }

  void _editGrocery(String listId, [Grocery? grocery]) async {
    final isCreating = grocery == null;
    await WidgetUtils.showFoodlyBottomSheet<Ingredient?>(
      context: context,
      builder: (_) => IngredientEditModal(
        ingredient: isCreating ? Ingredient() : grocery.toIngredient(),
        onSaved: (result) async {
          final updatedGrocery = Grocery.fromIngredient(result);
          if (isCreating) {
            await ShoppingListService.addGrocery(
              listId,
              updatedGrocery,
              BasicUtils.getActiveLanguage(context),
            );
          } else {
            updatedGrocery.id = grocery.id;
            await ShoppingListService.updateGrocery(
              listId,
              updatedGrocery,
              BasicUtils.getActiveLanguage(context),
            );
          }
        },
      ),
    );
  }

  void _shareList(List<Grocery> groceries, BuildContext ctx) {
    if (groceries.isEmpty) {
      MainSnackbar(
        message: 'shopping_list_share_error'.tr(),
        isError: true,
      ).show(ctx);
      return;
    }
    final shareText = SettingsService.shoppingListSort == ShoppingListSort.name
        ? _getShareTextSortByNames(groceries)
        : _getShareTextSortByGroups(groceries);
    final subject = shareText
        .substring(0, shareText.length > 50 ? 50 : shareText.length)
        .trim();
    final box = ctx.findRenderObject() as RenderBox?;
    final params = ShareParams(
      text: shareText,
      subject: '$subject...',
      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
    );
    SharePlus.instance.share(params);
  }

  String _getShareTextSortByNames(List<Grocery> groceries) {
    final list = groceries.map((e) {
      final amount = ConvertUtil.amountToString(e.amount, e.unit);
      return amount.isEmpty ? '- ${e.name}' : '- $amount ${e.name}';
    }).toList();
    return list.join('\n');
  }

  String _getShareTextSortByGroups(List<Grocery> groceries) {
    var groceriesWithGroups = _groceriesToGroups(groceries);
    groceriesWithGroups = _sortGroceriesWithGroups(groceriesWithGroups);
    groceriesWithGroups =
        groceriesWithGroups.where((e) => e.groceries.isNotEmpty).toList();
    final list = groceriesWithGroups.map((group) {
      final groupText = group.name;
      final items = group.groceries.map((e) {
        final amount = ConvertUtil.amountToString(e.amount, e.unit);
        return amount.isEmpty ? '- ${e.name}' : '- $amount ${e.name}';
      }).toList();
      return '$groupText\n${items.join('\n')}';
    }).toList();
    return list.join('\n\n');
  }

  void _removeBoughtGrocery(String listId, Grocery grocery, List<Grocery> items,
      List<Grocery> boughtItems) {
    AppReviewService.logGroceryBought(items.isEmpty);
    if (!SettingsService.removeBoughtImmediately) {
      ShoppingListService.groceryToggleBought(
        listId,
        grocery,
      );
      _checkBoughtItems(listId, boughtItems);
      return;
    }

    ShoppingListService.deleteGrocery(listId, grocery.id!);
    MainSnackbar(
      message: 'shopping_list_grocery_removed'.tr(args: [grocery.name!]),
      duration: 3,
      isCountdown: true,
      isDismissible: true,
      action: IconButton(
        icon: Icon(EvaIcons.undoOutline, color: theme.primaryColor),
        onPressed: () {
          ShoppingListService.addGrocery(
            listId,
            grocery,
            BasicUtils.getActiveLanguage(context),
          );
          Navigator.of(context).maybePop();
        },
      ),
    ).show(context);
  }

  void _checkBoughtItems(String listId, List<Grocery> boughtGroceries) {
    if (_shouldAskForRemovingOfBought(boughtGroceries.length)) {
      showDialog<void>(
        context: context,
        builder: (_) => Platform.isIOS || Platform.isMacOS
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
          child: Text(
            'shopping_dialog_action_cancel'.tr().toUpperCase(),
            style: TextStyle(color: theme.primaryColor),
          ),
        ),
        CupertinoDialogAction(
          onPressed: () {
            ShoppingListService.deleteAllBoughtGrocery(listId);
            Navigator.of(context).pop();
          },
          isDefaultAction: true,
          child: Text(
            'update_dialog_action_delete'.tr().toUpperCase(),
            style: TextStyle(color: theme.primaryColor),
          ),
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
          child: Text(
            'shopping_dialog_action_cancel'.tr(),
            style: TextStyle(color: theme.primaryColor),
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: Text(
            'update_dialog_action_delete'.tr(),
            style: TextStyle(color: theme.primaryColor),
          ),
          onPressed: () {
            ShoppingListService.deleteAllBoughtGrocery(listId);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  void _editGrocerySuggestion(Grocery grocery) {
    final user = ref.read(userProvider);
    if (!PermissionUtils.allowedToModerate(user)) {
      return;
    }
    WidgetUtils.showFoodlyBottomSheet<void>(
      context: context,
      builder: (_) {
        return EditGrocerySuggestionSheet(grocery: grocery);
      },
    );
  }
}
