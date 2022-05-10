// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************
//
// ignore_for_file: type=lint

import 'package:auto_route/auto_route.dart' as _i9;
import 'package:flutter/material.dart' as _i10;

import 'screens/authentication/authentication_screen.dart' as _i2;
import 'screens/feedback/feedback_screen.dart' as _i5;
import 'screens/meal/meal_screen.dart' as _i7;
import 'screens/meal_create/meal_create_screen.dart' as _i6;
import 'screens/meal_select/meal_select.dart' as _i3;
import 'screens/onboarding/onboarding_screen.dart' as _i4;
import 'screens/tab_navigation/home_screen.dart' as _i1;
import 'screens/unknown_route/unknown_route_screen.dart' as _i8;

class AppRouter extends _i9.RootStackRouter {
  AppRouter([_i10.GlobalKey<_i10.NavigatorState>? navigatorKey])
      : super(navigatorKey);

  @override
  final Map<String, _i9.PageFactory> pagesMap = {
    HomeScreenRoute.name: (routeData) {
      return _i9.CupertinoPageX<dynamic>(
          routeData: routeData, child: const _i1.HomeScreen());
    },
    AuthenticationScreenRoute.name: (routeData) {
      return _i9.CupertinoPageX<dynamic>(
          routeData: routeData, child: const _i2.AuthenticationScreen());
    },
    MealSelectScreenRoute.name: (routeData) {
      final args = routeData.argsAs<MealSelectScreenRouteArgs>();
      return _i9.CupertinoPageX<dynamic>(
          routeData: routeData,
          child: _i3.MealSelectScreen(
              date: args.date, isLunch: args.isLunch, key: args.key));
    },
    OnboardingScreenRoute.name: (routeData) {
      final args = routeData.argsAs<OnboardingScreenRouteArgs>(
          orElse: () => const OnboardingScreenRouteArgs());
      return _i9.CupertinoPageX<dynamic>(
          routeData: routeData, child: _i4.OnboardingScreen(key: args.key));
    },
    FeedbackScreenRoute.name: (routeData) {
      return _i9.CupertinoPageX<dynamic>(
          routeData: routeData, child: const _i5.FeedbackScreen());
    },
    MealCreateScreenRoute.name: (routeData) {
      final args = routeData.argsAs<MealCreateScreenRouteArgs>();
      return _i9.CupertinoPageX<dynamic>(
          routeData: routeData,
          child: _i6.MealCreateScreen(id: args.id, key: args.key));
    },
    MealScreenRoute.name: (routeData) {
      final args = routeData.argsAs<MealScreenRouteArgs>();
      return _i9.CupertinoPageX<dynamic>(
          routeData: routeData,
          child: _i7.MealScreen(id: args.id, key: args.key));
    },
    UnknownRouteScreenRoute.name: (routeData) {
      return _i9.CupertinoPageX<dynamic>(
          routeData: routeData, child: const _i8.UnknownRouteScreen());
    }
  };

  @override
  List<_i9.RouteConfig> get routes => [
        _i9.RouteConfig(HomeScreenRoute.name, path: '/'),
        _i9.RouteConfig(AuthenticationScreenRoute.name,
            path: '/authentication-screen'),
        _i9.RouteConfig(MealSelectScreenRoute.name,
            path: '/meal-select-screen'),
        _i9.RouteConfig(OnboardingScreenRoute.name, path: '/onboarding-screen'),
        _i9.RouteConfig(FeedbackScreenRoute.name, path: '/feedback-screen'),
        _i9.RouteConfig(MealCreateScreenRoute.name, path: '/meal-create/:id'),
        _i9.RouteConfig(MealScreenRoute.name, path: '/meal/:id'),
        _i9.RouteConfig(UnknownRouteScreenRoute.name, path: '*')
      ];
}

/// generated route for
/// [_i1.HomeScreen]
class HomeScreenRoute extends _i9.PageRouteInfo<void> {
  const HomeScreenRoute() : super(HomeScreenRoute.name, path: '/');

