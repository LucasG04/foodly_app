import 'package:auto_route/auto_route.dart';
import 'package:badges/badges.dart' as badges;
import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keyboard_service/keyboard_service.dart';
import 'package:simple_icons/simple_icons.dart';

import '../../app_router.gr.dart';
import '../../constants.dart';
import '../../models/ai_usage.dart';
import '../../models/ingredient.dart';
import '../../models/meal.dart';
import '../../providers/state_providers.dart';
import '../../services/ai_usage_service.dart';
import '../../services/authentication_service.dart';
import '../../services/in_app_purchase_service.dart';
import '../../services/link_metadata_service.dart';
import '../../services/lunix_api_service.dart';
import '../../services/meal_service.dart';
import '../../services/rate_limit_exception.dart';
import '../../services/storage_service.dart';
import '../../utils/ai_usage_period.dart';
import '../../utils/basic_utils.dart';
import '../../utils/main_snackbar.dart';
import '../../utils/of_context_mixin.dart';
import '../../utils/widget_utils.dart';
import '../../widgets/get_premium_modal.dart';
import '../../widgets/link_preview.dart';
import '../../widgets/main_appbar.dart';
import '../../widgets/main_button.dart';
import '../../widgets/main_text_field.dart';
import '../../widgets/markdown_editor.dart';
import '../../widgets/meal_tag.dart';
import '../../widgets/options_modal/options_modal.dart';
import '../../widgets/options_modal/options_modal_option.dart';
import '../../widgets/progress_button.dart';
import '../../widgets/small_circular_progress_indicator.dart';
import '../../widgets/small_number_input.dart';
import '../../widgets/wrapped_image_picker/wrapped_image_picker.dart';
import 'edit_ingredients.dart';
import 'edit_list_content_modal.dart';
import 'import_modal.dart';
import 'kcal_estimate_modal.dart';
import 'save_changes_modal.dart';

class MealCreateScreen extends ConsumerStatefulWidget {
  final String id;
  final bool navigateToDetailOnCreate;

  const MealCreateScreen({
    required this.id,
    this.navigateToDetailOnCreate = false,
    super.key,
  });

  @override
  _MealCreateScreenState createState() => _MealCreateScreenState();
}

