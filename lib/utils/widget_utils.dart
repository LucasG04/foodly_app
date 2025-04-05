// ignore_for_file: avoid_classes_with_only_static_members

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import '../services/in_app_purchase_service.dart';

class WidgetUtils {
  /// Shows a `BarModalBottomSheet` with rounded corners. Used as wrapper.
  static Future<T?> showFoodlyBottomSheet<T>({
    required BuildContext context,
    required Widget Function(BuildContext) builder,
    bool scrollable = false,
    bool unfocus = true,
  }) {
    if (!context.mounted) {
      return Future.value();
    }
    if (unfocus) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
    return showBarModalBottomSheet<T>(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(10.0),
        ),
      ),
      context: context,
      builder: !scrollable
          ? builder
          : (context) => SingleChildScrollView(
                controller: ModalScrollController.of(context),
                child: builder(context),
              ),
    );
  }

  /// Shows a edit dialog for a placeholder plan meal.
  static Future<String?> showPlaceholderEditDialog(
    BuildContext context, {
    String initialText = '',
    bool required = true,
  }) async {
    if (!context.mounted) {
      return Future.value();
    }
    final result = await showTextInputDialog(
      context: context,
      textFields: [
        DialogTextField(
          initialText: initialText,
          validator: required
              ? (value) => value!.isEmpty
                  ? 'meal_select_placeholder_dialog_placeholder'.tr()
                  : null
              : null,
        ),
      ],
      title: 'meal_select_placeholder_dialog_title'.tr(),
      cancelLabel: 'meal_select_placeholder_dialog_cancel'.tr(),
    );

    return result?.first;
  }

  static Consumer userIsSubscribed({
    required WidgetRef ref,
    bool negate = false,
    required Widget child,
  }) {
    return Consumer(builder: (context, ref, _) {
      final isSubscribed = ref.watch(InAppPurchaseService.$userIsSubscribed);
      final show = negate ? !isSubscribed : isSubscribed;
      return show ? child : const SizedBox();
    });
  }
}