  static const String name = 'HomeScreenRoute';
}

/// generated route for
/// [_i2.AuthenticationScreen]
class AuthenticationScreenRoute extends _i9.PageRouteInfo<void> {
  const AuthenticationScreenRoute()
      : super(AuthenticationScreenRoute.name, path: '/authentication-screen');

  static const String name = 'AuthenticationScreenRoute';
}

/// generated route for
/// [_i3.MealSelectScreen]
class MealSelectScreenRoute
    extends _i9.PageRouteInfo<MealSelectScreenRouteArgs> {
  MealSelectScreenRoute(
      {required DateTime date, required bool isLunch, _i10.Key? key})
      : super(MealSelectScreenRoute.name,
            path: '/meal-select-screen',
            args: MealSelectScreenRouteArgs(
                date: date, isLunch: isLunch, key: key));

  static const String name = 'MealSelectScreenRoute';
}

class MealSelectScreenRouteArgs {
  const MealSelectScreenRouteArgs(
      {required this.date, required this.isLunch, this.key});

  final DateTime date;

  final bool isLunch;

  final _i10.Key? key;

  @override
  String toString() {
    return 'MealSelectScreenRouteArgs{date: $date, isLunch: $isLunch, key: $key}';
  }
}

/// generated route for
/// [_i4.OnboardingScreen]
class OnboardingScreenRoute
    extends _i9.PageRouteInfo<OnboardingScreenRouteArgs> {
  OnboardingScreenRoute({_i10.Key? key})
      : super(OnboardingScreenRoute.name,
            path: '/onboarding-screen',
            args: OnboardingScreenRouteArgs(key: key));

  static const String name = 'OnboardingScreenRoute';
}

class OnboardingScreenRouteArgs {
  const OnboardingScreenRouteArgs({this.key});

  final _i10.Key? key;

  @override
  String toString() {
    return 'OnboardingScreenRouteArgs{key: $key}';
  }
}

/// generated route for
/// [_i5.FeedbackScreen]
class FeedbackScreenRoute extends _i9.PageRouteInfo<void> {
  const FeedbackScreenRoute()
      : super(FeedbackScreenRoute.name, path: '/feedback-screen');

  static const String name = 'FeedbackScreenRoute';
}

/// generated route for
/// [_i6.MealCreateScreen]
class MealCreateScreenRoute
    extends _i9.PageRouteInfo<MealCreateScreenRouteArgs> {
  MealCreateScreenRoute({required String id, _i10.Key? key})
      : super(MealCreateScreenRoute.name,
            path: '/meal-create/:id',
            args: MealCreateScreenRouteArgs(id: id, key: key));

  static const String name = 'MealCreateScreenRoute';
}

class MealCreateScreenRouteArgs {
  const MealCreateScreenRouteArgs({required this.id, this.key});

  final String id;

  final _i10.Key? key;

  @override
  String toString() {
    return 'MealCreateScreenRouteArgs{id: $id, key: $key}';
  }
}

/// generated route for
/// [_i7.MealScreen]
class MealScreenRoute extends _i9.PageRouteInfo<MealScreenRouteArgs> {
  MealScreenRoute({required String id, _i10.Key? key})
      : super(MealScreenRoute.name,
            path: '/meal/:id', args: MealScreenRouteArgs(id: id, key: key));

  static const String name = 'MealScreenRoute';
}

class MealScreenRouteArgs {
  const MealScreenRouteArgs({required this.id, this.key});

  final String id;

  final _i10.Key? key;

  @override
  String toString() {
    return 'MealScreenRouteArgs{id: $id, key: $key}';
  }
}

/// generated route for
/// [_i8.UnknownRouteScreen]
class UnknownRouteScreenRoute extends _i9.PageRouteInfo<void> {
  const UnknownRouteScreenRoute()
      : super(UnknownRouteScreenRoute.name, path: '*');

  static const String name = 'UnknownRouteScreenRoute';
}
