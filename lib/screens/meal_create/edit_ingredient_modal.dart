import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../models/ingredient.dart';
import '../../widgets/main_button.dart';
import '../../widgets/main_text_field.dart';

class EditIngredientModal extends StatefulWidget {
  final Ingredient? ingredient;

  EditIngredientModal({this.ingredient});

  @override
  _EditIngredientModalState createState() => _EditIngredientModalState();
}

class _EditIngredientModalState extends State<EditIngredientModal> {
  late bool _isCreating;
  TextEditingController? _nameController;
  TextEditingController? _amountController;
  TextEditingController? _unitController;
  FocusNode? _amountFocusNode;
  FocusNode? _unitFocusNode;

  String? _nameErrorText;

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
                _isCreating
                    ? 'ingredient_modal_title_add'.tr().toUpperCase()
                    : 'ingredient_modal_title_edit'.tr().toUpperCase(),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          MainTextField(
            controller: _nameController,
            title: 'ingredient_modal_name_title'.tr(),
            placeholder: 'ingredient_modal_name_placeholder'.tr(),
            errorText: _nameErrorText,
            textInputAction: TextInputAction.next,
            onSubmit: () => (_amountFocusNode!.requestFocus()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: width * 0.4,
                child: MainTextField(
                  controller: _amountController,
                  focusNode: _amountFocusNode,
                  title: 'ingredient_modal_amount_title'.tr(),
                  placeholder: '1',
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  onSubmit: () => (_unitFocusNode!.requestFocus()),
                ),
              ),
              SizedBox(
                width: width * 0.5,
                child: MainTextField(
                  controller: _unitController,
                  focusNode: _unitFocusNode,
                  title: 'ingredient_modal_unit_title'.tr(),
                  placeholder: 'ingredient_modal_unit_placeholder'.tr(),
                  onSubmit: _saveIngredient,
                ),
              ),
            ],
          ),
          SizedBox(height: kPadding * 2),
          Center(
            child: MainButton(
              text: 'save'.tr(),
              onTap: _saveIngredient,
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).viewInsets.bottom == 0
                ? kPadding * 2
                : MediaQuery.of(context).viewInsets.bottom,
          ),
        ],
      ),
    );
  }

  void _saveIngredient() async {
    final ingredient = _isCreating ? Ingredient() : widget.ingredient!;
    ingredient.name = _nameController!.text.trim();
    ingredient.amount =
        double.tryParse(_amountController!.text.trim().replaceAll(',', '.'));
    ingredient.unit = _unitController!.text.trim();

    if (ingredient.name!.isEmpty) {
      setState(() {
        _nameErrorText = 'ingredient_modal_error_name'.tr();
      });
      return;
    }

    if (ingredient.amount == null) {
      ingredient.amount = 0;
    }

    if (ingredient.unit == null) {
      ingredient.unit = '';
    }

    setState(() {
      _nameErrorText = null;
    });

    FocusScope.of(context).unfocus();

    Navigator.pop(context, ingredient);
  }
}
