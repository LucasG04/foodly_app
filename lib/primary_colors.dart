import 'package:flutter/material.dart';

MaterialColor get defaultPrimaryColor => primaryBlueColor;

MaterialColor primaryGreyColor = _swatch(0xFF334155);
MaterialColor primaryDarkBlueColor = _swatch(0xFF1E3A8A);
MaterialColor primaryBlueColor = _swatch(0xFF2563EB);
MaterialColor primaryDarkGreenColor = _swatch(0xFF004225);
MaterialColor primaryPurpleColor = _swatch(0xFF7C3AED);
MaterialColor primaryPinkColor = _swatch(0xFFDB2777);
MaterialColor primaryRedColor = _swatch(0xFFE03131);
MaterialColor primaryOrangeColor = _swatch(0xFFD9480F);

/// Previous palette values (still stored in some users' settings) mapped to
/// their replacements.
final Map<int, Color> legacyPrimaryColors = {
  0xFF3A3A3A: primaryGreyColor,
  0xFF072AC8: primaryDarkBlueColor,
  0xFF2196F3: primaryBlueColor,
  0xFF802097: primaryPurpleColor,
  0xFFDE0D92: primaryPinkColor,
  0xFFCE2D4F: primaryRedColor,
  0xFFF86624: primaryOrangeColor,
};

/// Shades 50–900 are the same color at 10–100 % opacity.
MaterialColor _swatch(int argb) {
  final color = Color(argb);
  return MaterialColor(argb, {
    for (var i = 0; i < 10; i++)
      i == 0 ? 50 : i * 100: color.withValues(alpha: (i + 1) / 10),
  });
}
