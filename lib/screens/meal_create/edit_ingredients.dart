import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:foodly/models/ingredient.dart';
import 'package:foodly/screens/meal_create/edit_ingredient_modal.dart';

class EditIngredients extends StatefulWidget {
  final String title;
  final List<Ingredient> content;
  final void Function(List<Ingredient>) onChanged;

  EditIngredients({
    Key key,
    @required this.title,
    @required this.content,
    @required this.onChanged,
  }) : super(key: key);

  @override
  _EditIngredientsState createState() => _EditIngredientsState();
}

class _EditIngredientsState extends State<EditIngredients> {
  List<Ingredient> _content;

  @override
  void initState() {
    _content = widget.content ?? [];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          child: Text(
            widget.title,
            style: Theme.of(context).textTheme.bodyText1,
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _content.length,
          itemBuilder: (context, index) => ListTile(
            title: Text(_content[index].name),
            subtitle: Text('${_content[index].amount} ${_content[index].unit}'),
            trailing: IconButton(
              icon: Icon(EvaIcons.minusCircleOutline, color: Colors.black),
              onPressed: () {
                setState(() {
                  _content.removeAt(index);
                  widget.onChanged(_content);
                });
              },
            ),
            onTap: () => _editIngredient(_content[index], index),
            dense: true,
          ),
        ),
        ListTile(
          trailing: IconButton(
            icon: Icon(EvaIcons.plusCircleOutline, color: Colors.black),
            onPressed: () => _editIngredient(),
          ),
        ),
      ],
    );
  }

  void _editIngredient([Ingredient ingredient, int index]) async {
    final result = await showModalBottomSheet<Ingredient>(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(10.0),
        ),
      ),
      isScrollControlled: true,
      context: context,
      builder: (_) => EditIngredientModal(ingredient: ingredient),
    );

    if (result != null) {
      if (ingredient == null) {
        setState(() {
          _content.add(result);
          widget.onChanged(_content);
        });
      } else {
        setState(() {
          _content[index] = result;
          widget.onChanged(_content);
        });
      }
    }
  }
}
