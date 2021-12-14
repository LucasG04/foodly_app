import 'package:auto_route/auto_route.dart';

import 'screens/authentication/authentication_screen.dart';
import 'screens/meal/meal_screen.dart';
import 'screens/meal_create/meal_create_screen.dart';
import 'screens/meal_select/meal_select.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/tab_navigation/home_screen.dart';
import 'screens/unknown_route/unknown_route_screen.dart';

// generate with `flutter packages pub run build_runner build`
// generate with `flutter packages pub run build_runner watch`

@MaterialAutoRouter(
  routes: <AutoRoute>[
    CupertinoRoute(page: HomeScreen, initial: true),
    CupertinoRoute(page: AuthenticationScreen),
    CupertinoRoute(page: MealSelectScreen),
    CupertinoRoute(page: OnboardingScreen),
    CupertinoRoute(path: '/meal-create/:id', page: MealCreateScreen),
    CupertinoRoute(path: '/meal/:id', page: MealScreen),
    CupertinoRoute(path: '*', page: UnknownRouteScreen),
  ],
)
class $AppRouter {}