class _MealCreateScreenState extends ConsumerState<MealCreateScreen>
    with OfContextMixin {
  bool _mealSaved = false;
  bool _isFirstCall = true;
  final ScrollController _scrollController = ScrollController();

  /// ID for API rate limitng on kcal estimation for creating
  final String _generateKcalIdForApiOnCreate = UniqueKey().toString();

  late bool _isCreatingMeal;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _kcalController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  final TextEditingController _sourceController = TextEditingController();

  final _$buttonState =
      AutoDisposeStateProvider<ButtonState>((_) => ButtonState.normal);
  final _$isLoading = AutoDisposeStateProvider<bool>((_) => true);
  final _$isAiLoading = AutoDisposeStateProvider<bool>((_) => false);
  final _$sourceLinkMetadata = AutoDisposeStateProvider<String?>((_) => null);
  final _$updatedImage = AutoDisposeStateProvider<String?>((_) => null);
  late final AutoDisposeStateProvider<Meal> _$meal;

  Meal _originalMeal = Meal(name: '');
  List<String>? _existingMealTags;

  /// Holds the value of _$updatedImage, so it can be used in dispose
  String _updatedImageUrl = '';

  /// Init listeners, providers and fetch data
  @override
  void initState() {
    super.initState();
    final plan = ref.read(planProvider);
    _$meal = AutoDisposeStateProvider<Meal>(
      (_) => Meal(name: '', planId: plan?.id),
    );
    _fetchAllTagsIfNotExist();
  }

  /// Parse passed id and set initial values
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_isFirstCall) {
      _isFirstCall = false;
      _initialParseId().then((meal) {
        if (meal != null) {
          BasicUtils.afterBuild(() {
            ref.read(_$meal.notifier).state = meal;
            _onSourceTextChange(_sourceController.text);
          });
        }
        ref.read(_$isLoading.notifier).state = false;
      });
    }
  }

  @override
  void dispose() {
    _removeUnsavedStorageImage(_updatedImageUrl);
    // TODO: Error "Looking up a deactivated widget's ancestor is unsafe."
    // ref.read(initSearchWebImagePickerProvider.notifier).state = '';
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fullWidth = mediaSize.width > 699 ? 700.0 : mediaSize.width * 0.85;

    // ignore: deprecated_member_use, see https://github.com/flutter/flutter/issues/138614
    return WillPopScope(
      onWillPop: _pageWillPop,
      child: KeyboardAutoDismiss(
        scaffold: Scaffold(
          appBar: MainAppBar(
            text: _isCreatingMeal
                ? 'meal_create_title_add'.tr()
                : 'meal_create_title_edit'.tr(),
            scrollController: _scrollController,
            actions: [
              IconButton(
                icon: Icon(
                  EvaIcons.downloadOutline,
                  color: theme.textTheme.bodyLarge!.color,
                ),
                onPressed: () => _openImport(),
              ),
            ],
            onPopRejected: () {
              AutoRouter.of(context).push(const HomeScreenRoute());
            },
          ),
          body: Consumer(
            builder: (context, ref, _) {
              final isLoading = ref.watch(_$isLoading);
              return isLoading
                  ? const Center(child: SmallCircularProgressIndicator())
                  : SafeArea(
                      bottom: false,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: Center(
                          child: SizedBox(
                            width: fullWidth,
                            child: Column(
                              // ignore: avoid_redundant_argument_values
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                MainTextField(
                                  controller: _titleController,
                                  title: 'meal_create_title_title'.tr(),
                                  required: true,
                                ),
                                _buildDivider(),
                                Consumer(builder: (context, ref, _) {
                                  final ingredients = ref.watch(_$meal
                                      .select((m) => m.ingredients ?? []));
                                  final groupOrder = ref.watch(_$meal
                                      .select((m) => m.ingredientGroupOrder));
                                  return EditIngredients(
                                    content: ingredients,
                                    groupOrder: groupOrder,
                                    onChanged: (updatedIngredients,
                                            updatedGroupOrder) =>
                                        _changeMealValue((meal) {
                                      meal.ingredients = updatedIngredients;
                                      meal.ingredientGroupOrder =
                                          updatedGroupOrder;
                                    }),
                                    title: 'meal_create_ingredients_title'.tr(),
                                  );
                                }),
                                _buildDivider(),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'meal_create_servings_title',
                                        style: theme.textTheme.bodyLarge,
                                        overflow: TextOverflow.ellipsis,
                                      ).tr(),
                                    ),
                                    Consumer(builder: (context, ref, _) {
                                      final servings = ref.watch(
                                          _$meal.select((v) => v.servings));
                                      return SmallNumberInput(
                                        value: servings,
                                        onChanged: (value) => _changeMealValue(
                                            (meal) => meal.servings = value),
                                        minValue: 1,
                                        maxValue: 30,
                                      );
                                    }),
                                  ],
                                ),
                                _buildDivider(),
                                SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    'meal_create_instruction_title',
                                    style: theme.textTheme.bodyLarge,
                                  ).tr(),
                                ),
                                MarkdownEditor(
                                  textEditingController:
                                      _instructionsController,
                                  hintText:
                                      'meal_create_instruction_placeholder'
                                          .tr(),
                                ),
                                _buildDivider(),
                                Consumer(builder: (context, ref, _) {
                                  final mealImageUrl = ref
                                      .watch(_$meal.select((m) => m.imageUrl));
                                  final updatedImageUrl =
                                      ref.watch(_$updatedImage);
                                  return WrappedImagePicker(
                                    key: ValueKey(
                                        updatedImageUrl ?? mealImageUrl),
                                    imageUrl: updatedImageUrl ?? mealImageUrl,
                                    onPick: _pickNewImage,
                                    onOpen: _onOpenImagePicker,
                                  );
                                }),
                                _buildDivider(),
                                MainTextField(
                                  controller: _sourceController,
                                  title: 'meal_create_source_title'.tr(),
                                  placeholder:
                                      'meal_create_source_placeholder'.tr(),
                                  onChange: (newText) =>
                                      _onSourceTextChange(newText.trim()),
                                ),
                                Row(
                                  children: [
                                    Flexible(
                                      flex: 3,
                                      child: MainTextField(
                                        controller: _kcalController,
                                        title: 'meal_create_kcal_title'.tr(),
                                        placeholder: '450',
                                        textAlign: TextAlign.end,
                                        keyboardType: TextInputType.number,
                                        suffix: _buildKcalAiButton(),
                                      ),
                                    ),
                                    const SizedBox(width: kPadding),
                                    Flexible(
                                      flex: 2,
                                      child: MainTextField(
                                        controller: _durationController,
                                        title:
                                            'meal_create_duration_title'.tr(),
                                        placeholder: '10',
                                        textAlign: TextAlign.end,
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: kPadding / 2,
                                  ),
                                  child: Consumer(
                                    builder: (_, ref, __) => LinkPreview(
                                      ref.watch(_$sourceLinkMetadata) ?? '',
                                    ),
                                  ),
                                ),
                                _buildDivider(),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('meal_create_tags_title'.tr()),
                                    IconButton(
                                      onPressed: _openMealTagEdit,
                                      icon: const Icon(EvaIcons.edit2Outline),
                                    )
                                  ],
                                ),
                                Consumer(builder: (context, ref, _) {
                                  final tags =
                                      ref.watch(_$meal.select((m) => m.tags));
                                  return tags == null || tags.isEmpty
                                      ? const Text('-')
                                      : SizedBox(
                                          width: double.infinity,
                                          child: Wrap(
                                            clipBehavior: Clip.hardEdge,
                                            children: tags
                                                .map((e) => MealTag(e))
                                                .toList(),
                                          ),
                                        );
                                }),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: kPadding,
                                  ),
                                  child: Consumer(builder: (context, ref, _) {
                                    final state = ref.watch(_$buttonState);
                                    return MainButton(
                                      text: 'save'.tr(),
                                      onTap: _saveMeal,
                                      isProgress: true,
                                      buttonState: state,
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildKcalAiButton() {
    return Consumer(
      builder: (context, ref, _) {
        final isSubscribed = ref.watch(InAppPurchaseService.$userIsSubscribed);
        final isAiLoading = ref.watch(_$isAiLoading);
        final usage = ref.watch(aiUsageProvider).valueOrNull;
        final canUse = usage?.canUseKcal(isSubscribed) ?? true;
        final showBadge = !isSubscribed && usage != null;

        Widget aiButton = IconButton(
          onPressed: canUse ? _estimateKcal : _showAiQuotaExhausted,
          icon: Icon(
            Icons.auto_awesome,
            color: canUse ? Theme.of(context).colorScheme.primary : Colors.grey,
          ),
          tooltip: showBadge
              ? 'ai_usage_remaining'.tr(args: [usage.kcalRemaining.toString()])
              : 'meal_create_kcal_ai_button'.tr(),
        );
        if (showBadge) {
          aiButton = badges.Badge(
            badgeStyle: const badges.BadgeStyle(badgeColor: kPremiumColor),
            position: badges.BadgePosition.topEnd(top: -4, end: -2),
            badgeContent: Text(
              usage.kcalRemaining.toString(),
              style: const TextStyle(color: kPrimaryColor, fontSize: 10),
            ),
            child: aiButton,
          );
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isAiLoading
              ? const SizedBox(
                  key: ValueKey('loader'),
                  width: 48,
                  height: 48,
                  child: Center(
                    child: SmallCircularProgressIndicator(),
                  ),
                )
              : KeyedSubtree(
                  key: const ValueKey('ai'),
                  child: aiButton,
                ),
        );
      },
    );
  }

  void _showAiQuotaExhausted() {
    final resetDate = DateFormat.yMMMMd(context.locale.toLanguageTag())
        .format(AiUsagePeriod.currentPeriodEnd());
    MainSnackbar(
      message: 'ai_usage_exhausted'.tr(args: [resetDate]),
      isError: true,
      action: TextButton(
        onPressed: _openGetPremium,
        child: Text('ai_usage_upgrade'.tr()),
      ),
    ).show(context);
  }

  Center _buildDivider() => Center(
        child: SizedBox(
          width: mediaSize.width > 699 ? 650.0 : mediaSize.width * 0.8,
          child: const Divider(),
        ),
      );

  Future<Meal?> _initialParseId() async {
    if (widget.id == 'create') {
      _isCreatingMeal = true;
      final meal = ref.read(_$meal.notifier).state;
      meal.ingredients = [];
      meal.tags = [];
      return meal;
    } else if (widget.id.startsWith('https')) {
      // Shared URL: open the import modal pre-filled, choosing the type by host.
      _isCreatingMeal = true;
      final url = Uri.decodeComponent(widget.id);
      final type = BasicUtils.isValidInstagramUrl(url)
          ? ImportType.instagram
          : ImportType.link;
      final meal = ref.read(_$meal.notifier).state;
      meal.ingredients = [];
      meal.tags = [];
      BasicUtils.afterBuild(() => _startSharedUrlImport(type, url));
      return meal;
    } else {
      _isCreatingMeal = false;
      final meal = await MealService.getMealById(widget.id);
      if (meal != null) {
        _titleController.text = meal.name;
        _sourceController.text = meal.source ?? '';
        _onSourceTextChange(meal.source ?? '');
        _durationController.text = (meal.duration ?? '').toString();
        _kcalController.text = (meal.kcal ?? '').toString();
        _instructionsController.text = meal.instructions ?? '';
        meal.ingredients = meal.ingredients ?? [];
        meal.tags = meal.tags ?? [];
        _originalMeal = Meal.fromMap(meal.id, meal.toMap());
        ref.read(_$meal.notifier).state = meal;
      }
      return meal;
    }
  }

  Future<bool> _pageWillPop() async {
    if (ref.read(_$isLoading.notifier).state ||
        _mealSaved ||
        !_formHasChanges()) {
      return true;
    }

    final result = await WidgetUtils.showFoodlyBottomSheet<SaveChangesResult?>(
      context: context,
      builder: (_) => const SaveChangesModal(),
    );

    if (result == SaveChangesResult.save && _formIsValid()) {
      ref.read(_$isLoading.notifier).state = true;
      final savedMealSuccessful = await _saveMeal();
      ref.read(_$isLoading.notifier).state = false;
      return savedMealSuccessful;
    } else if (result == SaveChangesResult.discard) {
      return true;
    } else {
      return false;
    }
  }

  void _pickNewImage(String imageUrl) {
    final meal = ref.read(_$meal.notifier).state;
    final updatedImage = ref.read(_$updatedImage.notifier).state;
    if (meal.imageUrl != updatedImage &&
        BasicUtils.isStorageMealImage(updatedImage)) {
      StorageService.removeFile(updatedImage);
    }

    ref.read(_$updatedImage.notifier).state = imageUrl;
    _updatedImageUrl = imageUrl;
  }

  Future<bool> _saveMeal() async {
    ref.read(_$buttonState.notifier).state = ButtonState.inProgress;

    final updatedImage = ref.read(_$updatedImage.notifier).state;
    final meal = ref.read(_$meal.notifier).state;
    meal.name = _titleController.text;
    meal.source = _sourceController.text;
    meal.duration = int.tryParse(_durationController.text.trim());
    meal.kcal = int.tryParse(_kcalController.text.trim());
    meal.instructions = _instructionsController.text;
    meal.createdBy = _isCreatingMeal
        ? AuthenticationService.currentUser!.uid
        : meal.createdBy;
    meal.planId = ref.read(planProvider)!.id;

    if (!_formIsValid()) {
      MainSnackbar(
        message: 'meal_create_error_missing_input'.tr(),
        isError: true,
      ).show(context);
      ref.read(_$buttonState.notifier).state = ButtonState.error;
      return false;
    }

    final useLinkImage =
        !_imageIsValid(meal.imageUrl) && !_imageIsValid(updatedImage);

    if (useLinkImage) {
      final imageOfSource =
          (await LinkMetadataService.get(meal.source!))?.image;
      if (_imageIsValid(imageOfSource)) {
        meal.imageUrl = imageOfSource;
      }
    } else if (_imageIsValid(updatedImage)) {
      final shouldRemoveCurrent = meal.imageUrl != updatedImage &&
          BasicUtils.isStorageMealImage(meal.imageUrl);
      if (shouldRemoveCurrent) {
        StorageService.removeFile(meal.imageUrl);
      }
      meal.imageUrl = updatedImage;
    }

    try {
      final newMeal = _isCreatingMeal
          ? await MealService.createMeal(meal)
          : await MealService.updateMeal(meal);
      ref.read(_$buttonState.notifier).state = ButtonState.normal;
      _mealSaved = true;
      if (!mounted) {
        return false;
      }
      LunixApiService.setGroupsForIngredients(
        newMeal?.id ?? '',
        BasicUtils.getActiveLanguage(context),
      );
      BasicUtils.emitMealsChanged(ref, newMeal?.id ?? '');
      if (_isCreatingMeal &&
          widget.navigateToDetailOnCreate &&
          newMeal?.id != null) {
        // Replace this screen with the detail view — no pop means no flash
        // of the underlying list.
        AutoRouter.of(context).replace(MealScreenRoute(id: newMeal!.id!));
      } else {
        AutoRouter.of(context).pop();
      }
      return true;
    } catch (e) {
      if (!mounted) {
        return false;
      }
      MainSnackbar(
        message: 'meal_create_error_unknown'.tr(),
        isError: true,
      ).show(context);
      ref.read(_$buttonState.notifier).state = ButtonState.error;
      return false;
    }
  }

  bool _formIsValid() {
    return _titleController.text.isNotEmpty;
  }

  bool _imageIsValid(String? image) {
    return image != null && image.isNotEmpty;
  }

  bool _formHasChanges() {
    final meal = ref.read(_$meal.notifier).state;
    return _titleController.text != _originalMeal.name ||
        _sourceController.text != (_originalMeal.source ?? '') ||
        _durationController.text != (_originalMeal.duration ?? '').toString() ||
        _kcalController.text != (_originalMeal.kcal ?? '').toString() ||
        _instructionsController.text != (_originalMeal.instructions ?? '') ||
        ref.read(_$updatedImage.notifier).state != null ||
        !_ingredientsEquals(
            meal.ingredients ?? [], _originalMeal.ingredients ?? []) ||
        !listEquals<String>(meal.tags ?? [], _originalMeal.tags ?? []) ||
        !listEquals<String>(meal.ingredientGroupOrder ?? [],
            _originalMeal.ingredientGroupOrder ?? []);
  }

  void _openImport() {
    final isSubscribed = ref.read(InAppPurchaseService.$userIsSubscribed);
    final usage = ref.read(aiUsageProvider).valueOrNull;
    final showQuotaBadges = !isSubscribed && usage != null;
    WidgetUtils.showFoodlyBottomSheet<void>(
      context: context,
      builder: (_) => OptionsSheet(
        options: [
          OptionsSheetOptions(
            icon: EvaIcons.link2Outline,
            title: 'import_options_link'.tr(),
            onTap: () => _openImportModal(ImportType.link),
          ),
          OptionsSheetOptions(
            icon: EvaIcons.fileTextOutline,
            title: 'import_options_text'.tr(),
            trailing:
                showQuotaBadges ? _buildQuotaPill(usage.textRemaining) : null,
            onTap: _onTapTextImport,
          ),
          OptionsSheetOptions(
            icon: SimpleIcons.instagram,
            title: 'import_options_instagram'.tr(),
            trailing: showQuotaBadges
                ? _buildQuotaPill(usage.instagramRemaining)
                : null,
            onTap: _onTapInstagramImport,
          ),
        ],
      ),
    );
  }

  void _onTapTextImport() {
    final isSubscribed = ref.read(InAppPurchaseService.$userIsSubscribed);
    final usage = ref.read(aiUsageProvider).valueOrNull;
    final canUse = usage?.canUseText(isSubscribed) ?? true;
    if (!canUse) {
      _showAiQuotaExhausted();
      return;
    }
    _openImportModal(ImportType.text);
  }

  void _onTapInstagramImport() {
    final isSubscribed = ref.read(InAppPurchaseService.$userIsSubscribed);
    final usage = ref.read(aiUsageProvider).valueOrNull;
    final canUse = usage?.canUseInstagram(isSubscribed) ?? true;
    if (!canUse) {
      _showAiQuotaExhausted();
      return;
    }
    _openImportModal(ImportType.instagram);
  }

  Widget _buildQuotaPill(int remaining) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: kPremiumColor,
        borderRadius: BorderRadius.circular(kRadius),
      ),
      child: Text(
        remaining.toString(),
        style: const TextStyle(
          color: kPrimaryColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Opens the import modal for a shared URL, gating Instagram imports behind
  /// the AI usage quota just like the in-app Instagram import button. Awaits the
  /// first usage value: on the share flow this runs right after the screen opens,
  /// before the streamed usage has arrived, so reading it synchronously would
  /// see null and skip the gate.
  Future<void> _startSharedUrlImport(ImportType type, String url) async {
    if (type == ImportType.instagram) {
      final isSubscribed = ref.read(InAppPurchaseService.$userIsSubscribed);
      AiUsage? usage;
      try {
        usage = await ref
            .read(aiUsageProvider.future)
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        // On cold start the Firestore connection may not be ready yet,
        // causing the stream to hang or error. Default to null so the
        // canUse check below allows access.
      }
      if (!mounted) {
        return;
      }
      final canUse = usage?.canUseInstagram(isSubscribed) ?? true;
      if (!canUse) {
        _showAiQuotaExhausted();
        return;
      }
    }
    _openImportModal(type, initialUrl: url);
  }

  void _openImportModal(ImportType type, {String? initialUrl}) async {
    final result = await WidgetUtils.showFoodlyBottomSheet<Meal>(
      context: context,
      builder: (_) => ImportModal(type: type, initialUrl: initialUrl),
    );

    if (result != null && mounted) {
      final meal = ref.read(_$meal.notifier).state;
      _titleController.text = result.name;
      meal.name = result.name;
      meal.imageUrl = result.imageUrl;
      _sourceController.text = result.source ?? '';
      _onSourceTextChange(result.source ?? '');
      _durationController.text = (result.duration ?? '').toString();
      _kcalController.text = (result.kcal ?? '').toString();
      _instructionsController.text = result.instructions ?? '';
      meal.instructions = result.instructions;
      meal.ingredients = result.ingredients ?? [];
      meal.servings = result.servings < 1 ? 1 : result.servings;
      meal.tags = result.tags;
      ref.read(_$meal.notifier).state = Meal.fromMap(meal.id, meal.toMap());

      // A text/Instagram import that returned a meal means a successful AI
      // generation — count it against the free quota (premium is unlimited).
      if (type == ImportType.text || type == ImportType.instagram) {
        final isSubscribed = ref.read(InAppPurchaseService.$userIsSubscribed);
        final userId = ref.read(userProvider)?.id;
        if (!isSubscribed && userId != null) {
          if (type == ImportType.instagram) {
            await AiUsageService.incrementInstagram(userId);
          } else {
            await AiUsageService.incrementText(userId);
          }
        }
      }
    }
  }

  void _openMealTagEdit() async {
    _existingMealTags ??=
        await MealService.getAllTags(ref.read(planProvider)!.id!);
    final allTags = [
      ..._existingMealTags ?? <String>[],
      ..._getMissingTagsInExisting()
    ];
    if (!mounted) {
      return;
    }
    final result = await WidgetUtils.showFoodlyBottomSheet<List<String>>(
      context: context,
      builder: (_) => EditListContentModal(
        title: 'meal_create_tags_title'.tr(),
        selectedContent: ref.read(_$meal.notifier).state.tags ?? [],
        allContent: allTags,
        textFieldInfo: 'meal_create_edit_tags_info'.tr(),
      ),
    );

    if (result != null) {
      _changeMealValue((meal) => meal.tags = result);
    }
  }

  List<String> _getMissingTagsInExisting() {
    final meal = ref.read(_$meal.notifier).state;
    if (meal.tags == null || meal.tags!.isEmpty) {
      return [];
    }
    if (_existingMealTags == null || _existingMealTags!.isEmpty) {
      return meal.tags!;
    }
    return meal.tags!
        .where((tag) => !_existingMealTags!.contains(tag))
        .toList();
  }

  void _fetchAllTagsIfNotExist() async {
    final plan = ref.read(planProvider);
    if (plan == null || plan.id == null || _existingMealTags != null) {
      return;
    }
    _existingMealTags = await MealService.getAllTags(plan.id!);
  }

  bool _ingredientsEquals(List<Ingredient>? a, List<Ingredient>? b) {
    if (a == null) {
      return b == null;
    }
    if (b == null || a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i].amount != b[i].amount ||
          a[i].name != b[i].name ||
          a[i].unit != b[i].unit ||
          a[i].group != b[i].group ||
          a[i].sortKey != b[i].sortKey) {
        return false;
      }
    }
    return true;
  }

  void _onSourceTextChange(String newText) {
    if (!mounted) {
      return;
    }

    if (newText.isEmpty) {
      ref.read(_$sourceLinkMetadata.notifier).state = null;
      return;
    }
    final textIsUri = BasicUtils.isValidUri(newText);
    if (textIsUri) {
      ref.read(_$sourceLinkMetadata.notifier).state = newText;
    }
  }

  void _removeUnsavedStorageImage(String currentUpdatedImage) {
    if (currentUpdatedImage.isNotEmpty &&
        !_mealSaved &&
        BasicUtils.isStorageMealImage(currentUpdatedImage)) {
      StorageService.removeFile(currentUpdatedImage);
    }
  }

  void _changeMealValue(Function(Meal) changeProperty) {
    final meal = ref.read(_$meal);
    changeProperty(meal);
    ref.read(_$meal.notifier).state = Meal.fromMap(meal.id, meal.toMap());
  }

  void _onOpenImagePicker() {
    ref.read(initSearchWebImagePickerProvider.notifier).state =
        _titleController.text;
  }

  void _openGetPremium() {
    WidgetUtils.showFoodlyBottomSheet<void>(
      context: context,
      builder: (_) => const GetPremiumModal(),
    );
  }

  Future<void> _estimateKcal() async {
    final baseMeal = ref.read(_$meal);
    final hasName = _titleController.text.isNotEmpty;
    final hasIngredient = baseMeal.ingredients?.isNotEmpty == true;
    if (!hasName || !hasIngredient) {
      MainSnackbar(
        message: 'meal_create_kcal_ai_missing_input'.tr(),
        isError: true,
      ).show(context);
      return;
    }

    ref.read(_$isAiLoading.notifier).state = true;
    try {
      final lang = context.locale.languageCode;
      final mealForApi = Meal.fromMap(baseMeal.id, baseMeal.toMap());
      mealForApi.name = _titleController.text;
      mealForApi.id ??= _generateKcalIdForApiOnCreate;
      final estimate = await LunixApiService.estimateKcal(mealForApi, lang);
      if (!mounted) {
        return;
      }
      // The AI call succeeded — count it against the free quota (premium is
      // unlimited). Captured before the modal await so we never touch `ref`
      // after the widget may have been disposed.
      final isSubscribed = ref.read(InAppPurchaseService.$userIsSubscribed);
      final userId = ref.read(userProvider)?.id;
      final result = await WidgetUtils.showFoodlyBottomSheet<int>(
        context: context,
        builder: (_) => KcalEstimateModal(estimate: estimate),
      );
      if (result != null) {
        _kcalController.text = result.toString();
      }
      if (!isSubscribed && userId != null) {
        await AiUsageService.incrementKcal(userId);
      }
    } on RateLimitException catch (e) {
      if (!mounted) {
        return;
      }
      final minutes = (e.retryAfterSeconds / 60).ceil();
      MainSnackbar(
        message:
            'meal_create_kcal_ai_rate_limit'.tr(args: [minutes.toString()]),
        isError: true,
      ).show(context);
    } catch (_) {
      if (!mounted) {
        return;
      }
      MainSnackbar(
        message: 'meal_create_error_unknown'.tr(),
        isError: true,
      ).show(context);
    } finally {
      if (mounted) {
        ref.read(_$isAiLoading.notifier).state = false;
      }
    }
  }
}
