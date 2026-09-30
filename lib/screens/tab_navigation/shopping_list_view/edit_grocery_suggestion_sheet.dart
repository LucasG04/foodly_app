import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants.dart';
import '../../../models/grocery.dart';
import '../../../models/grocery_group.dart';
import '../../../providers/data_provider.dart';
import '../../../providers/state_providers.dart';
import '../../../services/lunix_api_service.dart';
import '../../../services/shopping_list_service.dart';
import '../../../utils/main_snackbar.dart';
import '../../../utils/of_context_mixin.dart';
import '../../../widgets/main_button.dart';
import '../../../widgets/progress_button.dart';
import '../../../widgets/tag_chip.dart';

class EditGrocerySuggestionSheet extends ConsumerStatefulWidget {
  final Grocery grocery;
  final String listId;
  const EditGrocerySuggestionSheet({
    required this.grocery,
    required this.listId,
    super.key,
  });

  @override
  ConsumerState<EditGrocerySuggestionSheet> createState() =>
      _EditGrocerySuggestionSheetState();
}

class _EditGrocerySuggestionSheetState
    extends ConsumerState<EditGrocerySuggestionSheet> with OfContextMixin {
  final AutoDisposeStateProvider<ButtonState> _$buttonState =
      AutoDisposeStateProvider((_) => ButtonState.normal);

  /// Starts on the grocery's current group.
  late final AutoDisposeStateProvider<GroceryGroup?> _$selectedGroup =
      AutoDisposeStateProvider(
    (ref) => ref
        .read(dataGroceryGroupsProvider)
        ?.where((group) => group.id == widget.grocery.group)
        .firstOrNull,
  );

  @override
  Widget build(BuildContext context) {
    final productGroups = ref.read(dataGroceryGroupsProvider) ?? [];
    final width = mediaSize.width > 599 ? 580.0 : mediaSize.width * 0.9;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (mediaSize.width - width) / 2,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: kPadding / 2),
            Text(
              widget.grocery.name.toString(),
              style: theme.textTheme.bodyLarge!.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: kPadding),
            Text('edit_grocery_suggestion_group'.tr()),
            const SizedBox(height: kPadding / 2),
            Consumer(builder: (context, ref, _) {
              final selectedGroup = ref.watch(_$selectedGroup);
              return Wrap(
                spacing: kPadding / 2,
                runSpacing: kPadding / 2,
                children: [
                  for (final group in productGroups)
                    TagChip(
                      label: group.name,
                      selected: group.id == selectedGroup?.id,
                      onTap: () =>
                          ref.read(_$selectedGroup.notifier).state = group,
                    ),
                ],
              );
            }),
            const SizedBox(height: kPadding * 2),
            Center(
              child: Consumer(builder: (_, ref, __) {
                return MainButton(
                  text: 'save'.tr(),
                  isProgress: true,
                  buttonState: ref.watch(_$buttonState),
                  onTap: _saveGrocery,
                );
              }),
            ),
            SizedBox(
              height: mediaViewInsets.bottom == 0
                  ? kPadding * 2
                  : mediaViewInsets.bottom,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveGrocery() async {
    final selectedGroup = ref.read(_$selectedGroup);
    if (selectedGroup == null) {
      return;
    }
    if (selectedGroup.id == widget.grocery.group) {
      Navigator.of(context).pop();
      return;
    }
    ref.read(_$buttonState.notifier).state = ButtonState.inProgress;
    final nextGrocery = widget.grocery.copyWith(group: selectedGroup.id);
    final langCode = context.locale.languageCode;
    // Independent of the list update, so both requests run in parallel.
    final suggestionSaved = LunixApiService.editGrocerySuggestion(
      oldGrocery: widget.grocery,
      grocery: nextGrocery,
      langCode: langCode,
      userId: ref.read(userProvider)?.id ?? '',
    ).then((_) => true, onError: (Object _) => false);
    try {
      await ShoppingListService.updateGrocery(
        widget.listId,
        nextGrocery,
        langCode,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ref.read(_$buttonState.notifier).state = ButtonState.normal;
      MainSnackbar(
        message: 'edit_grocery_suggestion_error'.tr(),
        isError: true,
      ).show(context);
      return;
    }
    final saved = await suggestionSaved;
    if (!mounted) {
      return;
    }
    ref.read(_$buttonState.notifier).state = ButtonState.normal;
    final navigator = Navigator.of(context);
    // The sheet may already be dismissed and animating out.
    if (ModalRoute.of(context)?.isCurrent ?? false) {
      navigator.pop();
    }
    if (!saved) {
      // Flushbar is a route, so show it after the sheet is popped.
      MainSnackbar(
        message: 'edit_grocery_suggestion_list_only'.tr(),
        isError: true,
      ).show(navigator.context);
    }
  }
}
