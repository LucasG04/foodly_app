// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

import 'package:auto_route/auto_route.dart' as _i8;
import 'package:flutter/material.dart' as _i9;

import 'screens/authentication/authentication_screen.dart' as _i2;
import 'screens/meal/meal_screen.dart' as _i6;
import 'screens/meal_create/meal_create_screen.dart' as _i5;
import 'screens/meal_select/meal_select.dart' as _i3;
import 'screens/onboarding/onboarding_screen.dart' as _i4;
import 'screens/tab_navigation/home_screen.dart' as _i1;
import 'screens/unknown_route/unknown_route_screen.dart' as _i7;

class AppRouter extends _i8.RootStackRouter {
  AppRouter([_i9.GlobalKey<_i9.NavigatorState>? navigatorKey])
      : super(navigatorKey);

  @override
  final Map<String, _i8.PageFactory> pagesMap = {
    HomeScreenRoute.name: (routeData) {
      return _i8.CupertinoPageX<dynamic>(
          routeData: routeData, child: _i1.HomeScreen());
    },
    AuthenticationScreenRoute.name: (routeData) {
      return _i8.CupertinoPageX<dynamic>(
          routeData: routeData, child: _i2.AuthenticationScreen());
    },
    MealSelectScreenRoute.name: (routeData) {
      final args = routeData.argsAs<MealSelectScreenRouteArgs>();
      return _i8.CupertinoPageX<dynamic>(
          routeData: routeData,
          child: _i3.MealSelectScreen(date: args.date, isLunch: args.isLunch));
    },
    OnboardingScreenRoute.name: (routeData) {
      return _i8.CupertinoPageX<dynamic>(
          routeData: routeData, child: _i4.OnboardingScreen());
    },
    MealCreateScreenRoute.name: (routeData) {
      final args = routeData.argsAs<MealCreateScreenRouteArgs>();
      return _i8.CupertinoPageX<dynamic>(
          routeData: routeData, child: _i5.MealCreateScreen(id: args.id));
    },
    MealScreenRoute.name: (routeData) {
      final args = routeData.argsAs<MealScreenRouteArgs>();
      return _i8.CupertinoPageX<dynamic>(
          routeData: routeData, child: _i6.MealScreen(id: args.id));
    },
    UnknownRouteScreenRoute.name: (routeData) {
      return _i8.CupertinoPageX<dynamic>(
          routeData: routeData, child: _i7.UnknownRouteScreen());
    }
  };

  @override
  List<_i8.RouteConfig> get routes => [
        _i8.RouteConfig(HomeScreenRoute.name, path: '/'),
        _i8.RouteConfig(AuthenticationScreenRoute.name,
            path: '/authentication-screen'),
        _i8.RouteConfig(MealSelectScreenRoute.name,
            path: '/meal-select-screen'),
        _i8.RouteConfig(OnboardingScreenRoute.name, path: '/onboarding-screen'),
        _i8.RouteConfig(MealCreateScreenRoute.name, path: '/meal-create/:id'),
        _i8.RouteConfig(MealScreenRoute.name, path: '/meal/:id'),
        _i8.RouteConfig(UnknownRouteScreenRoute.name, path: '*')
      ];
}

/// generated route for [_i1.HomeScreen]
class HomeScreenRoute extends _i8.PageRouteInfo<void> {
  const HomeScreenRoute() : super(name, path: '/');

  static const String name = 'HomeScreenRoute';
}

/// generated route for [_i2.AuthenticationScreen]
class AuthenticationScreenRoute extends _i8.PageRouteInfo<void> {
  const AuthenticationScreenRoute()
      : super(name, path: '/authentication-screen');

  static const String name = 'AuthenticationScreenRoute';
}

/// generated route for [_i3.MealSelectScreen]
class MealSelectScreenRoute
    extends _i8.PageRouteInfo<MealSelectScreenRouteArgs> {
  MealSelectScreenRoute({required DateTime date, required bool isLunch})
      : super(name,
            path: '/meal-select-screen',
            args: MealSelectScreenRouteArgs(date: date, isLunch: isLunch));

  static const String name = 'MealSelectScreenRoute';
}

class MealSelectScreenRouteArgs {
  const MealSelectScreenRouteArgs({required this.date, required this.isLunch});

  final DateTime date;

  final bool isLunch;

  @override
  String toString() {
    return 'MealSelectScreenRouteArgs{date: $date, isLunch: $isLunch}';
  }
}

/// generated route for [_i4.OnboardingScreen]
class OnboardingScreenRoute extends _i8.PageRouteInfo<void> {
  const OnboardingScreenRoute() : super(name, path: '/onboarding-screen');

  static const String name = 'OnboardingScreenRoute';
}

/// generated route for [_i5.MealCreateScreen]
class MealCreateScreenRoute
    extends _i8.PageRouteInfo<MealCreateScreenRouteArgs> {
  MealCreateScreenRoute({required String id})
      : super(name,
            path: '/meal-create/:id', args: MealCreateScreenRouteArgs(id: id));

  static const String name = 'MealCreateScreenRoute';
}

class MealCreateScreenRouteArgs {
  const MealCreateScreenRouteArgs({required this.id});

  final String id;

  @override
  String toString() {
    return 'MealCreateScreenRouteArgs{id: $id}';
  }
}

/// generated route for [_i6.MealScreen]
class MealScreenRoute extends _i8.PageRouteInfo<MealScreenRouteArgs> {
  MealScreenRoute({required String id})
      : super(name, path: '/meal/:id', args: MealScreenRouteArgs(id: id));

  static const String name = 'MealScreenRoute';
}

class MealScreenRouteArgs {
  const MealScreenRouteArgs({required this.id});

  final String id;

  @override
  String toString() {
    return 'MealScreenRouteArgs{id: $id}';
  }
}

/// generated route for [_i7.UnknownRouteScreen]
class UnknownRouteScreenRoute extends _i8.PageRouteInfo<void> {
  const UnknownRouteScreenRoute() : super(name, path: '*');

  static const String name = 'UnknownRouteScreenRoute';
}
