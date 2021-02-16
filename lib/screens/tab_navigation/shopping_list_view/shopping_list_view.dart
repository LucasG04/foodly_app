import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/all.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:foodly/models/grocery.dart';
import 'package:foodly/models/shopping_list.dart';
import 'package:foodly/providers/state_providers.dart';
import 'package:foodly/screens/tab_navigation/shopping_list_view/animated_shopping_list.dart';
import 'package:foodly/screens/tab_navigation/shopping_list_view/edit_grocery_modal.dart';
import 'package:foodly/services/shopping_list_service.dart';
import 'package:foodly/widgets/page_title.dart';
import 'package:foodly/widgets/small_circular_progress_indicator.dart';

import '../../../constants.dart';

class ShoppingListView extends StatefulWidget {
  @override
  _ShoppingListViewState createState() => _ShoppingListViewState();
}

class _ShoppingListViewState extends State<ShoppingListView> {
  List<Grocery> todoItems = [];
  List<Grocery> boughtItems = [];

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, watch, child) {
        final planId = watch(planProvider).state.id;
        return FutureBuilder<ShoppingList>(
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
                            child: PageTitle(text: 'Einkaufsliste'),
                          ),
                          AnimatedShoppingList(
                            groceries: todoItems,
                            onEdit: (e) => _editGrocery(listId, e),
                            onRemove: (item) {
                              item.bought = true;
                              ShoppingListService.updateGrocery(listId, item);
                            },
                          ),
                          SizedBox(height: kPadding),
                          ExpansionTile(
                            title: Text('BEREITS GEKAUFT'),
                            children: [
                              AnimatedShoppingList(
                                groceries: boughtItems,
                                onEdit: (e) => _editGrocery(listId, e),
                                onRemove: (item) {
                                  item.bought = false;
                                  ShoppingListService.updateGrocery(
                                      listId, item);
                                },
                              ),
                            ],
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
        );
      },
    );
  }

  void _editGrocery(String listId, Grocery grocery) {
    showModalBottomSheet(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(10.0),
        ),
      ),
      context: context,
      isScrollControlled: true,
      builder: (context) => EditGroceryModal(listId, grocery),
    );
  }
}
