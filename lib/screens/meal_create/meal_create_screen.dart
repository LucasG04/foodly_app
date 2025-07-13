import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keyboard_service/keyboard_service.dart';

import '../../app_router.gr.dart';
import '../../constants.dart';
import '../../models/ingredient.dart';
import '../../models/meal.dart';
import '../../providers/state_providers.dart';
import '../../services/authentication_service.dart';
import '../../services/link_metadata_service.dart';
import '../../services/lunix_api_service.dart';
import '../../services/meal_service.dart';
import '../../services/storage_service.dart';
import '../../utils/basic_utils.dart';
import '../../utils/main_snackbar.dart';
import '../../utils/of_context_mixin.dart';
import '../../utils/widget_utils.dart';
import '../../widgets/link_preview.dart';
import '../../widgets/main_appbar.dart';
import '../../widgets/main_button.dart';
import '../../widgets/main_text_field.dart';
import '../../widgets/markdown_editor.dart';
import '../../widgets/meal_tag.dart';
import '../../widgets/progress_button.dart';
import '../../widgets/small_circular_progress_indicator.dart';
import '../../widgets/small_number_input.dart';
import '../../widgets/wrapped_image_picker/wrapped_image_picker.dart';
import 'chefkoch_import_modal.dart';
import 'edit_ingredients.dart';
import 'edit_list_content_modal.dart';
import 'save_changes_modal.dart';

class MealCreateScreen extends ConsumerStatefulWidget {
  final String id;

  const MealCreateScreen({required this.id, super.key});

  @override
  _MealCreateScreenState createState() => _MealCreateScreenState();
}

class _MealCreateScreenState extends ConsumerState<MealCreateScreen>
    with OfContextMixin {
  bool _mealSaved = false;
  bool _isFirstCall = true;
  final ScrollController _scrollController = ScrollController();

  late bool _isCreatingMeal;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  final TextEditingController _sourceController = TextEditingController();

  final _$buttonState =
      AutoDisposeStateProvider<ButtonState>((_) => ButtonState.normal);
  final _$isLoading = AutoDisposeStateProvider<bool>((_) => true);
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
    _sourceController.addListener(
      () => _onSourceTextChange(_sourceController.text),
    );
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
    final fullWidth = media.size.width > 699 ? 700.0 : media.size.width * 0.8;

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
                onPressed: () => _openChefkochImport(),
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
                                const Divider(),
                                Consumer(builder: (context, ref, _) {
                                  final meal = ref.watch(_$meal);
                                  return EditIngredients(
                                    content: meal.ingredients ?? [],
                                    onChanged: (value) => _changeMealValue(
                                        (meal) => meal.ingredients = value),
                                    title: 'meal_create_ingredients_title'.tr(),
                                  );
                                }),
                                const Divider(),
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
                                const Divider(),
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
                                ),
                                const Divider(),
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
                                const Divider(),
                                Row(
                                  children: [
                                    Flexible(
                                      flex: 2,
                                      child: MainTextField(
                                        controller: _sourceController,
                                        title: 'meal_create_source_title'.tr(),
                                        placeholder:
                                            'meal_create_source_placeholder'
                                                .tr(),
                                        onChange: (newText) =>
                                            _onSourceTextChange(newText.trim()),
                                      ),
                                    ),
                                    const SizedBox(width: kPadding / 2),
                                    Flexible(
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
                                const Divider(),
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
                                  final meal = ref.watch(_$meal);
                                  return meal.tags == null || meal.tags!.isEmpty
                                      ? const Text('-')
                                      : SizedBox(
                                          width: double.infinity,
                                          child: Wrap(
                                            clipBehavior: Clip.hardEdge,
                                            children: meal.tags!
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

  Future<Meal?> _initialParseId() async {
    if (widget.id == 'create') {
      _isCreatingMeal = true;
      final meal = ref.read(_$meal.notifier).state;
      meal.ingredients = [];
      meal.tags = [];
      return meal;
    } else if (widget.id.startsWith('https') &&
        Uri.decodeComponent(widget.id).startsWith(kChefkochShareEndpoint)) {
      _isCreatingMeal = true;
      final langCode = context.locale.languageCode;
      final meal = await LunixApiService.getMealFromUrl(
        Uri.decodeComponent(widget.id),
        langCode,
      );
      if (meal != null) {
        meal.imageUrl = meal.imageUrl!.replaceFirst('http:', 'https:');
        _titleController.text = meal.name;
        _sourceController.text = meal.source ?? '';
        _onSourceTextChange(meal.source ?? '');
        _durationController.text = (meal.duration ?? '').toString();
        _instructionsController.text = meal.instructions ?? '';
        meal.ingredients = meal.ingredients ?? [];
        meal.tags = meal.tags ?? [];
        _originalMeal = Meal.fromMap(meal.id, meal.toMap());
        ref.read(_$meal.notifier).state = meal;
      }
      return meal;
    } else {
      _isCreatingMeal = false;
      final meal = await MealService.getMealById(widget.id);
      if (meal != null) {
        _titleController.text = meal.name;
        _sourceController.text = meal.source ?? '';
        _onSourceTextChange(meal.source ?? '');
        _durationController.text = (meal.duration ?? '').toString();
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
      AutoRouter.of(context).pop();
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
        _instructionsController.text != (_originalMeal.instructions ?? '') ||
        ref.read(_$updatedImage.notifier).state != null ||
        !_ingredientsEquals(
            meal.ingredients ?? [], _originalMeal.ingredients ?? []) ||
        !listEquals<String>(meal.tags ?? [], _originalMeal.tags ?? []);
  }

  void _openChefkochImport() async {
    final result = await WidgetUtils.showFoodlyBottomSheet<Meal>(
      context: context,
      builder: (_) => const ChefkochImportModal(),
    );

    if (result != null) {
      final meal = ref.read(_$meal.notifier).state;
      _titleController.text = result.name;
      meal.imageUrl = result.imageUrl;
      _sourceController.text = result.source!;
      _durationController.text = (result.duration ?? '').toString();
      _instructionsController.text = result.instructions!;
      meal.ingredients = result.ingredients ?? [];
      meal.servings = result.servings;
      meal.tags = result.tags;
      ref.read(_$meal.notifier).state = Meal.fromMap(meal.id, meal.toMap());
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
          a[i].unit != b[i].unit) {
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
    final copy = Meal.fromMap(meal.id, meal.toMap());
    changeProperty(copy);
    ref.read(_$meal.notifier).state = copy;
  }

  void _onOpenImagePicker() {
    ref.read(initSearchWebImagePickerProvider.notifier).state =
        _titleController.text;
  }
}
