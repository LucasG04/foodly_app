import 'package:auto_route/auto_route.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/src/provider.dart';
import 'package:flutter_snake_navigationbar/flutter_snake_navigationbar.dart';
import 'package:foodly/providers/state_providers.dart';
import 'package:foodly/services/shopping_list_service.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import '../../app_router.gr.dart';
import 'meal_list_view/meal_list_view.dart';
import 'plan_view/plan_tab_view.dart';
import 'settings_view/settings_view.dart';
import 'shopping_list_view/edit_grocery_modal.dart';
import 'shopping_list_view/shopping_list_view.dart';

class TabNavigationView extends StatefulWidget {
  @override
  _TabNavigationViewState createState() => _TabNavigationViewState();
}

class _TabNavigationViewState extends State<TabNavigationView> {
  PageController _pageController = new PageController(initialPage: 1);
  int _currentIndex = 1;
  bool _navbarAnimating = false;

  String _activeListId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: BouncingScrollPhysics(),
          onPageChanged: (value) {
            if (!_navbarAnimating) {
              setState(() {
                _currentIndex = value;
              });
            }
          },
          children: [
            ShoppingListView(),
            PlanTabView(),
            MealListView(),
            SettingsView(),
          ],
        ),
      ),
      floatingActionButton: _showActionButton()
          ? FloatingActionButton(
              child: Icon(EvaIcons.plusOutline),
              onPressed: () {
                switch (_currentIndex) {
                  case 0:
                    _newGrocery();
                    break;
                  case 2:
                    _openMealCreate();
                    break;
                  default:
                    break;
                }
              },
            )
          : null,
      bottomNavigationBar: SnakeNavigationBar.color(
        currentIndex: _currentIndex,
        onTap: (value) async {
          setState(() {
            _currentIndex = value;
            _navbarAnimating = true;
          });

          await _pageController.animateToPage(
            value,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeIn,
          );
          _navbarAnimating = false;
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
          ),
          BottomNavigationBarItem(
            icon: Icon(EvaIcons.settings2Outline),
            label: 'settings',
          ),
        ],
      ),
    );
  }

  bool _showActionButton() {
    if (!_pageController.hasClients) {
      return false;
    }

    return _currentIndex == 0 || _currentIndex == 2;
  }

  void _newGrocery() async {
    if (_activeListId == null) {
      final planId = context.read(planProvider).state.id;
      final list = await ShoppingListService.getShoppingListByPlanId(planId);
      _activeListId = list.id;
    }

    showBarModalBottomSheet(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(10.0),
        ),
      ),
      context: context,
      builder: (modalContext) => EditGroceryModal(
        shoppingListId: _activeListId,
      ),
    );
  }

  void _openMealCreate() {
    context.router.push(MealCreateScreenRoute(id: 'create'));
  }
}
