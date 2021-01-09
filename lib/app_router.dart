import 'package:auto_route/auto_route_annotations.dart';

import 'screens/unknown_route/unknown_route_screen.dart';
import 'screens/meal-select/meal_select.dart';
import 'screens/meal/meal_screen.dart';
import 'screens/tab_navigation/tab_navigation_screen.dart';

// generate with `flutter packages pub run build_runner build`
// generate with `flutter packages pub run build_runner watch`

@MaterialAutoRouter(
  routes: <AutoRoute>[
    AdaptiveRoute(page: TabNavigationScreen, initial: true),
    AdaptiveRoute(page: MealSelectScreen),
    AdaptiveRoute(path: '/meal/:id', page: MealScreen),
    AdaptiveRoute(path: '*', page: UnknownRouteScreen),
  ],
)
class $AppRouter {}
