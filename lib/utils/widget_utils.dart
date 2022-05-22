// ignore_for_file: avoid_classes_with_only_static_members

import 'package:flutter/widgets.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class WidgetUtils {
  static Future<T?> showFoodlyBottomSheet<T>({
    required BuildContext context,
    required Widget Function(BuildContext) builder,
  }) {
    return showBarModalBottomSheet<T>(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(10.0),
        ),
      ),
      context: context,
      builder: builder,
    );
  }
}
