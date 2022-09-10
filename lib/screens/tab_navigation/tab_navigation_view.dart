import 'package:auto_route/auto_route.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
// ignore: implementation_imports
import 'package:flutter_riverpod/src/provider.dart';
import 'package:flutter_snake_navigationbar/flutter_snake_navigationbar.dart';

import '../../app_router.gr.dart';
import '../../models/grocery.dart';
import '../../models/ingredient.dart';
import '../../providers/state_providers.dart';
import '../../services/shopping_list_service.dart';
import '../../utils/widget_utils.dart';
import '../../widgets/ingredient_edit_modal.dart';
import 'meal_list_view/meal_list_view.dart';
import 'plan_view/plan_tab_view.dart';
import 'shopping_list_view/shopping_list_view.dart';

class TabNavigationView extends StatefulWidget {
  const TabNavigationView({Key? key}) : super(key: key);

  @override
  State<TabNavigationView> createState() => _TabNavigationViewState();
}

class _TabNavigationViewState extends State<TabNavigationView> {
  final PageController _pageController = PageController(initialPage: 1);
  int _currentIndex = 1;
  bool _navbarAnimating = false;

  String? _activeListId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          onPageChanged: (value) {
            if (!_navbarAnimating) {
              setState(() {
                _currentIndex = value;
              });
            }
          },
          children: const [ShoppingListView(), PlanTabView(), MealListView()],
        ),
      ),
      floatingActionButton: _showActionButton()
          ? FloatingActionButton(
              child: const Icon(EvaIcons.plus),
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
        items: const [
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
      final planId = context.read(planProvider).state!.id!;
      final list = await ShoppingListService.getShoppingListByPlanId(planId);
      _activeListId = list.id;
    }

    final result = await WidgetUtils.showFoodlyBottomSheet<Ingredient?>(
      context: context,
      builder: (_) => IngredientEditModal(
        ingredient: Ingredient(),
      ),
    );

    if (result == null) {
      return;
    }

    await ShoppingListService.addGrocery(
      _activeListId!,
      Grocery.fromIngredient(result),
    );
  }

  void _openMealCreate() {
    AutoRouter.of(context).push(MealCreateScreenRoute(id: 'create'));
  }
}
