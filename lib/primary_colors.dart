import 'package:flutter/material.dart';

const kPrimaryColorsHex = [
  '595457',
  '072ac8',
  '2196F3',
  '004225',
  'f86624',
  'de0d92',
];

MaterialColor get defaultPrimaryColor => primaryBlueColor;

MaterialColor primaryGreyColor = const MaterialColor(0xFF3A3A3A, _darkGrayMap);
MaterialColor primaryDarkBlueColor =
    const MaterialColor(0xFF072AC8, _darkBlueMap);
MaterialColor primaryBlueColor = const MaterialColor(0xFF2196F3, _blueMap);
MaterialColor primaryDarkGreenColor =
    const MaterialColor(0xFF004225, _darkGreenMap);
MaterialColor primaryPurpleColor = const MaterialColor(0xFF802097, _purpleMap);
MaterialColor primaryPinkColor = const MaterialColor(0xFFDE0D92, _pinkMap);
MaterialColor primaryRedColor = const MaterialColor(0xFFCE2D4F, _redMap);
MaterialColor primaryOrangeColor = const MaterialColor(0xFFF86624, _orangeMap);

const Map<int, Color> _darkGrayMap = {
  50: Color.fromRGBO(58, 58, 58, .1),
  100: Color.fromRGBO(58, 58, 58, .2),
  200: Color.fromRGBO(58, 58, 58, .3),
  300: Color.fromRGBO(58, 58, 58, .4),
  400: Color.fromRGBO(58, 58, 58, .5),
  500: Color.fromRGBO(58, 58, 58, .6),
  600: Color.fromRGBO(58, 58, 58, .7),
  700: Color.fromRGBO(58, 58, 58, .8),
  800: Color.fromRGBO(58, 58, 58, .9),
  900: Color.fromRGBO(58, 58, 58, 1),
};

const Map<int, Color> _darkBlueMap = {
  50: Color.fromRGBO(7, 42, 200, .1),
  100: Color.fromRGBO(7, 42, 200, .2),
  200: Color.fromRGBO(7, 42, 200, .3),
  300: Color.fromRGBO(7, 42, 200, .4),
  400: Color.fromRGBO(7, 42, 200, .5),
  500: Color.fromRGBO(7, 42, 200, .6),
  600: Color.fromRGBO(7, 42, 200, .7),
  700: Color.fromRGBO(7, 42, 200, .8),
  800: Color.fromRGBO(7, 42, 200, .9),
  900: Color.fromRGBO(7, 42, 200, 1),
};

const Map<int, Color> _blueMap = {
  50: Color.fromRGBO(33, 150, 243, .1),
  100: Color.fromRGBO(33, 150, 243, .2),
  200: Color.fromRGBO(33, 150, 243, .3),
  300: Color.fromRGBO(33, 150, 243, .4),
  400: Color.fromRGBO(33, 150, 243, .5),
  500: Color.fromRGBO(33, 150, 243, .6),
  600: Color.fromRGBO(33, 150, 243, .7),
  700: Color.fromRGBO(33, 150, 243, .8),
  800: Color.fromRGBO(33, 150, 243, .9),
  900: Color.fromRGBO(33, 150, 243, 1),
};

const Map<int, Color> _darkGreenMap = {
  50: Color.fromRGBO(0, 66, 37, .1),
  100: Color.fromRGBO(0, 66, 37, .2),
  200: Color.fromRGBO(0, 66, 37, .3),
  300: Color.fromRGBO(0, 66, 37, .4),
  400: Color.fromRGBO(0, 66, 37, .5),
  500: Color.fromRGBO(0, 66, 37, .6),
  600: Color.fromRGBO(0, 66, 37, .7),
  700: Color.fromRGBO(0, 66, 37, .8),
  800: Color.fromRGBO(0, 66, 37, .9),
  900: Color.fromRGBO(0, 66, 37, 1),
};

const Map<int, Color> _purpleMap = {
  50: Color.fromRGBO(128, 32, 151, .1),
  100: Color.fromRGBO(128, 32, 151, .2),
  200: Color.fromRGBO(128, 32, 151, .3),
  300: Color.fromRGBO(128, 32, 151, .4),
  400: Color.fromRGBO(128, 32, 151, .5),
  500: Color.fromRGBO(128, 32, 151, .6),
  600: Color.fromRGBO(128, 32, 151, .7),
  700: Color.fromRGBO(128, 32, 151, .8),
  800: Color.fromRGBO(128, 32, 151, .9),
  900: Color.fromRGBO(128, 32, 151, 1),
};

const Map<int, Color> _orangeMap = {
  50: Color.fromRGBO(248, 102, 36, .1),
  100: Color.fromRGBO(248, 102, 36, .2),
  200: Color.fromRGBO(248, 102, 36, .3),
  300: Color.fromRGBO(248, 102, 36, .4),
  400: Color.fromRGBO(248, 102, 36, .5),
  500: Color.fromRGBO(248, 102, 36, .6),
  600: Color.fromRGBO(248, 102, 36, .7),
  700: Color.fromRGBO(248, 102, 36, .8),
  800: Color.fromRGBO(248, 102, 36, .9),
  900: Color.fromRGBO(248, 102, 36, 1),
};

const Map<int, Color> _pinkMap = {
  50: Color.fromRGBO(222, 13, 146, .1),
  100: Color.fromRGBO(222, 13, 146, .2),
  200: Color.fromRGBO(222, 13, 146, .3),
  300: Color.fromRGBO(222, 13, 146, .4),
  400: Color.fromRGBO(222, 13, 146, .5),
  500: Color.fromRGBO(222, 13, 146, .6),
  600: Color.fromRGBO(222, 13, 146, .7),
  700: Color.fromRGBO(222, 13, 146, .8),
  800: Color.fromRGBO(222, 13, 146, .9),
  900: Color.fromRGBO(222, 13, 146, 1),
};

const Map<int, Color> _redMap = {
  50: Color.fromRGBO(206, 45, 79, .1),
  100: Color.fromRGBO(206, 45, 79, .2),
  200: Color.fromRGBO(206, 45, 79, .3),
  300: Color.fromRGBO(206, 45, 79, .4),
  400: Color.fromRGBO(206, 45, 79, .5),
  500: Color.fromRGBO(206, 45, 79, .6),
  600: Color.fromRGBO(206, 45, 79, .7),
  700: Color.fromRGBO(206, 45, 79, .8),
  800: Color.fromRGBO(206, 45, 79, .9),
  900: Color.fromRGBO(206, 45, 79, 1),
};
