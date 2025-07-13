import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants.dart';
import '../../../models/grocery.dart';
import '../../../models/grocery_group.dart';
import '../../../providers/data_provider.dart';
import '../../../providers/state_providers.dart';
import '../../../services/lunix_api_service.dart';
import '../../../utils/of_context_mixin.dart';
import '../../../widgets/main_button.dart';
import '../../../widgets/progress_button.dart';

class EditGrocerySuggestionSheet extends ConsumerStatefulWidget {
  final Grocery grocery;
  const EditGrocerySuggestionSheet({
    required this.grocery,
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
  final AutoDisposeStateProvider<GroceryGroup?> _$selectedGroup =
      AutoDisposeStateProvider((_) => null);

  @override
  Widget build(BuildContext context) {
    final productGroups = ref.read(dataGroceryGroupsProvider) ?? [];
    final width = media.size.width > 599 ? 580.0 : media.size.width * 0.9;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (media.size.width - width) / 2,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: width * 0.4,
                  child: Text('edit_grocery_suggestion_group'.tr()),
                ),
                SizedBox(
                  width: width * 0.5,
                  child: Consumer(builder: (context, ref, _) {
                    final selectedGroup = ref.watch(_$selectedGroup);
                    return DropdownButton<GroceryGroup>(
                      value: selectedGroup,
                      dropdownColor: theme.scaffoldBackgroundColor,
                      items: productGroups
                          .map((group) => DropdownMenuItem<GroceryGroup>(
                                value: group,
                                child: Text(group.name),
                              ))
                          .toList(),
                      onChanged: (value) {
                        ref.read(_$selectedGroup.notifier).state = value;
                      },
                      isExpanded: true,
                    );
                  }),
                ),
              ],
            ),
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
              height: media.viewInsets.bottom == 0
                  ? kPadding * 2
                  : media.viewInsets.bottom,
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
    ref.read(_$buttonState.notifier).state = ButtonState.inProgress;
    try {
      final nextGrocery = widget.grocery.copyWith(group: selectedGroup.id);
      await LunixApiService.editGrocerySuggestion(
        oldGrocery: widget.grocery,
        grocery: nextGrocery,
        langCode: context.locale.languageCode,
        userId: ref.read(userProvider)?.id ?? '',
      );
      ref.read(_$buttonState.notifier).state = ButtonState.normal;
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } catch (e) {
      ref.read(_$buttonState.notifier).state = ButtonState.normal;
    }
  }
}
