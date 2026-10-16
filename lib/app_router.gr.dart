// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************
//
// ignore_for_file: type=lint

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i14;
import 'package:flutter/material.dart' as _i15;

import 'models/plan_meal.dart' as _i16;
import 'screens/authentication/authentication_screen.dart' as _i2;
import 'screens/feedback/feedback_screen.dart' as _i6;
import 'screens/library/library_meal_screen.dart' as _i10;
import 'screens/library/library_screen.dart' as _i9;
import 'screens/library/library_starter_sheet.dart' as _i17;
import 'screens/meal/meal_screen.dart' as _i12;
import 'screens/meal_create/meal_create_screen.dart' as _i11;
import 'screens/meal_select/meal_select.dart' as _i4;
import 'screens/onboarding/onboarding_screen.dart' as _i5;
import 'screens/settings/reorder_product_groups_screen.dart' as _i8;
import 'screens/settings/settings_screen.dart' as _i3;
import 'screens/tab_navigation/home_screen.dart' as _i1;
import 'screens/unknown_route/unknown_route_screen.dart' as _i13;
import 'screens/upcoming_features/upcoming_features_screen.dart' as _i7;

class AppRouter extends _i14.RootStackRouter {
  AppRouter([_i15.GlobalKey<_i15.NavigatorState>? navigatorKey])
      : super(navigatorKey);

  @override
  final Map<String, _i14.PageFactory> pagesMap = {
    HomeScreenRoute.name: (routeData) {
      return _i14.CupertinoPageX<dynamic>(
        routeData: routeData,
        child: const _i1.HomeScreen(),
      );
    },
    AuthenticationScreenRoute.name: (routeData) {
      return _i14.CupertinoPageX<dynamic>(
        routeData: routeData,
        child: const _i2.AuthenticationScreen(),
      );
    },
    SettingsScreenRoute.name: (routeData) {
      return _i14.CupertinoPageX<dynamic>(
        routeData: routeData,
        child: const _i3.SettingsScreen(),
      );
    },
    MealSelectScreenRoute.name: (routeData) {
      final args = routeData.argsAs<MealSelectScreenRouteArgs>();
      return _i14.CupertinoPageX<dynamic>(
        routeData: routeData,
        child: _i4.MealSelectScreen(
          date: args.date,
          mealType: args.mealType,
          key: args.key,
        ),
      );
    },
    OnboardingScreenRoute.name: (routeData) {
      return _i14.CupertinoPageX<dynamic>(
        routeData: routeData,
        child: const _i5.OnboardingScreen(),
      );
    },
    FeedbackScreenRoute.name: (routeData) {
      return _i14.CupertinoPageX<dynamic>(
        routeData: routeData,
        child: const _i6.FeedbackScreen(),
      );
    },
    UpcomingFeaturesScreenRoute.name: (routeData) {
      return _i14.CupertinoPageX<dynamic>(
        routeData: routeData,
        child: const _i7.UpcomingFeaturesScreen(),
      );
    },
    ReorderProductGroupsScreenRoute.name: (routeData) {
      return _i14.CupertinoPageX<dynamic>(
        routeData: routeData,
        child: const _i8.ReorderProductGroupsScreen(),
      );
    },
    LibraryScreenRoute.name: (routeData) {
      final args = routeData.argsAs<LibraryScreenRouteArgs>(
          orElse: () => const LibraryScreenRouteArgs());
      return _i14.CupertinoPageX<dynamic>(
        routeData: routeData,
        child: _i9.LibraryScreen(
          query: args.query,
          tags: args.tags,
          starter: args.starter,
          entry: args.entry,
          key: args.key,
        ),
      );
    },
    LibraryMealScreenRoute.name: (routeData) {
      final args = routeData.argsAs<LibraryMealScreenRouteArgs>();
      return _i14.CupertinoPageX<dynamic>(
        routeData: routeData,
        child: _i10.LibraryMealScreen(
          id: args.id,
          entry: args.entry,
          onImported: args.onImported,
          key: args.key,
        ),
      );
    },
    MealCreateScreenRoute.name: (routeData) {
      final args = routeData.argsAs<MealCreateScreenRouteArgs>();
      return _i14.CupertinoPageX<dynamic>(
        routeData: routeData,
        child: _i11.MealCreateScreen(
          id: args.id,
          navigateToDetailOnCreate: args.navigateToDetailOnCreate,
          key: args.key,
        ),
      );
    },
    MealScreenRoute.name: (routeData) {
      final args = routeData.argsAs<MealScreenRouteArgs>();
      return _i14.CupertinoPageX<dynamic>(
        routeData: routeData,
        child: _i12.MealScreen(
          id: args.id,
          showOptions: args.showOptions,
          key: args.key,
        ),
      );
    },
    UnknownRouteScreenRoute.name: (routeData) {
      return _i14.CupertinoPageX<dynamic>(
        routeData: routeData,
        child: const _i13.UnknownRouteScreen(),
      );
    },
  };

