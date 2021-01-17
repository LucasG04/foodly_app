// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

// ignore_for_file: public_member_api_docs

import 'package:auto_route/auto_route.dart';

import 'screens/meal-create/meal_create_screen.dart';
import 'screens/meal/meal_screen.dart';
import 'screens/meal_select/meal_select.dart';
import 'screens/tab_navigation/tab_navigation_screen.dart';
import 'screens/unknown_route/unknown_route_screen.dart';

class Routes {
  static const String tabNavigationScreen = '/';
  static const String mealSelectScreen = '/meal-select-screen';
  static const String mealCreateScreen = '/meal-create-screen';
  static const String _mealScreen = '/meal/:id';
  static String mealScreen({@required dynamic id}) => '/meal/$id';
  static const String unknownRouteScreen = '*';
  static const all = <String>{
    tabNavigationScreen,
    mealSelectScreen,
    mealCreateScreen,
    _mealScreen,
    unknownRouteScreen,
  };
}

class AppRouter extends RouterBase {
  @override
  List<RouteDef> get routes => _routes;
  final _routes = <RouteDef>[
    RouteDef(Routes.tabNavigationScreen, page: TabNavigationScreen),
    RouteDef(Routes.mealSelectScreen, page: MealSelectScreen),
    RouteDef(Routes.mealCreateScreen, page: MealCreateScreen),
    RouteDef(Routes._mealScreen, page: MealScreen),
    RouteDef(Routes.unknownRouteScreen, page: UnknownRouteScreen),
  ];
  @override
  Map<Type, AutoRouteFactory> get pagesMap => _pagesMap;
  final _pagesMap = <Type, AutoRouteFactory>{
    TabNavigationScreen: (data) {
      return buildAdaptivePageRoute<dynamic>(
        builder: (context) => TabNavigationScreen(),
        settings: data,
      );
    },
    MealSelectScreen: (data) {
      return buildAdaptivePageRoute<dynamic>(
        builder: (context) => MealSelectScreen(
          dateString: data.queryParams['date'].stringValue,
          isLunchString: data.queryParams['isLunch'].stringValue,
        ),
        settings: data,
      );
    },
    MealCreateScreen: (data) {
      return buildAdaptivePageRoute<dynamic>(
        builder: (context) => MealCreateScreen(),
        settings: data,
      );
    },
    MealScreen: (data) {
      return buildAdaptivePageRoute<dynamic>(
        builder: (context) => MealScreen(id: data.pathParams['id'].stringValue),
        settings: data,
      );
    },
    UnknownRouteScreen: (data) {
      return buildAdaptivePageRoute<dynamic>(
        builder: (context) => UnknownRouteScreen(),
        settings: data,
      );
    },
  };
}
