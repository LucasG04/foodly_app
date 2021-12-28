import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

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
import '../../widgets/full_screen_loader.dart';
import '../../widgets/link_preview.dart';
import '../../widgets/main_appbar.dart';
import '../../widgets/main_button.dart';
import '../../widgets/main_text_field.dart';
import '../../widgets/markdown_editor.dart';
import '../../widgets/progress_button.dart';
import '../../widgets/wrapped_image_picker/wrapped_image_picker.dart';
import 'chefkoch_import_modal.dart';
import 'edit_ingredients.dart';
import 'edit_list_content.dart';

class MealCreateScreen extends StatefulWidget {
  final String id;

  const MealCreateScreen({required this.id, Key? key}) : super(key: key);

  @override
  _MealCreateScreenState createState() => _MealCreateScreenState();
}

class _MealCreateScreenState extends State<MealCreateScreen> {
  ButtonState? _buttonState;
  TextEditingController? _durationController;
  TextEditingController? _instructionsController;
  late bool _isCreatingMeal;
  late bool _isLoadingMeal;
  late bool _mealSaved;
  Meal _meal = Meal(name: '');
  ScrollController? _scrollController;
  TextEditingController? _sourceController;
  TextEditingController? _titleController;
  String? _updatedImage;

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
    _meal.planId = context.read(planProvider).state!.id;
    final fullWidth = MediaQuery.of(context).size.width > 699
        ? 700.0
        : MediaQuery.of(context).size.width * 0.8;

    return Scaffold(
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
      body: Stack(
        children: [
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
                          title: 'meal_create_ingredients_title'.tr(),
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
                          initialValue: '',
                        )
                      else
                        MarkdownEditor(
                          textEditingController: _instructionsController,
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
                            // ignore: avoid_redundant_argument_values
                            flex: 1,
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
                      if (!_isLoadingMeal)
                        EditListContent(
                          content: _meal.tags,
                          onChanged: (list) => _meal.tags = list,
                          title: 'meal_create_tags_title'.tr(),
                        )
                      else
                        const SizedBox(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: kPadding),
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
          if (_isLoadingMeal) const FullScreenLoader() else const SizedBox(),
        ],
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
    _meal.instructions = _instructionsController!.text;
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
        AutoRouter.of(context).pop(newMeal);
      } catch (e) {
        MainSnackbar(
          message: 'meal_create_error_unknown'.tr(),
          isError: true,
        ).show(context);
        _buttonState = ButtonState.error;
      }
    } else {
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
    final result = await showBarModalBottomSheet<Meal>(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(10.0),
        ),
      ),
      context: context,
      builder: (_) => const ChefkochImportModal(),
    );

    if (result != null) {
      setState(() {
        _titleController!.text = result.name;
        _meal.imageUrl = result.imageUrl;
        _sourceController!.text = result.source!;
        _durationController!.text = result.duration.toString();
        _instructionsController!.text = result.instructions!;
        _meal.ingredients = result.ingredients ?? [];

        _meal.tags = result.tags;
      });
    }
  }
}
