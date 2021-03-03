// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

// ignore_for_file: public_member_api_docs

import 'package:auto_route/auto_route.dart';

import 'screens/authentication/authentication_screen.dart';
import 'screens/meal/meal_screen.dart';
import 'screens/meal_create/meal_create_screen.dart';
import 'screens/meal_select/meal_select.dart';
import 'screens/tab_navigation/home_screen.dart';
import 'screens/unknown_route/unknown_route_screen.dart';

class Routes {
  static const String homeScreen = '/';
  static const String authenticationScreen = '/authentication-screen';
  static const String mealSelectScreen = '/meal-select-screen';
  static const String _mealCreateScreen = '/meal-create/:id';
  static String mealCreateScreen({@required dynamic id}) => '/meal-create/$id';
  static const String _mealScreen = '/meal/:id';
  static String mealScreen({@required dynamic id}) => '/meal/$id';
  static const String unknownRouteScreen = '*';
  static const all = <String>{
    homeScreen,
    authenticationScreen,
    mealSelectScreen,
    _mealCreateScreen,
    _mealScreen,
    unknownRouteScreen,
  };
}

class AppRouter extends RouterBase {
  @override
  List<RouteDef> get routes => _routes;
  final _routes = <RouteDef>[
    RouteDef(Routes.homeScreen, page: HomeScreen),
    RouteDef(Routes.authenticationScreen, page: AuthenticationScreen),
    RouteDef(Routes.mealSelectScreen, page: MealSelectScreen),
    RouteDef(Routes._mealCreateScreen, page: MealCreateScreen),
    RouteDef(Routes._mealScreen, page: MealScreen),
    RouteDef(Routes.unknownRouteScreen, page: UnknownRouteScreen),
  ];
  @override
  Map<Type, AutoRouteFactory> get pagesMap => _pagesMap;
  final _pagesMap = <Type, AutoRouteFactory>{
    HomeScreen: (data) {
      return buildAdaptivePageRoute<dynamic>(
        builder: (context) => HomeScreen(),
        settings: data,
      );
    },
    AuthenticationScreen: (data) {
      return buildAdaptivePageRoute<dynamic>(
        builder: (context) => AuthenticationScreen(),
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
        builder: (context) =>
            MealCreateScreen(id: data.pathParams['id'].stringValue),
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
