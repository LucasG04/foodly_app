import 'dart:math' as math;

import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_snake_navigationbar/flutter_snake_navigationbar.dart';

import '../../models/grocery.dart';
import '../../models/ingredient.dart';
import '../../providers/state_providers.dart';
import '../../services/shopping_list_service.dart';
import '../../utils/analytics.dart';
import '../../utils/basic_utils.dart';
import '../../utils/of_context_mixin.dart';
import '../../utils/widget_utils.dart';
import '../../widgets/ingredient_edit_modal.dart';
import '../../widgets/sized_safe_area.dart';
import '../add_dish/add_dish_sheet.dart';
import 'meal_list_view/meal_list_view.dart';
import 'plan_view/plan_tab_view.dart';
import 'shopping_list_view/shopping_list_view.dart';

class TabNavigationView extends ConsumerStatefulWidget {
  const TabNavigationView({super.key});

  @override
  _TabNavigationViewState createState() => _TabNavigationViewState();
}

class _TabNavigationViewState extends ConsumerState<TabNavigationView>
    with OfContextMixin {
  final PageController _pageController = PageController(initialPage: 1);
  int _currentIndex = 1;
  bool _navbarAnimating = false;

  String? _activeListId;

  static const _tabs = [
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
  ];

  @override
  Widget build(BuildContext context) {
    // iPhone Duo puts the status bar on a side edge (inset there instead of at
    // the top); the tab bar follows it there as a rail, like system tab bars.
    final padding = mediaPadding;
    final railRight = padding.right > padding.top;
    final railLeft = !railRight && padding.left > padding.top;
    final railWidth = math.max(railLeft ? padding.left : padding.right, 72.0);
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Stack(
          children: [
            // Pages scroll under the home indicator and pad for it themselves.
            SizedSafeArea(
              bottom: false,
              minLeft: railLeft ? railWidth : 0,
              minRight: railRight ? railWidth : 0,
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (value) {
                  if (!_navbarAnimating) {
                    setState(() {
                      _currentIndex = value;
                    });
                    _logTabView(value);
                  }
                },
                children: const [
                  ShoppingListView(),
                  PlanTabView(),
                  MealListView(),
                ],
              ),
            ),
            if (railLeft || railRight)
              Positioned(
                top: 0,
                bottom: 0,
                left: railLeft ? 0 : null,
                right: railRight ? 0 : null,
                width: railWidth,
                child: _buildRail(railWidth),
              ),
          ],
        ),
      ),
      floatingActionButton: _showActionButton()
          ? FloatingActionButton(
              backgroundColor: theme.primaryColor,
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
      bottomNavigationBar: railLeft || railRight
          ? null
          : SnakeNavigationBar.color(
              currentIndex: _currentIndex,
              snakeViewColor: theme.primaryColor,
              unselectedItemColor: theme.primaryColor,
              backgroundColor: theme.scaffoldBackgroundColor,
              elevation: 1,
              onTap: _selectTab,
              items: _tabs,
            ),
    );
  }

  /// Fills the side inset, below the status bar.
  Widget _buildRail(double width) {
    return MediaQuery.removePadding(
      context: context,
      removeLeft: true,
      removeRight: true,
      // No ink: the rail's built-in highlight is a fixed rect, not our circle.
      child: Theme(
        data: theme.copyWith(
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        child: NavigationRail(
          minWidth: width,
          groupAlignment: 1,
          backgroundColor: theme.scaffoldBackgroundColor,
          // M3's indicator is fixed at 32pt, so draw a larger circle instead.
          useIndicator: false,
          selectedIconTheme: const IconThemeData(color: Colors.white),
          unselectedIconTheme: IconThemeData(color: theme.primaryColor),
          selectedIndex: _currentIndex,
          onDestinationSelected: _selectTab,
          destinations: [
            for (final tab in _tabs)
              NavigationRailDestination(
                icon: SizedBox.square(dimension: 48, child: tab.icon),
                selectedIcon: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: tab.icon,
                ),
                label: Text(tab.label!),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTab(int value) async {
    if (value != _currentIndex) {
      _logTabView(value);
    }
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
  }

  void _logTabView(int index) {
    const tabs = ['shopping', 'plan', 'meals'];
    logEvent(AnalyticsEvent.tabView, {'tab': tabs[index]});
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
          logEvent(AnalyticsEvent.groceryAdd, {'source': 'manual'});
        },
      ),
    );
  }

  void _openMealCreate() {
    showAddDishSheet(context, ref);
  }
}
