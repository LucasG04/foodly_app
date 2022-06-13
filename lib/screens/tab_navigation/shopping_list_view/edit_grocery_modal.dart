import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../constants.dart';
import '../../../models/grocery.dart';
import '../../../services/shopping_list_service.dart';
import '../../../widgets/main_button.dart';
import '../../../widgets/main_text_field.dart';
import '../../../widgets/progress_button.dart';

class EditGroceryModal extends StatefulWidget {
  final String shoppingListId;
  final Grocery? grocery;

  const EditGroceryModal({
    required this.shoppingListId,
    this.grocery,
    Key? key,
  }) : super(key: key);

  @override
  State<EditGroceryModal> createState() => _EditGroceryModalState();
}

class _EditGroceryModalState extends State<EditGroceryModal> {
  late bool _isCreating;
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _unitController;
  late FocusNode _amountFocusNode;
  late FocusNode _unitFocusNode;

  late ButtonState _buttonState;
  String? _errorText;

  @override
  void initState() {
    _isCreating = widget.grocery == null;
    _nameController = TextEditingController(text: widget.grocery?.name);
    String amountString = widget.grocery?.amount?.toString() ?? '';
    amountString = amountString.endsWith('.0')
        ? amountString.substring(0, amountString.length - 2)
        : amountString;
    _amountController = TextEditingController(text: amountString);
    _unitController = TextEditingController(text: widget.grocery?.unit);

    _buttonState = ButtonState.normal;
    _amountFocusNode = FocusNode();
    _unitFocusNode = FocusNode();

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
                    ? 'edit_grocery_modal_add'
                    : 'edit_grocery_modal_edit',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ).tr(),
            ),
          ),
          MainTextField(
            controller: _nameController,
            title: 'edit_grocery_modal_ctrl_name_title'.tr(),
            placeholder: 'edit_grocery_modal_ctrl_name_placeholder'.tr(),
            errorText: _errorText,
            textInputAction: TextInputAction.next,
            onSubmit: () => _amountFocusNode.requestFocus(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: width * 0.4,
                child: MainTextField(
                  controller: _amountController,
                  focusNode: _amountFocusNode,
                  title: 'edit_grocery_modal_ctrl_amount_title'.tr(),
                  placeholder: '1',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  onSubmit: () => _unitFocusNode.requestFocus(),
                ),
              ),
              SizedBox(
                width: width * 0.5,
                child: MainTextField(
                  controller: _unitController,
                  focusNode: _unitFocusNode,
                  title: 'edit_grocery_modal_ctrl_unit_title'.tr(),
                  placeholder: 'edit_grocery_modal_ctrl_unit_placeholder'.tr(),
                  onSubmit: _saveGrocery,
                ),
              ),
            ],
          ),
          const SizedBox(height: kPadding * 2),
          Center(
            child: MainButton(
              text: 'save'.tr(),
              isProgress: true,
              buttonState: _buttonState,
              onTap: _saveGrocery,
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

  void _saveGrocery() async {
    final grocery = _isCreating ? Grocery() : widget.grocery!;
    grocery.name = _nameController.text.trim();
    grocery.amount =
        double.tryParse(_amountController.text.trim().replaceAll(',', '.')) ??
            0;
    grocery.unit = _unitController.text.trim();
    grocery.bought = _isCreating ? false : grocery.bought;

    if (grocery.name != null && grocery.name!.isNotEmpty) {
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
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
    } else {
      setState(() {
        _errorText = 'edit_grocery_modal_error'.tr();
        _buttonState = ButtonState.error;
      });
    }
  }
}
