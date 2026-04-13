import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../models/ingredient.dart';
import '../../utils/convert_util.dart';
import '../../utils/widget_utils.dart';
import '../../widgets/ingredient_edit_modal.dart';

class EditIngredients extends StatelessWidget {
  final String title;
  final List<Ingredient> content;
  final void Function(List<Ingredient>) onChanged;

  static const _listTileHorizontalPadding = kPadding;

  const EditIngredients({
    super.key,
    required this.title,
    required this.content,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final groups = Ingredient.orderedGroups(content);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        ...groups.map((group) => _buildGroupSection(context, group)),
        Center(
          child: TextButton.icon(
            icon: const Icon(EvaIcons.plusCircleOutline),
            label: Text('ingredient_group_add_button'.tr()),
            onPressed: () => _addGroup(context),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupSection(BuildContext context, String? group) {
    final groupIngredients = content.where((i) => i.group == group).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGroupHeader(context, group),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: groupIngredients.length,
          itemBuilder: (context, index) {
            final ingredient = groupIngredients[index];
            final amount =
                ConvertUtil.amountToString(ingredient.amount, ingredient.unit);
            return ListTile(
              title: Text(ingredient.name ?? ''),
              subtitle: amount.isNotEmpty ? Text(amount) : null,
              trailing: IconButton(
                icon: Icon(EvaIcons.minusCircleOutline,
                    color: Theme.of(context).iconTheme.color),
                onPressed: () {
                  content.remove(ingredient);
                  onChanged(content);
                },
              ),
              onTap: () => _editIngredient(context, existing: ingredient),
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: _listTileHorizontalPadding),
            );
          },
        ),
        Center(
          child: IconButton(
            icon: Icon(
              EvaIcons.plusCircleOutline,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            onPressed: () => _editIngredient(context, group: group),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupHeader(BuildContext context, String? group) {
    if (group == null) {
      return const SizedBox();
    }
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: _listTileHorizontalPadding),
      child: Column(
        children: [
          const Divider(height: 8, thickness: 0.5),
          Row(
            children: [
              Expanded(
                child: Text(
                  group,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(EvaIcons.edit2Outline, size: 18),
                onPressed: () => _renameGroup(context, group),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(
                  EvaIcons.trash2Outline,
                  size: 18,
                  color: Colors.red,
                ),
                onPressed: () => _deleteGroup(context, group),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _editIngredient(
    BuildContext context, {
    Ingredient? existing,
    String? group,
  }) async {
    final result = await WidgetUtils.showFoodlyBottomSheet<Ingredient?>(
      context: context,
      builder: (_) => IngredientEditModal(
        ingredient: existing ?? Ingredient(group: group),
      ),
    );

    if (result == null) {
      return;
    }

    if (existing != null) {
      final idx = content.indexOf(existing);
      if (idx < 0) {
        // The parent screen (via Riverpod) may have rebuilt and replaced the
        // entire ingredients list with new object instances (e.g. after a
        // concurrent remove → onChanged → Meal.fromMap round-trip). The old
        // reference is no longer in the list, so we silently discard the edit
        // rather than risk corrupting state.
        return;
      }
      // IngredientEditModal mutates the passed ingredient in place and pops
      // the same reference, so result == existing here. We still reassign
      // result.group explicitly in case the modal is ever refactored to
      // return a fresh object.
      result.group = existing.group;
      content[idx] = result;
    } else {
      content.add(result);
    }
    onChanged(content);
  }

  Future<void> _addGroup(BuildContext context) async {
    final existingNames =
        content.map((i) => i.group).whereType<String>().toSet();

    final nameResult = await showTextInputDialog(
      context: context,
      title: 'ingredient_group_add_dialog_title'.tr(),
      cancelLabel: 'meal_select_placeholder_dialog_cancel'.tr(),
      textFields: [
        DialogTextField(
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'ingredient_group_name_required'.tr();
            }
            if (existingNames.contains(value.trim())) {
              return 'ingredient_group_name_duplicate'.tr();
            }
            return null;
          },
        ),
      ],
    );

    if (nameResult == null || nameResult.first.trim().isEmpty) {
      return;
    }
    final newGroupName = nameResult.first.trim();

    if (!context.mounted) {
      return;
    }
    await _editIngredient(context, group: newGroupName);
  }

  Future<void> _renameGroup(BuildContext context, String oldName) async {
    final existingNames = content
        .map((i) => i.group)
        .whereType<String>()
        .toSet()
      ..remove(oldName);

    final nameResult = await showTextInputDialog(
      context: context,
      title: 'ingredient_group_rename_dialog_title'.tr(),
      cancelLabel: 'meal_select_placeholder_dialog_cancel'.tr(),
      textFields: [
        DialogTextField(
          initialText: oldName,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'ingredient_group_name_required'.tr();
            }
            if (existingNames.contains(value.trim())) {
              return 'ingredient_group_name_duplicate'.tr();
            }
            return null;
          },
        ),
      ],
    );

    if (nameResult == null || nameResult.first.trim().isEmpty) {
      return;
    }
    final newName = nameResult.first.trim();
    if (newName == oldName) {
      return;
    }

    for (final ingredient in content) {
      if (ingredient.group == oldName) {
        ingredient.group = newName;
      }
    }
    onChanged(content);
  }

  Future<void> _deleteGroup(BuildContext context, String groupName) async {
    final confirm = await showOkCancelAlertDialog(
      context: context,
      title: 'ingredient_group_delete_dialog_title'.tr(),
      message: 'ingredient_group_delete_dialog_message'.tr(),
      okLabel: 'delete'.tr(),
      isDestructiveAction: true,
    );

    if (confirm != OkCancelResult.ok) {
      return;
    }

    content.removeWhere((i) => i.group == groupName);
    onChanged(content);
  }
}
