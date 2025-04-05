import 'package:auto_route/auto_route.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_snake_navigationbar/flutter_snake_navigationbar.dart';

import '../../app_router.gr.dart';
import '../../models/grocery.dart';
import '../../models/ingredient.dart';
import '../../providers/state_providers.dart';
import '../../services/shopping_list_service.dart';
import '../../utils/basic_utils.dart';
import '../../utils/widget_utils.dart';
import '../../widgets/ingredient_edit_modal.dart';
import 'meal_list_view/meal_list_view.dart';
import 'plan_view/plan_tab_view.dart';
import 'shopping_list_view/shopping_list_view.dart';

class TabNavigationView extends ConsumerStatefulWidget {
  const TabNavigationView({super.key});

  @override
  _TabNavigationViewState createState() => _TabNavigationViewState();
}

class _TabNavigationViewState extends ConsumerState<TabNavigationView> {
  final PageController _pageController = PageController(initialPage: 1);
  int _currentIndex = 1;
  bool _navbarAnimating = false;

  String? _activeListId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: SafeArea(
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
      ),
      floatingActionButton: _showActionButton()
          ? FloatingActionButton(
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(
                EvaIcons.plus,
                color: Colors.white,
              ),
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
        snakeViewColor: Theme.of(context).primaryColor,
        unselectedItemColor: Theme.of(context).primaryColor,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 1,
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
            icon: Icon(Icons.checklist_rounded),
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
    _activeListId ??= ref.read(shoppingListIdProvider);

    await WidgetUtils.showFoodlyBottomSheet<Ingredient?>(
      context: context,
      builder: (_) => IngredientEditModal(
        ingredient: Ingredient(),
        onSaved: (result) async {
          final grocery = Grocery.fromIngredient(result);
          await ShoppingListService.addGrocery(
            _activeListId!,
            grocery,
            BasicUtils.getActiveLanguage(context),
          );
        },
      ),
    );
  }

  void _openMealCreate() {
    AutoRouter.of(context).push(MealCreateScreenRoute(id: 'create'));
  }
}
