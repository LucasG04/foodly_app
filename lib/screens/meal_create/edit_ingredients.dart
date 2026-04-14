import 'dart:async';

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
  bool _isDraggingIngredient = false;
  Ingredient? _draggedIngredient;
  Timer? _autoScrollTimer;
  double _dragDy = 0;

  @override
  void initState() {
    super.initState();
    _ingredients = List.from(widget.content);
    _groupOrder =
        widget.groupOrder != null ? List.from(widget.groupOrder!) : null;
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

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    // Use the State's own context (above ReorderableListView in the tree) so
    // that Scrollable.maybeOf finds the parent SingleChildScrollView instead of
    // the ReorderableListView, which has NeverScrollableScrollPhysics.
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) {
      return;
    }
    _autoScrollTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) {
        if (!mounted) {
          _stopAutoScroll();
          return;
        }
        const edgeThreshold = 100.0;
        const maxSpeed = 12.0;
        final screenHeight = MediaQuery.of(context).size.height;
        double delta = 0;
        if (_dragDy < edgeThreshold) {
          delta = -maxSpeed * (1 - _dragDy / edgeThreshold);
        } else if (_dragDy > screenHeight - edgeThreshold) {
          delta = maxSpeed * (1 - (screenHeight - _dragDy) / edgeThreshold);
        }
        if (delta == 0) {
          return;
        }
        final position = scrollable.position;
        final newOffset = (position.pixels + delta).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        );
        position.jumpTo(newOffset);
      },
    );
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
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

    final tiles = <Widget>[
      _buildGroupHeader(context, group, outerIndex),
      _buildInsertionPoint(context, group, 0),
      for (var i = 0; i < groupIngredients.length; i++) ...[
        _buildIngredientTile(context, groupIngredients[i]),
        _buildInsertionPoint(context, group, i + 1),
      ],
      if (!_isDraggingIngredient)
        Center(
          child: IconButton(
            icon: Icon(
              EvaIcons.plusCircleOutline,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            onPressed: () => _editIngredient(context, group: group),
          ),
        ),
    ];

    return Column(
      key: ValueKey(group ?? '__null__'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: tiles,
    );
  }

  Widget _buildIngredientTile(BuildContext context, Ingredient ingredient) {
    final amount =
        ConvertUtil.amountToString(ingredient.amount, ingredient.unit);

    return LayoutBuilder(
      key: ObjectKey(ingredient),
      builder: (context, constraints) {
        final tile = ListTile(
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

        return Opacity(
          opacity: _draggedIngredient == ingredient ? 0.3 : 1.0,
          child: LongPressDraggable<Ingredient>(
            data: ingredient,
            onDragStarted: () {
              setState(() {
                _isDraggingIngredient = true;
                _draggedIngredient = ingredient;
              });
              _startAutoScroll();
            },
            onDragUpdate: (details) {
              _dragDy = details.globalPosition.dy;
            },
            onDragEnd: (_) {
              _stopAutoScroll();
              setState(() {
                _isDraggingIngredient = false;
                _draggedIngredient = null;
              });
            },
            feedback: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(kRadius),
              child: SizedBox(
                width: constraints.maxWidth,
                child: ListTile(
                  dense: true,
                  title: Text(
                    ingredient.name ?? '',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  subtitle: amount.isNotEmpty ? Text(amount) : null,
                ),
              ),
            ),
            child: tile,
          ),
        );
      },
    );
  }

  Widget _buildInsertionPoint(
    BuildContext context,
    String? group,
    int insertAtIndex,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final dividerColor = Theme.of(context).dividerColor;

    return DragTarget<Ingredient>(
      onWillAcceptWithDetails: (_) => _isDraggingIngredient,
      onAcceptWithDetails: (details) => _onIngredientInsert(
        details.data,
        group,
        insertAtIndex,
      ),
      builder: (context, candidateData, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: candidateData.isNotEmpty ? 36 : 4,
        margin: const EdgeInsets.symmetric(
          horizontal: EditIngredients._listTileHorizontalPadding,
        ),
        decoration: BoxDecoration(
          color: candidateData.isNotEmpty
              ? colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(kRadius),
          border: (_isDraggingIngredient && candidateData.isEmpty)
              ? Border.all(
                  color: dividerColor.withValues(alpha: 0.3),
                  width: 0.5,
                )
              : null,
        ),
      ),
    );
  }

  void _onIngredientInsert(
      Ingredient ingredient, String? targetGroup, int insertAtIndex) {
    final groups = Ingredient.orderedGroupsSorted(_ingredients, _groupOrder);
    final newIngredients = <Ingredient>[];
    var targetHandled = false;

    for (final g in groups) {
      // All items in this group excluding dragged, sorted by sortKey.
      final groupItems = _ingredients
          .where((i) => i.group == g && i != ingredient)
          .toList()
        ..sort((a, b) => (a.sortKey ?? 9999).compareTo(b.sortKey ?? 9999));

      if (g == targetGroup) {
        targetHandled = true;
        groupItems.insert(
          insertAtIndex.clamp(0, groupItems.length),
          ingredient.copyWith(group: targetGroup),
        );
      }

      for (var i = 0; i < groupItems.length; i++) {
        newIngredients.add(groupItems[i].copyWith(sortKey: i));
      }
    }

    // Edge case: targetGroup had no ingredients (empty group not in orderedGroupsSorted result).
    if (!targetHandled) {
      newIngredients.add(ingredient.copyWith(group: targetGroup, sortKey: 0));
    }

    setState(() {
      _ingredients = newIngredients;
      _isDraggingIngredient = false;
      _draggedIngredient = null;
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
