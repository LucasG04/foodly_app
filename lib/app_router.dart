import 'package:auto_route/auto_route.dart';

import 'screens/authentication/authentication_screen.dart';
import 'screens/feedback/feedback_screen.dart';
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
    CupertinoRoute<dynamic>(page: HomeScreen, initial: true),
    CupertinoRoute<dynamic>(page: AuthenticationScreen),
    CupertinoRoute<dynamic>(page: MealSelectScreen),
    CupertinoRoute<dynamic>(page: OnboardingScreen),
    CupertinoRoute<dynamic>(page: FeedbackScreen),
    CupertinoRoute<dynamic>(path: '/meal-create/:id', page: MealCreateScreen),
    CupertinoRoute<dynamic>(path: '/meal/:id', page: MealScreen),
    CupertinoRoute<dynamic>(path: '*', page: UnknownRouteScreen),
  ],
)
class $AppRouter {}
