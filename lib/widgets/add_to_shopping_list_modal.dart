import 'package:auto_size_text/auto_size_text.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../constants.dart';
import '../models/grocery.dart';
import '../models/ingredient.dart';
import '../models/meal.dart';
import '../providers/state_providers.dart';
import '../services/meal_service.dart';
import '../services/shopping_list_service.dart';
import '../utils/analytics.dart';
import '../utils/basic_utils.dart';
import '../utils/convert_util.dart';
import '../utils/main_snackbar.dart';
import '../utils/of_context_mixin.dart';
import '../utils/widget_utils.dart';
import 'main_button.dart';
import 'progress_button.dart';
import 'sheet_header.dart';
import 'small_circular_progress_indicator.dart';
import 'small_number_input.dart';

class AddToShoppingListModal extends ConsumerStatefulWidget {
  final String? mealId;

  const AddToShoppingListModal({
    this.mealId,
    super.key,
  });

  @override
  _AddToShoppingListModalState createState() => _AddToShoppingListModalState();
}

class _AddToShoppingListModalState extends ConsumerState<AddToShoppingListModal>
    with OfContextMixin {
  static final _log = Logger('AddToShoppingListModal');

  final AutoDisposeStateProvider<ButtonState> _$buttonState =
      AutoDisposeStateProvider((_) => ButtonState.normal);
  // Starts true: _loadMeal only runs after the first frame.
  final AutoDisposeStateProvider<bool> _$loadingData =
      AutoDisposeStateProvider((_) => true);
  final AutoDisposeStateProvider<int> _$servings =
      AutoDisposeStateProvider((_) => 1);

  Meal? _meal;
  List<IngredientState>? _ingredientStates;

  @override
  void initState() {
    super.initState();
    BasicUtils.afterBuild(_loadMeal);
  }

  Future<void> _loadMeal() async {
    ref.read(_$loadingData.notifier).state = true;
    final meal = await MealService.getMealById(widget.mealId!);
    if (!mounted) {
      return;
    }
    if (meal != null) {
      _meal = meal;
      _ingredientStates = _getIngredientStates(meal);
      BasicUtils.afterBuild(
        () => ref.read(_$servings.notifier).state = meal.servings,
      );
    }
    ref.read(_$loadingData.notifier).state = false;
  }

  @override
  Widget build(BuildContext context) {
    final width = mediaSize.width > 599 ? 580.0 : mediaSize.width * 0.8;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (mediaSize.width - width) / 2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SheetHeader(title: context.tr('add')),
          const SizedBox(height: kPadding / 2),
          Consumer(builder: (context, ref, _) {
            final loadState = ref.watch(_$loadingData);
            if (loadState) {
              return _buildSingleChildWrapper(
                context: context,
                child: const SmallCircularProgressIndicator(),
              );
            } else if (_ingredientStates?.isNotEmpty ?? false) {
              return _buildIngredientCheckList();
            }
            return _buildSingleChildWrapper(
              context: context,
              child: Text(context.tr(_meal == null
                  ? 'try_again_later'
                  : 'add_to_shopping_list_modal_no_ingredients')),
            );
          }),
          Consumer(builder: (context, ref, _) {
            if (ref.watch(_$loadingData)) {
              return const SizedBox();
            }
            if (_meal == null) {
              return MainButton(
                height: 40.0,
                onTap: _loadMeal,
                text: context.tr('try_again'),
              );
            }
            if (_ingredientStates!.isEmpty) {
              return const SizedBox();
            }
            return MainButton(
              height: 40.0,
              onTap: _addToShoppingList,
              text: context.tr('add'),
              isProgress: true,
              buttonState: ref.watch(_$buttonState),
            );
          }),
          SizedBox(height: WidgetUtils.sheetBottomPadding(context)),
        ],
      ),
    );
  }

  Widget _buildSingleChildWrapper({
    required BuildContext context,
    required Widget child,
  }) {
    final height = mediaSize.height > 200 ? 200.0 : mediaSize.height * 0.4;
    return SizedBox(
      height: height,
      child: Center(child: child),
    );
  }

  Widget _buildIngredientCheckList() {
    if (_ingredientStates == null) {
      return const SizedBox();
    }
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            context.tr('add_to_shopping_list_modal_servings'),
            style: const TextStyle(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Consumer(
            builder: (context, ref, _) => SmallNumberInput(
              value: ref.watch(_$servings),
              onChanged: (value) {
                ref.read(_$servings.notifier).state = value;
              },
            ),
          ),
        ),
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: _ingredientStates!.length,
          itemBuilder: (context, index) {
            return Consumer(
              builder: (context, ref, _) {
                final isChecked =
                    ref.watch(_ingredientStates![index].$isChecked);
                final ingredient = _ingredientStates![index].ingredient;
                final amountString = ConvertUtil.amountToString(
                    ingredient.amount, ingredient.unit);
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: isChecked,
                  onChanged: (value) => ref
                      .read(_ingredientStates![index].$isChecked.notifier)
                      .state = value ?? true,
                  title: AutoSizeText(ingredient.name ?? ''),
                  subtitle: amountString.isEmpty
                      ? null
                      : _buildAmountSubtitle(ingredient),
                  activeColor: theme.primaryColor,
                );
              },
            );
          },
        ),
      ],
    );
  }

  Consumer _buildAmountSubtitle(Ingredient ingredient) {
    return Consumer(builder: (context, ref, _) {
      final servings = ref.watch(_$servings);
      final amount = ConvertUtil.calculateServingsAmount(
        requestedServings: servings,
        mealServings: _meal?.servings ?? 0,
        amount: ingredient.amount,
      );
      final amountWithServings =
          ConvertUtil.amountToString(amount, ingredient.unit);
      return Text(amountWithServings);
    });
  }

  void _close() {
    final sheet = ModalRoute.of(context);
    // An error snackbar from a failed attempt may still be on top.
    Navigator.of(context)
      ..popUntil((route) => route == sheet)
      ..pop();
  }

  List<IngredientState> _getIngredientStates(Meal meal) {
    return (meal.ingredients ?? [])
        .map((ingredient) => IngredientState(
              ingredient: ingredient,
              $isChecked: AutoDisposeStateProvider<bool>((ref) => true),
            ))
        .toList();
  }

  Future<void> _addToShoppingList() async {
    final meal = _meal!;
    ref.read(_$buttonState.notifier).state = ButtonState.inProgress;
    final shoppingListId = ref.read(shoppingListIdProvider);
    final checked = _ingredientStates!
        .where((state) => ref.read(state.$isChecked))
        .toList();
    // Scaled copies, so a retry after a failed add doesn't scale twice.
    final groceries = checked
        .map((state) => state.ingredient)
        .map((e) => Grocery(
              name: e.name,
              amount: ConvertUtil.calculateServingsAmount(
                requestedServings: ref.read(_$servings),
                mealServings: meal.servings,
                amount: e.amount,
              ).toDouble(),
              unit: e.unit,
              group: e.productGroup,
              lastBoughtEdited: DateTime.now(),
              sources: [
                GrocerySource(mealId: widget.mealId!, mealName: meal.name),
              ],
            ))
        .toList();

    try {
      await ShoppingListService.addGroceries(
        shoppingListId!,
        groceries,
        BasicUtils.getActiveLanguage(context),
      );
    } catch (e, s) {
      _log.severe('Adding ${groceries.length} groceries failed', e, s);
      if (!mounted) {
        return;
      }
      // The API lists the items it couldn't save; uncheck the saved ones so a
      // retry doesn't add them twice.
      final data = e is DioException ? e.response?.data : null;
      final failed = data is Map && data['failed'] is List
          ? List<int>.from(data['failed'] as List)
          : null;
      for (var i = 0; failed != null && i < checked.length; i++) {
        if (!failed.contains(i)) {
          ref.read(checked[i].$isChecked.notifier).state = false;
        }
      }
      ref.read(_$buttonState.notifier).state = ButtonState.normal;
      MainSnackbar(
        message: context.tr(failed == null
            ? 'general_error_message'
            : 'add_to_shopping_list_modal_partial_error'),
        isError: true,
      ).show(context);
      return;
    }
    logEvent(
      AnalyticsEvent.groceryAdd,
      {'source': 'from_meal', 'count': groceries.length.toString()},
    );
    if (!mounted) {
      return;
    }

    ref.read(_$buttonState.notifier).state = ButtonState.normal;
    _close();
  }
}

class IngredientState {
  final Ingredient ingredient;
  AutoDisposeStateProvider<bool> $isChecked;

  IngredientState({
    required this.ingredient,
    required this.$isChecked,
  });
}
