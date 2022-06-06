import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keyboard_service/keyboard_service.dart';

import '../../constants.dart';
import '../../models/meal.dart';
import '../../providers/state_providers.dart';
import '../../services/authentication_service.dart';
import '../../services/chefkoch_service.dart';
import '../../services/link_metadata_service.dart';
import '../../services/meal_service.dart';
import '../../services/storage_service.dart';
import '../../utils/basic_utils.dart';
import '../../utils/main_snackbar.dart';
import '../../utils/widget_utils.dart';
import '../../widgets/full_screen_loader.dart';
import '../../widgets/link_preview.dart';
import '../../widgets/main_appbar.dart';
import '../../widgets/main_button.dart';
import '../../widgets/main_text_field.dart';
import '../../widgets/markdown_editor.dart';
import '../../widgets/meal_tag.dart';
import '../../widgets/progress_button.dart';
import '../../widgets/wrapped_image_picker/wrapped_image_picker.dart';
import 'chefkoch_import_modal.dart';
import 'edit_ingredients.dart';
import 'edit_list_content_modal.dart';

class MealCreateScreen extends StatefulWidget {
  final String id;

  const MealCreateScreen({required this.id, Key? key}) : super(key: key);

  @override
  State<MealCreateScreen> createState() => _MealCreateScreenState();
}

class _MealCreateScreenState extends State<MealCreateScreen> {
  ButtonState? _buttonState;
  TextEditingController? _durationController;
  late TextEditingController _instructionsController;
  late bool _isCreatingMeal;
  late bool _isLoadingMeal;
  late bool _mealSaved;
  Meal _meal = Meal(name: '');
  ScrollController? _scrollController;
  TextEditingController? _sourceController;
  TextEditingController? _titleController;
  String? _updatedImage;

  List<String>? _existingMealTags;

  @override
  void initState() {
    _initialParseId();

    _buttonState = ButtonState.normal;
    _scrollController = ScrollController();
    _mealSaved = false;

    super.initState();
  }

