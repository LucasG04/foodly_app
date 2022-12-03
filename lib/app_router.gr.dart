// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************
//
// ignore_for_file: type=lint

import 'package:auto_route/auto_route.dart' as _i12;
import 'package:flutter/material.dart' as _i13;

import 'models/plan_meal.dart' as _i14;
import 'screens/authentication/authentication_screen.dart' as _i2;
import 'screens/feedback/feedback_screen.dart' as _i6;
import 'screens/meal/meal_screen.dart' as _i10;
import 'screens/meal_create/meal_create_screen.dart' as _i9;
import 'screens/meal_select/meal_select.dart' as _i4;
import 'screens/onboarding/onboarding_screen.dart' as _i5;
import 'screens/settings/reorder_product_groups_screen.dart' as _i8;
import 'screens/settings/settings_screen.dart' as _i3;
import 'screens/tab_navigation/home_screen.dart' as _i1;
import 'screens/unknown_route/unknown_route_screen.dart' as _i11;
import 'screens/upcoming_features/upcoming_features_screen.dart' as _i7;

class AppRouter extends _i12.RootStackRouter {
  AppRouter([_i13.GlobalKey<_i13.NavigatorState>? navigatorKey])
      : super(navigatorKey);

  @override
  final Map<String, _i12.PageFactory> pagesMap = {
    HomeScreenRoute.name: (routeData) {
      return _i12.CupertinoPageX<dynamic>(
          routeData: routeData, child: const _i1.HomeScreen());
    },
    AuthenticationScreenRoute.name: (routeData) {
      return _i12.CupertinoPageX<dynamic>(
          routeData: routeData, child: const _i2.AuthenticationScreen());
    },
    SettingsScreenRoute.name: (routeData) {
      return _i12.CupertinoPageX<dynamic>(
          routeData: routeData, child: const _i3.SettingsScreen());
    },
    MealSelectScreenRoute.name: (routeData) {
      final args = routeData.argsAs<MealSelectScreenRouteArgs>();
      return _i12.CupertinoPageX<dynamic>(
          routeData: routeData,
          child: _i4.MealSelectScreen(
              date: args.date, mealType: args.mealType, key: args.key));
    },
    OnboardingScreenRoute.name: (routeData) {
      return _i12.CupertinoPageX<dynamic>(
          routeData: routeData, child: const _i5.OnboardingScreen());
    },
    FeedbackScreenRoute.name: (routeData) {
      return _i12.CupertinoPageX<dynamic>(
          routeData: routeData, child: const _i6.FeedbackScreen());
    },
    UpcomingFeaturesScreenRoute.name: (routeData) {
      return _i12.CupertinoPageX<dynamic>(
          routeData: routeData, child: const _i7.UpcomingFeaturesScreen());
    },
    ReorderProductGroupsScreenRoute.name: (routeData) {
      return _i12.CupertinoPageX<dynamic>(
          routeData: routeData, child: const _i8.ReorderProductGroupsScreen());
    },
    MealCreateScreenRoute.name: (routeData) {
      final args = routeData.argsAs<MealCreateScreenRouteArgs>();
      return _i12.CupertinoPageX<dynamic>(
          routeData: routeData,
          child: _i9.MealCreateScreen(id: args.id, key: args.key));
    },
    MealScreenRoute.name: (routeData) {
      final args = routeData.argsAs<MealScreenRouteArgs>();
      return _i12.CupertinoPageX<dynamic>(
          routeData: routeData,
          child: _i10.MealScreen(id: args.id, key: args.key));
    },
    UnknownRouteScreenRoute.name: (routeData) {
      return _i12.CupertinoPageX<dynamic>(
          routeData: routeData, child: const _i11.UnknownRouteScreen());
    }
  };

  @override
  List<_i12.RouteConfig> get routes => [
        _i12.RouteConfig(HomeScreenRoute.name, path: '/'),
        _i12.RouteConfig(AuthenticationScreenRoute.name,
            path: '/authentication-screen'),
        _i12.RouteConfig(SettingsScreenRoute.name, path: '/settings-screen'),
        _i12.RouteConfig(MealSelectScreenRoute.name,
            path: '/meal-select-screen'),
        _i12.RouteConfig(OnboardingScreenRoute.name,
            path: '/onboarding-screen'),
        _i12.RouteConfig(FeedbackScreenRoute.name, path: '/feedback-screen'),
        _i12.RouteConfig(UpcomingFeaturesScreenRoute.name,
            path: '/upcoming-features-screen'),
        _i12.RouteConfig(ReorderProductGroupsScreenRoute.name,
            path: '/reorder-product-groups-screen'),
        _i12.RouteConfig(MealCreateScreenRoute.name, path: '/meal-create/:id'),
        _i12.RouteConfig(MealScreenRoute.name, path: '/meal/:id'),
        _i12.RouteConfig(UnknownRouteScreenRoute.name, path: '*')
      ];
}

