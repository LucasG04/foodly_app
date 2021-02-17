import 'package:auto_route/auto_route_annotations.dart';
import 'package:foodly/screens/authentication/authentication_screen.dart';

import 'screens/meal_create/meal_create_screen.dart';
import 'screens/meal/meal_screen.dart';
import 'screens/meal_select/meal_select.dart';
import 'screens/tab_navigation/tab_navigation_screen.dart';
import 'screens/unknown_route/unknown_route_screen.dart';

// generate with `flutter packages pub run build_runner build`
// generate with `flutter packages pub run build_runner watch`

@MaterialAutoRouter(
  routes: <AutoRoute>[
    AdaptiveRoute(page: AuthenticationScreen, initial: true),
    AdaptiveRoute(page: TabNavigationScreen),
    AdaptiveRoute(page: MealSelectScreen),
    AdaptiveRoute(page: MealCreateScreen),
    AdaptiveRoute(path: '/meal/:id', page: MealScreen),
    AdaptiveRoute(path: '*', page: UnknownRouteScreen),
  ],
)
class $AppRouter {}