  @override
  void dispose() {
    if (_updatedImage != null &&
        !_mealSaved &&
        BasicUtils.isStorageMealImage(_updatedImage!)) {
      StorageService.removeFile(_updatedImage);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fullWidth = MediaQuery.of(context).size.width > 699
        ? 700.0
        : MediaQuery.of(context).size.width * 0.8;

    return KeyboardAutoDismiss(
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
                color: Theme.of(context).textTheme.bodyText1!.color,
              ),
              onPressed: () => _openChefkochImport(),
            ),
          ],
        ),
        body: Consumer(
          builder: (context, watch, _) {
            final plan = watch(planProvider).state;
            _meal.planId = plan?.id;
            _fetchAllTagsIfNotExist();
            return Stack(
              children: [
                if (_isLoadingMeal || plan == null) const FullScreenLoader(),
                if (plan != null)
                  SafeArea(
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
                                onChange: (newText) => context
                                    .read(initSearchWebImagePickerProvider)
                                    .state = newText,
                              ),
                              const Divider(),
                              if (_isLoadingMeal)
                                EditIngredients(
                                  key: UniqueKey(),
                                  content: const [],
                                  onChanged: null,
                                  title: 'meal_create_ingredients_title'.tr(),
                                )
                              else
                                EditIngredients(
                                  content: _meal.ingredients ?? [],
                                  onChanged: (results) {
                                    setState(() {
                                      _meal.ingredients = results;
                                    });
                                  },
                                  title:
                                      '${'meal_create_ingredients_title'.tr()} *',
                                ),
                              const Divider(),
                              SizedBox(
                                width: double.infinity,
                                child: Text(
                                  'meal_create_instruction_title',
                                  style: Theme.of(context).textTheme.bodyText1,
                                ).tr(),
                              ),
                              if (_isLoadingMeal)
                                MarkdownEditor(
                                  key: UniqueKey(),
                                  textEditingController:
                                      TextEditingController(),
                                )
                              else
                                MarkdownEditor(
                                  textEditingController:
                                      _instructionsController,
                                ),
                              const Divider(),
                              if (_isLoadingMeal)
                                WrappedImagePicker(
                                  key: UniqueKey(),
                                  onPick: null,
                                )
                              else
                                WrappedImagePicker(
                                  imageUrl: _meal.imageUrl,
                                  onPick: (value) => _updatedImage = value,
                                ),
                              const Divider(),
                              Row(
                                children: [
                                  Flexible(
                                    flex: 2,
                                    child: MainTextField(
                                      controller: _sourceController,
                                      title: 'meal_create_source_title'.tr(),
                                      placeholder:
                                          'meal_create_source_placeholder'.tr(),
                                    ),
                                  ),
                                  const SizedBox(width: kPadding / 2),
                                  Flexible(
                                    child: MainTextField(
                                      controller: _durationController,
                                      title: 'meal_create_duration_title'.tr(),
                                      placeholder: '10',
                                      textAlign: TextAlign.end,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ),
                              if (!_isLoadingMeal)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: kPadding / 2),
                                  child: LinkPreview(_sourceController!.text),
                                ),
                              const Divider(),
                              if (!_isLoadingMeal) ...[
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
                                if (_meal.tags != null &&
                                    _meal.tags!.isNotEmpty)
                                  SizedBox(
                                    width: double.infinity,
                                    child: Wrap(
                                      clipBehavior: Clip.hardEdge,
                                      children: _meal.tags!
                                          .map((e) => MealTag(e))
                                          .toList(),
                                    ),
                                  )
                                else
                                  const Text('-')
                              ],
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: kPadding),
                                child: MainButton(
                                  text: 'save'.tr(),
                                  onTap: _saveMeal,
                                  isProgress: true,
                                  buttonState: _buttonState,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _initialParseId() {
    if (widget.id == 'create') {
      _isLoadingMeal = false;
      _isCreatingMeal = true;
      _titleController = TextEditingController();
      _sourceController = TextEditingController();
      _durationController = TextEditingController();
      _instructionsController = TextEditingController();
      _meal.ingredients = [];
      _meal.tags = [];
    } else if (widget.id.startsWith('https') &&
        Uri.decodeComponent(widget.id).startsWith(kChefkochShareEndpoint)) {
      _isLoadingMeal = true;
      _isCreatingMeal = true;
      ChefkochService.getMealFromChefkochUrl(Uri.decodeComponent(widget.id))
          .then((meal) {
        if (meal != null) {
          meal.imageUrl = meal.imageUrl!.replaceFirst('http:', 'https:');
          _meal = meal;
          _titleController = TextEditingController(text: meal.name);
          _sourceController = TextEditingController(text: meal.source);
          _durationController =
              TextEditingController(text: meal.duration.toString());
          _instructionsController =
              TextEditingController(text: meal.instructions);
          _meal.ingredients = _meal.ingredients ?? [];
          _meal.tags = _meal.tags ?? [];
        }

        setState(() {
          _isLoadingMeal = false;
        });
      });
    } else {
      _isLoadingMeal = true;
      _isCreatingMeal = false;
      MealService.getMealById(widget.id).then((meal) {
        if (meal != null) {
          _meal = meal;
          _titleController = TextEditingController(text: meal.name);
          _sourceController = TextEditingController(text: meal.source);
          _durationController =
              TextEditingController(text: meal.duration.toString());
          _instructionsController =
              TextEditingController(text: meal.instructions);
          _meal.ingredients = _meal.ingredients ?? [];
          _meal.tags = _meal.tags ?? [];
        }

        setState(() {
          _isLoadingMeal = false;
        });
      });
    }
  }

  Future<void> _saveMeal() async {
    setState(() {
      _buttonState = ButtonState.inProgress;
    });

    _meal.name = _titleController!.text;
    _meal.source = _sourceController!.text;
    _meal.duration = int.tryParse(_durationController!.text) ?? 0;
    _meal.instructions = _instructionsController.text;
    _meal.createdBy = _isCreatingMeal
        ? AuthenticationService.currentUser!.uid
        : _meal.createdBy;

    _meal.imageUrl = _updatedImage ??
        (await LinkMetadataService.get(_meal.source!))?.image ??
        _meal.imageUrl;

    if (_formIsValid()) {
      try {
        final newMeal = _isCreatingMeal
            ? await MealService.createMeal(_meal)
            : await MealService.updateMeal(_meal);
        _buttonState = ButtonState.normal;
        _mealSaved = true;
        if (!mounted) {
          return;
        }
        BasicUtils.emitMealsChanged(context);
        AutoRouter.of(context).pop(newMeal);
      } catch (e) {
        if (!mounted) {
          return;
        }
        MainSnackbar(
          message: 'meal_create_error_unknown'.tr(),
          isError: true,
        ).show(context);
        _buttonState = ButtonState.error;
      }
    } else {
      if (!mounted) {
        return;
      }
      MainSnackbar(
        message: 'meal_create_error_missing_input'.tr(),
        isError: true,
      ).show(context);
      _buttonState = ButtonState.error;
    }

    // update button state
    setState(() {});
  }

  bool _formIsValid() {
    return _titleController!.text.isNotEmpty;
  }

  void _openChefkochImport() async {
    final result = await WidgetUtils.showFoodlyBottomSheet<Meal>(
      context: context,
      builder: (_) => const ChefkochImportModal(),
    );

    if (result != null) {
      setState(() {
        _titleController!.text = result.name;
        _meal.imageUrl = result.imageUrl;
        _sourceController!.text = result.source!;
        _durationController!.text = result.duration.toString();
        _instructionsController.text = result.instructions!;
        _meal.ingredients = result.ingredients ?? [];

        _meal.tags = result.tags;
      });
    }
  }

  void _openMealTagEdit() async {
    // ignore: prefer_conditional_assignment
    if (_existingMealTags == null) {
      _existingMealTags =
          await MealService.getAllTags(context.read(planProvider).state!.id!);
    }
    final allTags = [
      ..._existingMealTags ?? <String>[],
      ..._getMissingTagsInExisting()
    ];
    final result = await WidgetUtils.showFoodlyBottomSheet<List<String>>(
      context: context,
      builder: (_) => EditListContentModal(
        title: 'meal_create_tags_title'.tr(),
        selectedContent: _meal.tags ?? [],
        allContent: allTags,
        textFieldInfo: 'meal_create_edit_tags_info'.tr(),
      ),
    );

    if (result != null) {
      setState(() {
        _meal.tags = result;
      });
    }
  }

  List<String> _getMissingTagsInExisting() {
    if (_meal.tags == null || _meal.tags!.isEmpty) {
      return [];
    }
    if (_existingMealTags == null || _existingMealTags!.isEmpty) {
      return _meal.tags!;
    }
    return _meal.tags!
        .where((tag) => !_existingMealTags!.contains(tag))
        .toList();
  }

  void _fetchAllTagsIfNotExist() async {
    final plan = context.read(planProvider).state;
    if (plan == null || plan.id == null || _existingMealTags != null) {
      return;
    }
    _existingMealTags = await MealService.getAllTags(plan.id!);
  }
}
