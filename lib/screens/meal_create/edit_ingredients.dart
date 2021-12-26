import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import '../../models/ingredient.dart';
import '../../utils/convert_util.dart';
import 'edit_ingredient_modal.dart';

class EditIngredients extends StatelessWidget {
  final String title;
  final List<Ingredient> content;
  final void Function(List<Ingredient>)? onChanged;

  const EditIngredients({
    Key? key,
    required this.title,
    required this.content,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyText1,
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

  void _editIngredient(BuildContext context,
      [Ingredient? ingredient, int? index]) async {
    final result = await showBarModalBottomSheet<Ingredient>(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(10.0),
        ),
      ),
      context: context,
      builder: (_) => EditIngredientModal(ingredient: ingredient),
    );

    if (result != null) {
      if (ingredient == null) {
        content.add(result);
        onChanged!(content);
      } else {
        content[index!] = result;
        onChanged!(content);
      }
    }
  }
}
