import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_snake_navigationbar/flutter_snake_navigationbar.dart';

import 'meal_list_view/meal_list_view.dart';
import 'plan_view/plan_tab_view.dart';
import 'shopping_list_view/shopping_list_view.dart';

class TabNavigationView extends StatefulWidget {
  @override
  _TabNavigationViewState createState() => _TabNavigationViewState();
}

class _TabNavigationViewState extends State<TabNavigationView> {
  PageController _pageController = new PageController(initialPage: 1);
  int _currentIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: NeverScrollableScrollPhysics(),
          children: [
            ShoppingListView(),
            PlanTabView(),
            MealListView(),
          ],
        ),
      ),
      bottomNavigationBar: SnakeNavigationBar.color(
        currentIndex: _currentIndex,
        onTap: (value) {
          setState(() {
            _currentIndex = value;
          });

          _pageController.animateToPage(
            value,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeIn,
          );
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(EvaIcons.shoppingBagOutline),
            label: 'shopping',
          ),
          BottomNavigationBarItem(
            icon: Icon(EvaIcons.homeOutline),
            label: 'home',
          ),
          BottomNavigationBarItem(
            icon: Icon(EvaIcons.bookOutline),
            label: 'meals',
          )
        ],
      ),
    );
  }
}