/// generated route for
/// [_i1.HomeScreen]
class HomeScreenRoute extends _i12.PageRouteInfo<void> {
  const HomeScreenRoute() : super(HomeScreenRoute.name, path: '/');

  static const String name = 'HomeScreenRoute';
}

/// generated route for
/// [_i2.AuthenticationScreen]
class AuthenticationScreenRoute extends _i12.PageRouteInfo<void> {
  const AuthenticationScreenRoute()
      : super(AuthenticationScreenRoute.name, path: '/authentication-screen');

  static const String name = 'AuthenticationScreenRoute';
}

/// generated route for
/// [_i3.SettingsScreen]
class SettingsScreenRoute extends _i12.PageRouteInfo<void> {
  const SettingsScreenRoute()
      : super(SettingsScreenRoute.name, path: '/settings-screen');

  static const String name = 'SettingsScreenRoute';
}

/// generated route for
/// [_i4.MealSelectScreen]
class MealSelectScreenRoute
    extends _i12.PageRouteInfo<MealSelectScreenRouteArgs> {
  MealSelectScreenRoute(
      {required DateTime date, required _i14.MealType mealType, _i13.Key? key})
      : super(MealSelectScreenRoute.name,
            path: '/meal-select-screen',
            args: MealSelectScreenRouteArgs(
                date: date, mealType: mealType, key: key));

  static const String name = 'MealSelectScreenRoute';
}

class MealSelectScreenRouteArgs {
  const MealSelectScreenRouteArgs(
      {required this.date, required this.mealType, this.key});

  final DateTime date;

  final _i14.MealType mealType;

  final _i13.Key? key;

  @override
  String toString() {
    return 'MealSelectScreenRouteArgs{date: $date, mealType: $mealType, key: $key}';
  }
}

/// generated route for
/// [_i5.OnboardingScreen]
class OnboardingScreenRoute extends _i12.PageRouteInfo<void> {
  const OnboardingScreenRoute()
      : super(OnboardingScreenRoute.name, path: '/onboarding-screen');

  static const String name = 'OnboardingScreenRoute';
}

/// generated route for
/// [_i6.FeedbackScreen]
class FeedbackScreenRoute extends _i12.PageRouteInfo<void> {
  const FeedbackScreenRoute()
      : super(FeedbackScreenRoute.name, path: '/feedback-screen');

  static const String name = 'FeedbackScreenRoute';
}

/// generated route for
/// [_i7.UpcomingFeaturesScreen]
class UpcomingFeaturesScreenRoute extends _i12.PageRouteInfo<void> {
  const UpcomingFeaturesScreenRoute()
      : super(UpcomingFeaturesScreenRoute.name,
            path: '/upcoming-features-screen');

  static const String name = 'UpcomingFeaturesScreenRoute';
}

/// generated route for
/// [_i8.ReorderProductGroupsScreen]
class ReorderProductGroupsScreenRoute extends _i12.PageRouteInfo<void> {
  const ReorderProductGroupsScreenRoute()
      : super(ReorderProductGroupsScreenRoute.name,
            path: '/reorder-product-groups-screen');

  static const String name = 'ReorderProductGroupsScreenRoute';
}

/// generated route for
/// [_i9.MealCreateScreen]
class MealCreateScreenRoute
    extends _i12.PageRouteInfo<MealCreateScreenRouteArgs> {
  MealCreateScreenRoute({required String id, _i13.Key? key})
      : super(MealCreateScreenRoute.name,
            path: '/meal-create/:id',
            args: MealCreateScreenRouteArgs(id: id, key: key));

  static const String name = 'MealCreateScreenRoute';
}

class MealCreateScreenRouteArgs {
  const MealCreateScreenRouteArgs({required this.id, this.key});

  final String id;

  final _i13.Key? key;

  @override
  String toString() {
    return 'MealCreateScreenRouteArgs{id: $id, key: $key}';
  }
}

/// generated route for
/// [_i10.MealScreen]
class MealScreenRoute extends _i12.PageRouteInfo<MealScreenRouteArgs> {
  MealScreenRoute({required String id, _i13.Key? key})
      : super(MealScreenRoute.name,
            path: '/meal/:id', args: MealScreenRouteArgs(id: id, key: key));

  static const String name = 'MealScreenRoute';
}

class MealScreenRouteArgs {
  const MealScreenRouteArgs({required this.id, this.key});

  final String id;

  final _i13.Key? key;

  @override
  String toString() {
    return 'MealScreenRouteArgs{id: $id, key: $key}';
  }
}

/// generated route for
/// [_i11.UnknownRouteScreen]
class UnknownRouteScreenRoute extends _i12.PageRouteInfo<void> {
  const UnknownRouteScreenRoute()
      : super(UnknownRouteScreenRoute.name, path: '*');

  static const String name = 'UnknownRouteScreenRoute';
}
