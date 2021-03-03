import 'package:auto_route/auto_route_annotations.dart';
import 'screens/authentication/authentication_screen.dart';
import 'screens/tab_navigation/home_screen.dart';

import 'screens/meal_create/meal_create_screen.dart';
import 'screens/meal/meal_screen.dart';
import 'screens/meal_select/meal_select.dart';
import 'screens/unknown_route/unknown_route_screen.dart';

// generate with `flutter packages pub run build_runner build`
// generate with `flutter packages pub run build_runner watch`

@MaterialAutoRouter(
  routes: <AutoRoute>[
    AdaptiveRoute(page: HomeScreen, initial: true),
    AdaptiveRoute(page: AuthenticationScreen),
    AdaptiveRoute(page: MealSelectScreen),
    AdaptiveRoute(path: '/meal-create/:id', page: MealCreateScreen),
    AdaptiveRoute(path: '/meal/:id', page: MealScreen),
    AdaptiveRoute(path: '*', page: UnknownRouteScreen),
  ],
)
class $AppRouter {}
