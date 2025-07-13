import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../constants.dart';
import '../../../providers/state_providers.dart';
import '../../../services/lunix_api_service.dart';
import '../../../utils/basic_utils.dart';
import '../../../utils/convert_util.dart';
import '../../../utils/debouncer.dart';
import '../../../widgets/main_button.dart';
import '../../../widgets/main_text_field.dart';
import '../../../widgets/progress_button.dart';
import '../../../widgets/suggestion_tile.dart';
import '../models/grocery.dart';
import '../models/ingredient.dart';
import '../services/in_app_purchase_service.dart';
import '../utils/of_context_mixin.dart';

class IngredientEditModal extends ConsumerStatefulWidget {
  final Ingredient ingredient;
  final Future<void> Function(Ingredient)? onSaved;

  const IngredientEditModal({
    required this.ingredient,
    this.onSaved,
    super.key,
  });

  @override
  _IngredientEditModalState createState() => _IngredientEditModalState();
}

class _IngredientEditModalState extends ConsumerState<IngredientEditModal>
    with OfContextMixin {
  static final _log = Logger('IngredientEditModal');
  late Debouncer _nameDebouncer;
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _unitController;
  late FocusNode _nameFocusNode;
  late FocusNode _amountFocusNode;
  late FocusNode _unitFocusNode;

  late AutoDisposeStateProvider<ButtonState> _$buttonState;
  late AutoDisposeStateProvider<List<Grocery>> _$suggestions;
  String? _errorText;

  bool get showSuggestions => ref.read(InAppPurchaseService.$userIsSubscribed);

  @override
  void initState() {
    _nameDebouncer = Debouncer(milliseconds: 300);
    _nameController = TextEditingController(text: widget.ingredient.name);
    final amountString = ConvertUtil.amountToString(widget.ingredient.amount);
    _amountController = TextEditingController(text: amountString);
    _unitController = TextEditingController(text: widget.ingredient.unit);

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
    final width = media.size.width > 599 ? 580.0 : media.size.width * 0.9;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (media.size.width - width) / 2,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Consumer(builder: (_, ref, __) {
              return SizedBox(
                height: ref.watch(_$suggestions).isNotEmpty ? kPadding : 0,
              );
            }),
            Consumer(
              builder: (_, ref, __) => Wrap(
                spacing: kPadding / 2,
                runSpacing: kPadding / 2,
                children: ref.watch(_$suggestions).take(6).map((grocery) {
                  return SuggestionTile(
                    text: grocery.name.toString(),
                    onTap: () => _applyGroceryFromSuggestion(grocery),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: kPadding / 2),
            Consumer(builder: (_, ref, __) {
              ref.watch(_$buttonState);
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
                textCapitalization:
                    BasicUtils.getTextCapitalizationByLanguage(context),
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
                  buttonState: ref.watch(_$buttonState),
                  onTap: _saveGrocery,
                );
              }),
            ),
            SizedBox(
              height: media.viewInsets.bottom == 0
                  ? kPadding * 2
                  : media.viewInsets.bottom,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveGrocery() async {
    if (_formIsValid()) {
      ref.read(_$buttonState.notifier).state = ButtonState.inProgress;
      widget.ingredient.name = _nameController.text.trim();
      widget.ingredient.amount =
          double.tryParse(_amountController.text.trim().replaceAll(',', '.'));
      widget.ingredient.unit = _unitController.text.trim();

      if (widget.onSaved != null) {
        try {
          await widget.onSaved!(widget.ingredient);
        } catch (e) {
          _log.severe('Error while saving ingredient. ${widget.ingredient}', e);
        }
      }

      if (!mounted) {
        return;
      }

      ref.read(_$buttonState.notifier).state = ButtonState.normal;
      Navigator.of(context).pop(widget.ingredient);
    } else {
      _errorText = 'edit_grocery_modal_error'.tr();
      ref.read(_$buttonState.notifier).state = ButtonState.error;
    }
  }

  bool _formIsValid() {
    final name = _nameController.text.trim();
    return name.isNotEmpty;
  }

  Future<void> _loadSuggestions(String text) async {
    if (!showSuggestions) {
      return;
    }
    text = text.trim();
    if (text.length < 3) {
      if (ref.read(_$suggestions).isNotEmpty) {
        ref.read(_$suggestions.notifier).state = [];
      }
      return;
    }

    final suggestions = await LunixApiService.getGrocerySuggestions(
      text,
      BasicUtils.getActiveLanguage(context),
      ref.read(planProvider)?.id ?? '',
    );

    if (mounted) {
      ref.read(_$suggestions.notifier).state = suggestions;
    }
  }

  void _applyGroceryFromSuggestion(Grocery grocery) {
    _nameController.text = grocery.name.toString();

    if (grocery.group != null) {
      widget.ingredient.productGroup = grocery.group.toString();
    }

    ref.read(_$suggestions.notifier).state = [];
    _amountFocusNode.requestFocus();
  }

  void _onNameFocusChanged() {
    if (!_nameFocusNode.hasFocus) {
      ref.read(_$suggestions.notifier).state = [];
    } else if (ref.read(_$suggestions).isEmpty &&
        _nameController.text.isNotEmpty) {
      _nameDebouncer.run(() => _loadSuggestions(_nameController.text));
    }
  }
}
