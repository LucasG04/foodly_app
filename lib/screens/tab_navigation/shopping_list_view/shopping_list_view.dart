import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/all.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:foodly/models/grocery.dart';
import 'package:foodly/models/shopping_list.dart';
import 'package:foodly/providers/state_providers.dart';
import 'package:foodly/screens/tab_navigation/shopping_list_view/animated_shopping_list.dart';
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
        return StreamBuilder<ShoppingList>(
          stream: ShoppingListService.streamShoppingListByPlanId(planId),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              todoItems =
                  snapshot.data.groceries.where((e) => !e.bought).toList();
              boughtItems =
                  snapshot.data.groceries.where((e) => e.bought).toList();

              print('update');
              print('todo ' + todoItems.length.toString());
              print('update ' + boughtItems.length.toString());

              return SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: kPadding),
                    Padding(
                      padding: const EdgeInsets.only(left: 5.0),
                      child: PageTitle(text: 'Einkaufsliste'),
                    ),
                    // ListView.separated(
                    //   shrinkWrap: true,
                    //   physics: NeverScrollableScrollPhysics(),
                    //   itemCount: todoItems.length,
                    //   itemBuilder: (context, index) =>
                    //       _buildItemListTile(todoItems[index]),
                    //   separatorBuilder: (context, index) => Divider(),
                    // ),
                    AnimatedShoppingList(
                      groceries: todoItems,
                      onRemove: (item) {},
                    ),
                    SizedBox(height: kPadding),
                    ExpansionTile(
                      title: Text('BEREITS GEKAUFT'),
                      children: [
                        AnimatedShoppingList(
                          groceries: boughtItems,
                          onRemove: (item) {},
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
      },
    );
  }
}