  @override
  List<_i14.RouteConfig> get routes => [
        _i14.RouteConfig(
          HomeScreenRoute.name,
          path: '/',
        ),
        _i14.RouteConfig(
          AuthenticationScreenRoute.name,
          path: '/authentication-screen',
        ),
        _i14.RouteConfig(
          SettingsScreenRoute.name,
          path: '/settings-screen',
        ),
        _i14.RouteConfig(
          MealSelectScreenRoute.name,
          path: '/meal-select-screen',
        ),
        _i14.RouteConfig(
          OnboardingScreenRoute.name,
          path: '/onboarding-screen',
        ),
        _i14.RouteConfig(
          FeedbackScreenRoute.name,
          path: '/feedback-screen',
        ),
        _i14.RouteConfig(
          UpcomingFeaturesScreenRoute.name,
          path: '/upcoming-features-screen',
        ),
        _i14.RouteConfig(
          ReorderProductGroupsScreenRoute.name,
          path: '/reorder-product-groups-screen',
        ),
        _i14.RouteConfig(
          LibraryScreenRoute.name,
          path: '/library-screen',
        ),
        _i14.RouteConfig(
          LibraryMealScreenRoute.name,
          path: '/library-meal-screen',
        ),
        _i14.RouteConfig(
          MealCreateScreenRoute.name,
          path: '/meal-create/:id',
        ),
        _i14.RouteConfig(
          MealScreenRoute.name,
          path: '/meal',
        ),
        _i14.RouteConfig(
          UnknownRouteScreenRoute.name,
          path: '*',
        ),
      ];
}

/// generated route for
/// [_i1.HomeScreen]
class HomeScreenRoute extends _i14.PageRouteInfo<void> {
  const HomeScreenRoute()
      : super(
          HomeScreenRoute.name,
          path: '/',
        );

  static const String name = 'HomeScreenRoute';
}

/// generated route for
/// [_i2.AuthenticationScreen]
class AuthenticationScreenRoute extends _i14.PageRouteInfo<void> {
  const AuthenticationScreenRoute()
      : super(
          AuthenticationScreenRoute.name,
          path: '/authentication-screen',
        );

  static const String name = 'AuthenticationScreenRoute';
}

/// generated route for
/// [_i3.SettingsScreen]
class SettingsScreenRoute extends _i14.PageRouteInfo<void> {
  const SettingsScreenRoute()
      : super(
          SettingsScreenRoute.name,
          path: '/settings-screen',
        );

  static const String name = 'SettingsScreenRoute';
}

/// generated route for
/// [_i4.MealSelectScreen]
class MealSelectScreenRoute
    extends _i14.PageRouteInfo<MealSelectScreenRouteArgs> {
  MealSelectScreenRoute({
    required DateTime date,
    required _i16.MealType mealType,
    _i15.Key? key,
  }) : super(
          MealSelectScreenRoute.name,
          path: '/meal-select-screen',
          args: MealSelectScreenRouteArgs(
            date: date,
            mealType: mealType,
            key: key,
          ),
        );

  static const String name = 'MealSelectScreenRoute';
}

class MealSelectScreenRouteArgs {
  const MealSelectScreenRouteArgs({
    required this.date,
    required this.mealType,
    this.key,
  });

  final DateTime date;

  final _i16.MealType mealType;

  final _i15.Key? key;

  @override
  String toString() {
    return 'MealSelectScreenRouteArgs{date: $date, mealType: $mealType, key: $key}';
  }
}

/// generated route for
/// [_i5.OnboardingScreen]
class OnboardingScreenRoute extends _i14.PageRouteInfo<void> {
  const OnboardingScreenRoute()
      : super(
          OnboardingScreenRoute.name,
          path: '/onboarding-screen',
        );

  static const String name = 'OnboardingScreenRoute';
}

/// generated route for
/// [_i6.FeedbackScreen]
class FeedbackScreenRoute extends _i14.PageRouteInfo<void> {
  const FeedbackScreenRoute()
      : super(
          FeedbackScreenRoute.name,
          path: '/feedback-screen',
        );

  static const String name = 'FeedbackScreenRoute';
}

/// generated route for
/// [_i7.UpcomingFeaturesScreen]
class UpcomingFeaturesScreenRoute extends _i14.PageRouteInfo<void> {
  const UpcomingFeaturesScreenRoute()
      : super(
          UpcomingFeaturesScreenRoute.name,
          path: '/upcoming-features-screen',
        );

  static const String name = 'UpcomingFeaturesScreenRoute';
}

