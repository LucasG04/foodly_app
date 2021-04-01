import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../models/ingredient.dart';
import '../../widgets/main_button.dart';
import '../../widgets/main_text_field.dart';

class EditIngredientModal extends StatefulWidget {
  final Ingredient ingredient;

  EditIngredientModal({this.ingredient});

  @override
  _EditIngredientModalState createState() => _EditIngredientModalState();
}

class _EditIngredientModalState extends State<EditIngredientModal> {
  bool _isCreating;
  TextEditingController _nameController;
  TextEditingController _amountController;
  TextEditingController _unitController;
  FocusNode _amountFocusNode;
  FocusNode _unitFocusNode;

  String _nameErrorText;
  String _amountErrorText;
  String _unitErrorText;

  @override
  void initState() {
    _isCreating = widget.ingredient == null;
    _nameController = new TextEditingController(text: widget.ingredient?.name);
    _amountController = new TextEditingController(
        text: widget.ingredient?.amount == null
            ? ''
            : widget.ingredient?.amount.toString());
    _unitController = new TextEditingController(text: widget.ingredient?.unit);

    _amountFocusNode = new FocusNode();
    _unitFocusNode = new FocusNode();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width > 599
        ? 580.0
        : MediaQuery.of(context).size.width * 0.8;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (MediaQuery.of(context).size.width - width) / 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: kPadding),
              child: Text(
                _isCreating ? 'HINZUFÜGEN' : 'BEARBEITEN',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          MainTextField(
            controller: _nameController,
            title: 'Bezeichnung',
            placeholder: 'Salz',
            errorText: _nameErrorText,
            textInputAction: TextInputAction.next,
            onSubmit: () => (_amountFocusNode.requestFocus()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: width * 0.4,
                child: MainTextField(
                  controller: _amountController,
                  focusNode: _amountFocusNode,
                  title: 'Menge',
                  placeholder: '1',
                  keyboardType: TextInputType.number,
                  errorText: _amountErrorText,
                  textInputAction: TextInputAction.next,
                  onSubmit: () => (_unitFocusNode.requestFocus()),
                ),
              ),
              SizedBox(
                width: width * 0.5,
                child: MainTextField(
                  controller: _unitController,
                  focusNode: _unitFocusNode,
                  title: 'Einheit',
                  placeholder: 'Prise',
                  errorText: _unitErrorText,
                  onSubmit: _saveIngredient,
                ),
              ),
            ],
          ),
          SizedBox(
            height: MediaQuery.of(context).viewInsets.bottom == 0
                ? kPadding * 2
                : MediaQuery.of(context).viewInsets.bottom,
          ),
          Center(
            child: MainButton(
              text: 'Speichern',
              onTap: _saveIngredient,
            ),
          ),
          SizedBox(height: kPadding * 2),
        ],
      ),
    );
  }

  void _saveIngredient() async {
    final ingredient = _isCreating ? Ingredient() : widget.ingredient;
    ingredient.name = _nameController.text.trim();
    ingredient.amount =
        double.tryParse(_amountController.text.trim().replaceAll(',', '.'));
    ingredient.unit = _unitController.text.trim();

    if (ingredient.name.isEmpty) {
      setState(() {
        _nameErrorText = 'Bitte trag eine Bezeichnung ein.';
      });
      return;
    }

    if (ingredient.amount == null) {
      ingredient.amount = 0;
      // setState(() {
      //   _amountErrorText = 'Zahl eintragen.';
      // });
      // return;
    }

    if (ingredient.name.isEmpty) {
      setState(() {
        _unitErrorText = 'Maßeinheit eintragen.';
      });
      return;
    }

    setState(() {
      _nameErrorText = null;
      _amountErrorText = null;
      _unitErrorText = null;
    });

    FocusScope.of(context).unfocus();

    Navigator.pop(context, ingredient);
  }
}
