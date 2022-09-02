import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants.dart';
import '../../../models/grocery.dart';
import '../../../providers/state_providers.dart';
import '../../../services/lunix_api_service.dart';
import '../../../services/shopping_list_service.dart';
import '../../../utils/basic_utils.dart';
import '../../../utils/convert_util.dart';
import '../../../utils/debouncer.dart';
import '../../../widgets/disposable_widget.dart';
import '../../../widgets/main_button.dart';
import '../../../widgets/main_text_field.dart';
import '../../../widgets/progress_button.dart';
import 'grocery_suggestion_tile.dart';

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

class _EditGroceryModalState extends State<EditGroceryModal>
    with DisposableWidget {
  late Debouncer _nameDebouncer;
  late bool _isCreating;
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _unitController;
  late FocusNode _nameFocusNode;
  late FocusNode _amountFocusNode;
  late FocusNode _unitFocusNode;

  late AutoDisposeStateProvider<ButtonState> _$buttonState;
  late AutoDisposeStateProvider<List<Grocery>> _$suggestions;
  String? _errorText;

  @override
  void initState() {
    _nameDebouncer = Debouncer(milliseconds: 300);
    _isCreating = widget.grocery == null;
    _nameController = TextEditingController(text: widget.grocery?.name);
    final amountString = ConvertUtil.amountToString(widget.grocery?.amount);
    _amountController = TextEditingController(text: amountString);
    _unitController = TextEditingController(text: widget.grocery?.unit);

    _$buttonState =
        StateProvider.autoDispose<ButtonState>((_) => ButtonState.normal);
    _$suggestions = StateProvider.autoDispose<List<Grocery>>((_) => []);
    _nameFocusNode = FocusNode();
    _amountFocusNode = FocusNode();
    _unitFocusNode = FocusNode();

    _nameFocusNode.addListener(() => _onNameFocusChanged());

    super.initState();
  }

  @override
  void dispose() {
    _nameDebouncer.dispose();
    _nameController.dispose();
    _amountController.dispose();
    _unitController.dispose();
    _nameFocusNode.dispose();
    _amountFocusNode.dispose();
    _unitFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width > 599
        ? 580.0
        : MediaQuery.of(context).size.width * 0.9;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (MediaQuery.of(context).size.width - width) / 2,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Consumer(builder: (_, ref, __) {
              return SizedBox(
                height: ref(_$suggestions).state.isNotEmpty ? kPadding : 0,
              );
            }),
            Consumer(builder: (_, ref, __) {
              return Wrap(
                spacing: kPadding / 2,
                runSpacing: kPadding / 2,
                children: ref(_$suggestions).state.take(6).map((grocery) {
                  return GrocerySuggestionTile(
                    grocery: grocery,
                    onTap: () => _applyGroceryFromSuggestion(grocery),
                  );
                }).toList(),
              );
            }),
            const SizedBox(height: kPadding / 2),
            Consumer(builder: (_, ref, __) {
              ref(_$buttonState);
              return MainTextField(
                controller: _nameController,
                focusNode: _nameFocusNode,
                title: 'edit_grocery_modal_ctrl_name_title'.tr(),
                placeholder: 'edit_grocery_modal_ctrl_name_placeholder'.tr(),
                errorText: _errorText,
                textInputAction: TextInputAction.next,
                onSubmit: () => _amountFocusNode.requestFocus(),
                onChange: (text) =>
                    _nameDebouncer.run(() => _loadSuggestions(text)),
              );
            }),
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
                    placeholder:
                        'edit_grocery_modal_ctrl_unit_placeholder'.tr(),
                    onSubmit: _saveGrocery,
                  ),
                ),
              ],
            ),
            const SizedBox(height: kPadding * 2),
            Center(
              child: Consumer(builder: (_, ref, __) {
                return MainButton(
                  text: 'save'.tr(),
                  isProgress: true,
                  buttonState: ref(_$buttonState).state,
                  onTap: _saveGrocery,
                );
              }),
            ),
            SizedBox(
              height: MediaQuery.of(context).viewInsets.bottom == 0
                  ? kPadding * 2
                  : MediaQuery.of(context).viewInsets.bottom,
            ),
          ],
        ),
      ),
    );
  }

  void _saveGrocery() async {
    final grocery = _isCreating
        ? Grocery(lastBoughtEdited: DateTime.now())
        : widget.grocery!;
    grocery.name = _nameController.text.trim();
    grocery.amount =
        double.tryParse(_amountController.text.trim().replaceAll(',', '.')) ??
            0;
    grocery.unit = _unitController.text.trim();
    grocery.bought = !_isCreating && grocery.bought;

    if (grocery.name != null && grocery.name!.isNotEmpty) {
      context.read(_$buttonState).state = ButtonState.inProgress;

      if (_isCreating) {
        await ShoppingListService.addGrocery(widget.shoppingListId, grocery);
      } else {
        await ShoppingListService.updateGrocery(widget.shoppingListId, grocery);
      }
      if (!mounted) {
        return;
      }
      context.read(_$buttonState).state = ButtonState.normal;
      Navigator.pop(context);
    } else {
      _errorText = 'edit_grocery_modal_error'.tr();
      context.read(_$buttonState).state = ButtonState.error;
    }
  }

  Future<void> _loadSuggestions(String text) async {
    text = text.trim();
    if (text.length < 3) {
      if (context.read(_$suggestions).state.isNotEmpty) {
        context.read(_$suggestions).state = [];
      }
      return;
    }

    final suggestions = await LunixApiService.getGrocerySuggestions(
      text,
      BasicUtils.getActiveLanguage(context),
      context.read(planProvider).state?.id ?? '',
    );

    if (mounted) {
      context.read(_$suggestions).state = suggestions;
    }
  }

  void _applyGroceryFromSuggestion(Grocery grocery) {
    _nameController.text = grocery.name.toString();

    if (grocery.amount != null) {
      _amountController.text = ConvertUtil.amountToString(grocery.amount);
    }

    if (grocery.unit != null) {
      _unitController.text = grocery.unit.toString();
    }

    context.read(_$suggestions).state = [];
    _amountFocusNode.requestFocus();
  }

  void _onNameFocusChanged() {
    if (!_nameFocusNode.hasFocus) {
      context.read(_$suggestions).state = [];
    } else if (context.read(_$suggestions).state.isEmpty &&
        _nameController.text.isNotEmpty) {
      _nameDebouncer.run(() => _loadSuggestions(_nameController.text));
    }
  }
}
