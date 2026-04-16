import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../models/ingredient.dart';
import '../../utils/convert_util.dart';
import '../../utils/widget_utils.dart';
import '../../widgets/ingredient_edit_modal.dart';

class EditIngredients extends StatefulWidget {
  final String title;
  final List<Ingredient> content;
  final List<String>? groupOrder;
  final void Function(List<Ingredient>, List<String>?) onChanged;

  static const _listTileHorizontalPadding = kPadding;

  const EditIngredients({
    super.key,
    required this.title,
    required this.content,
    required this.onChanged,
    this.groupOrder,
  });

  @override
  State<EditIngredients> createState() => _EditIngredientsState();
}

class _EditIngredientsState extends State<EditIngredients> {
  late List<Ingredient> _ingredients;
  List<String>? _groupOrder;

  @override
  void initState() {
    super.initState();
    _ingredients = _normalizeSortKeys(List.from(widget.content));
    _groupOrder =
        widget.groupOrder != null ? List.from(widget.groupOrder!) : null;
  }

  /// Assigns stable [Ingredient.sortKey] values to any ingredient whose
  /// sortKey is null, preserving the relative order within each group.
  List<Ingredient> _normalizeSortKeys(List<Ingredient> ingredients) {
    final groups = ingredients.map((i) => i.group).toSet();
    final result = List<Ingredient>.from(ingredients);
    for (final group in groups) {
      final groupItems = result
          .where((i) => i.group == group)
          .toList()
        ..sort((a, b) => (a.sortKey ?? 9999).compareTo(b.sortKey ?? 9999));
      for (var i = 0; i < groupItems.length; i++) {
        if (groupItems[i].sortKey == null) {
          final idx = result.indexOf(groupItems[i]);
          result[idx] = groupItems[i].copyWith(sortKey: i);
        }
      }
    }
    return result;
  }

