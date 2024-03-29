import 'package:auto_route/auto_route.dart';

import 'screens/authentication/authentication_screen.dart';
import 'screens/feedback/feedback_screen.dart';
import 'screens/meal/meal_screen.dart';
import 'screens/meal_create/meal_create_screen.dart';
import 'screens/meal_select/meal_select.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/settings/reorder_product_groups_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/tab_navigation/home_screen.dart';
import 'screens/unknown_route/unknown_route_screen.dart';
import 'screens/upcoming_features/upcoming_features_screen.dart';

// generate with `flutter packages pub run build_runner build --delete-conflicting-outputs`
// generate with `flutter packages pub run build_runner watch`

@MaterialAutoRouter(
  routes: <AutoRoute>[
    CupertinoRoute<dynamic>(page: HomeScreen, initial: true),
    CupertinoRoute<dynamic>(page: AuthenticationScreen),
    CupertinoRoute<dynamic>(page: SettingsScreen),
    CupertinoRoute<dynamic>(page: MealSelectScreen),
    CupertinoRoute<dynamic>(page: OnboardingScreen),
    CupertinoRoute<dynamic>(page: FeedbackScreen),
    CupertinoRoute<dynamic>(page: UpcomingFeaturesScreen),
    CupertinoRoute<dynamic>(page: ReorderProductGroupsScreen),
    CupertinoRoute<dynamic>(path: '/meal-create/:id', page: MealCreateScreen),
    CupertinoRoute<dynamic>(path: '/meal', page: MealScreen),
    CupertinoRoute<dynamic>(path: '*', page: UnknownRouteScreen),
  ],
)
class $AppRouter {}
