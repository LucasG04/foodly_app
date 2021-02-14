import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

import '../../constants.dart';

class EditIngredients extends StatefulWidget {
  final List<String> ingredients;
  final void Function(List<String>) onChanged;

  EditIngredients({
    @required this.ingredients,
    @required this.onChanged,
  });

  @override
  _EditIngredientsState createState() => _EditIngredientsState();
}

class _EditIngredientsState extends State<EditIngredients> {
  List<String> _ingredients;

  @override
  void initState() {
    _ingredients = widget.ingredients ?? [];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          child: Text(
            'Zutaten:',
            style: Theme.of(context).textTheme.bodyText1,
          ),
        ),
        ..._ingredients.map((ingredient) {
          return Row(
            children: <Widget>[
              Expanded(
                child: _buildTextField(
                    ingredient, _ingredients.indexOf(ingredient), context),
              ),
              IconButton(
                  icon: Icon(EvaIcons.minusCircleOutline),
                  onPressed: () {
                    setState(() {
                      _ingredients.remove(ingredient);
                      widget.onChanged(_ingredients);
                    });
                  }),
            ],
          );
        }).toList(),
        Row(
          children: <Widget>[
            Spacer(),
            IconButton(
              icon: Icon(EvaIcons.plusCircleOutline),
              onPressed: () {
                setState(() {
                  _ingredients.add('');
                  widget.onChanged(_ingredients);
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  TextField _buildTextField(
      String ingredient, int index, BuildContext context) {
    final controller = TextEditingController(text: ingredient);
    controller.addListener(() {
      _ingredients[index] = controller.text;
      widget.onChanged(_ingredients);
    });

    return TextField(
      controller: controller,
      decoration: new InputDecoration(
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        contentPadding: EdgeInsets.only(
          left: kPadding / 2,
          bottom: 11,
          top: 11,
          right: 5,
        ),
        hintText: '...',
      ),
      style: Theme.of(context).textTheme.bodyText2,
    );
  }
}