  @override
  void didUpdateWidget(EditIngredients oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.content != oldWidget.content ||
        widget.groupOrder != oldWidget.groupOrder) {
      setState(() {
        _ingredients = List.from(widget.content);
        _groupOrder =
            widget.groupOrder != null ? List.from(widget.groupOrder!) : null;
      });
    }
  }

  void _notify() => widget.onChanged(_ingredients, _groupOrder);

  @override
  Widget build(BuildContext context) {
    final groups = Ingredient.orderedGroupsSorted(_ingredients, _groupOrder);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: Text(
            widget.title,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: groups.length,
          itemBuilder: (context, outerIndex) =>
              _buildGroupSection(context, groups[outerIndex], outerIndex),
          onReorder: _onGroupReorder,
          proxyDecorator: (child, index, animation) => Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(kRadius),
            clipBehavior: Clip.antiAlias,
            color: Theme.of(context).scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            child: Stack(
              children: [
                child,
                // Cover the Divider widget (height: 8) at the top of each
                // named-group header so the card looks clean while dragging.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 8,
                  child: ColoredBox(
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),
                ),
              ],
            ),
          ),
        ),
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

  Widget _buildGroupSection(
    BuildContext context,
    String? group,
    int outerIndex,
  ) {
    final groupIngredients = _ingredients
        .where((i) => i.group == group)
        .toList()
      ..sort((a, b) => (a.sortKey ?? 9999).compareTo(b.sortKey ?? 9999));

    return Column(
      key: ValueKey(group ?? '__null__'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGroupHeader(context, group, outerIndex),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: groupIngredients.length,
          proxyDecorator: (child, index, animation) => Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(kRadius),
            color: Theme.of(context).scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            child: child,
          ),
          itemBuilder: (context, index) => _buildIngredientTile(
            context,
            groupIngredients[index],
            index,
            key: ObjectKey(groupIngredients[index]),
          ),
          onReorder: (oldIndex, newIndex) =>
              _onIngredientReorder(group, oldIndex, newIndex),
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

  Widget _buildIngredientTile(
    BuildContext context,
    Ingredient ingredient,
    int index, {
    required Key key,
  }) {
    final amount =
        ConvertUtil.amountToString(ingredient.amount, ingredient.unit);

    return ListTile(
      key: key,
      leading: ReorderableDragStartListener(
        index: index,
        child: Icon(
          EvaIcons.menu,
          size: 18,
          color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.5),
        ),
      ),
      title: Text(ingredient.name ?? ''),
      subtitle: amount.isNotEmpty ? Text(amount) : null,
      trailing: IconButton(
        icon: Icon(
          EvaIcons.minusCircleOutline,
          color: Theme.of(context).iconTheme.color,
        ),
        onPressed: () {
          setState(() => _ingredients.remove(ingredient));
          _notify();
        },
      ),
      onTap: () => _editIngredient(context, existing: ingredient),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: EditIngredients._listTileHorizontalPadding,
      ),
    );
  }

  void _onIngredientReorder(String? group, int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex--;
    }
    final groupIngredients = _ingredients
        .where((i) => i.group == group)
        .toList()
      ..sort((a, b) => (a.sortKey ?? 9999).compareTo(b.sortKey ?? 9999));

    final ingredient = groupIngredients.removeAt(oldIndex);
    groupIngredients.insert(newIndex, ingredient);

    final reindexed = groupIngredients
        .asMap()
        .entries
        .map((e) => e.value.copyWith(sortKey: e.key))
        .toList();

    setState(() {
      _ingredients = [
        ..._ingredients.where((i) => i.group != group),
        ...reindexed,
      ];
    });
    _notify();
  }

  void _onGroupReorder(int oldIndex, int newIndex) {
    // The null group (index 0) is always first and cannot be moved.
    // Named groups cannot be moved before the null group.
    if (oldIndex == 0) {
      return;
    }
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    if (newIndex == 0) {
      newIndex = 1; // clamp: cannot go before null group
    }

    final groups = Ingredient.orderedGroupsSorted(_ingredients, _groupOrder);
    final updated = List<String?>.from(groups);
    final moved = updated.removeAt(oldIndex);
    updated.insert(newIndex, moved);

    setState(() {
      _groupOrder = updated.whereType<String>().toList();
    });
    _notify();
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
      final idx = _ingredients.indexOf(existing);
      if (idx < 0) {
        return;
      }
      result.group = existing.group;
      setState(() {
        _ingredients[idx] = result;
      });
    } else {
      setState(() {
        // When a brand-new group is created, add it to _groupOrder.
        if (result.group != null) {
          final currentOrder = _groupOrder ?? [];
          if (!currentOrder.contains(result.group)) {
            _groupOrder = [...currentOrder, result.group!];
          }
        }
        _ingredients.add(result);
      });
    }
    _notify();
  }

  Future<void> _addGroup(BuildContext context) async {
    final existingNamesLowered = _ingredients
        .map((i) => i.group?.toLowerCase())
        .whereType<String>()
        .toSet();

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
            if (existingNamesLowered.contains(value.trim().toLowerCase())) {
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
    final existingNamesLowered = _ingredients
        .map((i) => i.group?.toLowerCase())
        .whereType<String>()
        .toSet()
      ..remove(oldName.toLowerCase());

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
            if (existingNamesLowered.contains(value.trim().toLowerCase())) {
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

    setState(() {
      _ingredients = [
        for (final ingredient in _ingredients)
          ingredient.group == oldName
              ? ingredient.copyWith(group: newName)
              : ingredient,
      ];
      if (_groupOrder != null) {
        final idx = _groupOrder!.indexOf(oldName);
        if (idx >= 0) {
          _groupOrder![idx] = newName;
        }
      }
    });
    _notify();
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

    setState(() {
      _ingredients.removeWhere((i) => i.group == groupName);
      _groupOrder?.remove(groupName);
    });
    _notify();
  }

  Widget _buildGroupHeader(
      BuildContext context, String? group, int outerIndex) {
    if (group == null) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: EditIngredients._listTileHorizontalPadding,
      ),
      child: Column(
        children: [
          const Divider(height: 8, thickness: 0.5),
          Row(
            children: [
              ReorderableDragStartListener(
                index: outerIndex,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    EvaIcons.menu,
                    size: 18,
                    color: Theme.of(context)
                        .iconTheme
                        .color
                        ?.withValues(alpha: 0.5),
                  ),
                ),
              ),
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
}