/// generated route for
/// [_i8.ReorderProductGroupsScreen]
class ReorderProductGroupsScreenRoute extends _i14.PageRouteInfo<void> {
  const ReorderProductGroupsScreenRoute()
      : super(
          ReorderProductGroupsScreenRoute.name,
          path: '/reorder-product-groups-screen',
        );

  static const String name = 'ReorderProductGroupsScreenRoute';
}

/// generated route for
/// [_i9.LibraryScreen]
class LibraryScreenRoute extends _i14.PageRouteInfo<LibraryScreenRouteArgs> {
  LibraryScreenRoute({
    String? query,
    List<String>? tags,
    _i17.StarterAnswers? starter,
    String entry = 'header',
    _i15.Key? key,
  }) : super(
          LibraryScreenRoute.name,
          path: '/library-screen',
          args: LibraryScreenRouteArgs(
            query: query,
            tags: tags,
            starter: starter,
            entry: entry,
            key: key,
          ),
        );

  static const String name = 'LibraryScreenRoute';
}

class LibraryScreenRouteArgs {
  const LibraryScreenRouteArgs({
    this.query,
    this.tags,
    this.starter,
    this.entry = 'header',
    this.key,
  });

  final String? query;

  final List<String>? tags;

  final _i17.StarterAnswers? starter;

  final String entry;

  final _i15.Key? key;

  @override
  String toString() {
    return 'LibraryScreenRouteArgs{query: $query, tags: $tags, starter: $starter, entry: $entry, key: $key}';
  }
}

/// generated route for
/// [_i10.LibraryMealScreen]
class LibraryMealScreenRoute
    extends _i14.PageRouteInfo<LibraryMealScreenRouteArgs> {
  LibraryMealScreenRoute({
    required String id,
    String entry = 'library',
    void Function(
      String,
      String,
    )? onImported,
    _i15.Key? key,
  }) : super(
          LibraryMealScreenRoute.name,
          path: '/library-meal-screen',
          args: LibraryMealScreenRouteArgs(
            id: id,
            entry: entry,
            onImported: onImported,
            key: key,
          ),
        );

  static const String name = 'LibraryMealScreenRoute';
}

class LibraryMealScreenRouteArgs {
  const LibraryMealScreenRouteArgs({
    required this.id,
    this.entry = 'library',
    this.onImported,
    this.key,
  });

  final String id;

  final String entry;

  final void Function(
    String,
    String,
  )? onImported;

  final _i15.Key? key;

  @override
  String toString() {
    return 'LibraryMealScreenRouteArgs{id: $id, entry: $entry, onImported: $onImported, key: $key}';
  }
}

/// generated route for
/// [_i11.MealCreateScreen]
class MealCreateScreenRoute
    extends _i14.PageRouteInfo<MealCreateScreenRouteArgs> {
  MealCreateScreenRoute({
    required String id,
    bool navigateToDetailOnCreate = false,
    _i15.Key? key,
  }) : super(
          MealCreateScreenRoute.name,
          path: '/meal-create/:id',
          args: MealCreateScreenRouteArgs(
            id: id,
            navigateToDetailOnCreate: navigateToDetailOnCreate,
            key: key,
          ),
        );

  static const String name = 'MealCreateScreenRoute';
}

class MealCreateScreenRouteArgs {
  const MealCreateScreenRouteArgs({
    required this.id,
    this.navigateToDetailOnCreate = false,
    this.key,
  });

  final String id;

  final bool navigateToDetailOnCreate;

  final _i15.Key? key;

  @override
  String toString() {
    return 'MealCreateScreenRouteArgs{id: $id, navigateToDetailOnCreate: $navigateToDetailOnCreate, key: $key}';
  }
}

/// generated route for
/// [_i12.MealScreen]
class MealScreenRoute extends _i14.PageRouteInfo<MealScreenRouteArgs> {
  MealScreenRoute({
    required String id,
    bool showOptions = true,
    _i15.Key? key,
  }) : super(
          MealScreenRoute.name,
          path: '/meal',
          args: MealScreenRouteArgs(
            id: id,
            showOptions: showOptions,
            key: key,
          ),
        );

  static const String name = 'MealScreenRoute';
}

class MealScreenRouteArgs {
  const MealScreenRouteArgs({
    required this.id,
    this.showOptions = true,
    this.key,
  });

  final String id;

  final bool showOptions;

  final _i15.Key? key;

  @override
  String toString() {
    return 'MealScreenRouteArgs{id: $id, showOptions: $showOptions, key: $key}';
  }
}

/// generated route for
/// [_i13.UnknownRouteScreen]
class UnknownRouteScreenRoute extends _i14.PageRouteInfo<void> {
  const UnknownRouteScreenRoute()
      : super(
          UnknownRouteScreenRoute.name,
          path: '*',
        );

  static const String name = 'UnknownRouteScreenRoute';
}
