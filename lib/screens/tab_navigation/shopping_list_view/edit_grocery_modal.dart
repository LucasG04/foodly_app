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

  EditGroceryModal(this.shoppingListId, [this.grocery]);

  @override
  _EditGroceryModalState createState() => _EditGroceryModalState();
}

class _EditGroceryModalState extends State<EditGroceryModal> {
  bool _isCreating;
  TextEditingController _nameController;
  TextEditingController _amountController;

  ButtonState _buttonState;
  String _errorText;

  @override
  void initState() {
    _isCreating = widget.grocery == null;
    _nameController = new TextEditingController(text: widget.grocery?.name);
    _amountController = new TextEditingController(text: widget.grocery?.amount);

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
            title: 'Name',
            placeholder: 'Brötchen',
            errorText: _errorText,
          ),
          SizedBox(
            width: width * 0.4,
            child: MainTextField(
              controller: _amountController,
              title: 'Menge',
              placeholder: '2 Packungen',
            ),
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
          SizedBox(
            height: kPadding * 2 + MediaQuery.of(context).viewInsets.bottom,
          ),
        ],
      ),
    );
  }

  void _saveGrocery() async {
    final grocery = _isCreating ? Grocery() : widget.grocery;
    grocery.name = _nameController.text.trim();
    grocery.amount = _amountController.text.trim();
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
      Navigator.maybePop(context);
    } else {
      setState(() {
        _errorText = 'Bitte trag einen Namen ein.';
        _buttonState = ButtonState.error;
      });
    }
  }
}
