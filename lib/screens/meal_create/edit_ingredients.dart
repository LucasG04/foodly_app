import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

import '../../models/ingredient.dart';
import '../../utils/convert_util.dart';
import '../../utils/widget_utils.dart';
import '../../widgets/ingredient_edit_modal.dart';

class EditIngredients extends StatelessWidget {
  final String title;
  final List<Ingredient> content;
  final void Function(List<Ingredient>)? onChanged;

  const EditIngredients({
    super.key,
    required this.title,
    required this.content,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: content.length,
          itemBuilder: (context, index) {
            final String amount = ConvertUtil.amountToString(
                content[index].amount, content[index].unit);
            return ListTile(
              title: Text(content[index].name!),
              subtitle: amount.isNotEmpty ? Text(amount) : null,
              trailing: IconButton(
                icon: const Icon(EvaIcons.minusCircleOutline,
                    color: Colors.black),
                onPressed: () {
                  content.removeAt(index);
                  onChanged!(content);
                },
              ),
              onTap: () => _editIngredient(context, content[index], index),
              dense: true,
            );
          },
        ),
        Center(
          child: IconButton(
            icon: const Icon(EvaIcons.plusCircleOutline, color: Colors.black),
            onPressed: () => _editIngredient(context),
          ),
        ),
      ],
    );
  }

  Future<void> _editIngredient(BuildContext context,
      [Ingredient? ingredient, int? index]) async {
    final isCreating = ingredient == null || index == null;
    final result = await WidgetUtils.showFoodlyBottomSheet<Ingredient?>(
      context: context,
      builder: (_) => IngredientEditModal(
        ingredient: isCreating ? Ingredient() : ingredient,
      ),
    );

    if (result == null) {
      return;
    }

    if (isCreating) {
      content.add(result);
    } else {
      content[index] = result;
    }
    onChanged!(content);
  }
}
