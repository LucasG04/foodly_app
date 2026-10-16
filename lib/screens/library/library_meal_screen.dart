import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_router.gr.dart';
import '../../constants.dart';
import '../../models/library_meal.dart';
import '../../providers/state_providers.dart';
import '../../services/lunix_api_service.dart';
import '../../utils/main_snackbar.dart';
import '../../utils/widget_utils.dart';
import '../../widgets/main_button.dart';
import '../../widgets/progress_button.dart';
import '../../widgets/small_circular_progress_indicator.dart';
import '../../widgets/small_number_input.dart';
import '../../widgets/user_information.dart';
import '../meal/border_icon.dart';
import '../meal/meal_detail_widgets.dart';
import '../tab_navigation/plan_view/plan_move_meal_modal.dart';
import 'library_action_bar.dart';
import 'library_import.dart';

/// A library recipe, laid out like MealScreen (shared parts in
/// `meal_detail_widgets.dart`), with "add to my meals" / "add & plan".
/// [onImported] tells the list which dish the plan now has.
class LibraryMealScreen extends ConsumerStatefulWidget {
  final String id;
  final String entry;
  final void Function(String libraryId, String mealId)? onImported;

  const LibraryMealScreen({
    required this.id,
    this.entry = 'library',
    this.onImported,
    super.key,
  });

  @override
  ConsumerState<LibraryMealScreen> createState() => _LibraryMealScreenState();
}

class _LibraryMealScreenState extends ConsumerState<LibraryMealScreen> {
  // Started on first build: the language comes from the context.
  late final Future<LibraryMeal?> _load = LunixApiService.getLibraryMeal(
    widget.id,
    libraryLang(context.locale.languageCode),
    ref.read(planProvider)?.id,
  ).then((meal) {
    // The bottom bar lives outside the FutureBuilder.
    if (mounted) {
      setState(() => _meal = meal);
    }
    return meal;
  });
  LibraryMeal? _meal;

  /// Servings the amounts are shown for; the recipe's until changed.
  int? _servings;
  ButtonState _buttonState = ButtonState.normal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The recipe scrolls behind the floating buttons.
      extendBody: true,
      body: FutureBuilder<LibraryMeal?>(
        future: _load,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: SmallCircularProgressIndicator());
          }
          return _meal == null ? _buildError() : _buildRecipe(_meal!);
        },
      ),
      bottomNavigationBar: _meal == null ? null : _buildActions(_meal!),
    );
  }

  Widget _buildError() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(kPadding),
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: const BorderIcon(
                height: 50,
                width: 50,
                child: Icon(EvaIcons.arrowBackOutline, color: Colors.black),
              ),
            ),
          ),
          UserInformation(
            assetPath: 'assets/images/undraw_void.png',
            title: context.tr('library_error_title'),
            message: context.tr('library_error_message'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipe(LibraryMeal meal) {
    final servings = _servings ?? meal.servings;
    final ingredients = meal.ingredients ?? const [];
    final instructions = meal.instructions ?? '';
    return CustomScrollView(
      slivers: [
        MealImageAppBar(imageUrl: meal.imageUrl, imageCredit: meal.imageCredit),
        const SliverToBoxAdapter(child: SizedBox(height: kPadding)),
        MealDetailBody(
          children: [
            MealHeadline(
              name: meal.name,
              source: meal.source,
              duration: meal.duration,
              kcal: meal.kcal,
              mealServings: meal.servings,
              servings: servings,
            ),
            const SizedBox(height: kPadding),
            MealTagRow(meal.tags),
            if (ingredients.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: kPadding),
                child: MealSection(
                  title: context.tr('meal_details_ingredient'),
                  trailing: SmallNumberInput(
                    value: servings,
                    minValue: 1,
                    maxValue: 30,
                    onChanged: (value) => setState(() => _servings = value),
                  ),
                  child: MealIngredientList(
                    ingredients: ingredients,
                    servings: servings,
                    mealServings: meal.servings,
                  ),
                ),
              ),
            if (instructions.isNotEmpty) ...[
              const SizedBox(height: kPadding),
              MealSection(
                title: context.tr('meal_details_instructions'),
                child: MealInstructions(instructions),
              ),
            ],
            if (meal.recipeCredit != null)
              _buildRecipeCredit(meal.recipeCredit!),
            const SizedBox(height: kPadding * 2),
          ],
        ),
        // Room for the buttons (extendBody adds their height to the padding).
        const SliverSafeArea(top: false, sliver: SliverToBoxAdapter()),
      ],
    );
  }

  /// "Recipe: Wikibooks · CC BY-SA 4.0" at the end of the page; opens the
  /// source page (which carries the license and the authors).
  Widget _buildRecipeCredit(RecipeCredit credit) {
    final source = credit.source == 'wikibooks' ? 'Wikibooks' : credit.source;
    final color =
        Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.5);
    return Padding(
      padding: const EdgeInsets.fromLTRB(kPadding, kPadding * 2, kPadding, 0),
      child: InkWell(
        onTap: () => launchUrl(Uri.parse(credit.link)),
        borderRadius: BorderRadius.circular(kRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: kPadding / 4),
          child: Row(
            children: [
              Icon(EvaIcons.externalLinkOutline, size: 16, color: color),
              const SizedBox(width: kPadding / 4),
              Expanded(
                child: Text(
                  context.tr('library_recipe_credit',
                      args: [source, credit.license]),
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(LibraryMeal meal) {
    return LibraryActionBar(
      child: meal.isImported
          ? MainButton(
              text: context.tr('library_open_in_meals'),
              width: double.infinity,
              floating: true,
              onTap: () => AutoRouter.of(context).popAndPush(
                MealScreenRoute(id: meal.importedMealId!),
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: MainButton(
                    text: context.tr('library_add'),
                    width: double.infinity,
                    floating: true,
                    isProgress: true,
                    buttonState: _buttonState,
                    onTap: _import,
                  ),
                ),
                const SizedBox(width: kPadding / 2),
                Tooltip(
                  message: context.tr('library_add_and_plan'),
                  child: MainButton(
                    iconData: EvaIcons.calendarOutline,
                    width: 60,
                    isSecondary: true,
                    floating: true,
                    onTap: () => _import(plan: true),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _import({bool plan = false}) async {
    if (_buttonState == ButtonState.inProgress) {
      return;
    }
    setState(() => _buttonState = ButtonState.inProgress);
    final result = await importFromLibrary(
      context,
      [widget.id],
      entry: widget.entry,
    );
    if (!mounted) {
      return;
    }
    setState(() => _buttonState = ButtonState.normal);
    final meal = result?.meals.firstOrNull;
    if (meal == null) {
      return;
    }
    setState(() => _meal = _meal!.withImported(meal.id!));
    widget.onImported?.call(widget.id, meal.id!);
    if (plan) {
      await WidgetUtils.showFoodlyBottomSheet<bool?>(
        context: context,
        builder: (_) => PlanMoveMealModal(isMoving: false, meal: meal),
      );
    } else {
      MainSnackbar(
        message: context.tr('library_added', args: [meal.name]),
        isSuccess: true,
      ).show(context);
    }
  }
}
