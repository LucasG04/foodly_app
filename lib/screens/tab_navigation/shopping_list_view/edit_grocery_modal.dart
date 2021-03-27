import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../constants.dart';
import '../../../models/grocery.dart';
import '../../../services/shopping_list_service.dart';
import '../../../widgets/main_button.dart';
import '../../../widgets/main_text_field.dart';
import '../../../widgets/progress_button.dart';

class EditGroceryModal extends StatefulWidget {
  final String shoppingListId;
  final Grocery grocery;

  EditGroceryModal({
    @required this.shoppingListId,
    this.grocery,
  });

  @override
  _EditGroceryModalState createState() => _EditGroceryModalState();
}

class _EditGroceryModalState extends State<EditGroceryModal> {
  bool _isCreating;
  TextEditingController _nameController;
  TextEditingController _amountController;
  TextEditingController _unitController;
  FocusNode _amountFocusNode;
  FocusNode _unitFocusNode;

  ButtonState _buttonState;
  String _errorText;

  @override
  void initState() {
    _isCreating = widget.grocery == null;
    _nameController = new TextEditingController(text: widget.grocery?.name);
    _amountController =
        new TextEditingController(text: widget.grocery?.amount?.toString());
    _unitController = new TextEditingController(text: widget.grocery?.unit);

    _buttonState = ButtonState.normal;

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
            placeholder: 'Brötchen',
            errorText: _errorText,
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
                  onSubmit: _saveGrocery,
                ),
              ),
            ],
          ),
          SizedBox(height: kPadding * 2),
          Center(
            child: MainButton(
              text: 'Speichern',
              isProgress: true,
              buttonState: _buttonState,
              onTap: _saveGrocery,
            ),
          ),
          SizedBox(height: kPadding * 2),
        ],
      ),
    );
  }

  void _saveGrocery() async {
    final grocery = _isCreating ? Grocery() : widget.grocery;
    grocery.name = _nameController.text.trim();
    grocery.amount =
        double.tryParse(_amountController.text.trim().replaceAll(',', '.'));
    grocery.unit = _unitController.text.trim();
    grocery.bought = _isCreating ? false : grocery.bought;

    if (grocery.name.isNotEmpty) {
      setState(() {
        _buttonState = ButtonState.inProgress;
      });

      if (_isCreating) {
        await ShoppingListService.addGrocery(widget.shoppingListId, grocery);
      } else {
        await ShoppingListService.updateGrocery(widget.shoppingListId, grocery);
      }

      setState(() {
        _buttonState = ButtonState.normal;
      });
      Navigator.pop(context);
    } else {
      setState(() {
        _errorText = 'Bitte trag eine Bezeichnung ein.';
        _buttonState = ButtonState.error;
      });
    }
  }
}
