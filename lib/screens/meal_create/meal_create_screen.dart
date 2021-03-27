import 'package:auto_route/auto_route.dart';
import 'package:auto_route/auto_route_annotations.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foodly/services/storage_service.dart';
import 'package:foodly/utils/basic_utils.dart';
import 'package:foodly/widgets/wrapped_image_picker/wrapped_image_picker.dart';

import '../../constants.dart';
import '../../models/meal.dart';
import '../../providers/state_providers.dart';
import '../../services/authentication_service.dart';
import '../../services/chefkoch_service.dart';
import '../../services/meal_service.dart';
import '../../utils/main_snackbar.dart';
import '../../widgets/full_screen_loader.dart';
import '../../widgets/main_appbar.dart';
import '../../widgets/main_button.dart';
import '../../widgets/main_text_field.dart';
import '../../widgets/markdown_editor.dart';
import '../../widgets/progress_button.dart';
import 'chefkoch_import_modal.dart';
import 'edit_ingredients.dart';
import 'edit_list_content.dart';

class MealCreateScreen extends StatefulWidget {
  final String id;

  const MealCreateScreen({
    @PathParam() this.id,
  });

  @override
  _MealCreateScreenState createState() => _MealCreateScreenState();
}

class _MealCreateScreenState extends State<MealCreateScreen> {
  ButtonState _buttonState;
  TextEditingController _durationController;
  TextEditingController _instructionsController;
  bool _isCreatingMeal;
  bool _isLoadingMeal;
  bool _mealSaved;
  Meal _meal = new Meal();
  ScrollController _scrollController;
  TextEditingController _sourceController;
  TextEditingController _titleController;
  String _updatedImage;

  @override
  void initState() {
    _initialParseId();

    _buttonState = ButtonState.normal;
    _scrollController = new ScrollController();
    _mealSaved = false;
    super.initState();
  }

  @override
  void dispose() {
    if (_updatedImage != null &&
        !_mealSaved &&
        BasicUtils.isStorageImage(_updatedImage)) {
      StorageService.removeFile(_updatedImage);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _meal.planId = context.read(planProvider).state.id;
    final fullWidth = MediaQuery.of(context).size.width > 699
        ? 700
        : MediaQuery.of(context).size.width * 0.8;

    return Scaffold(
      appBar: MainAppBar(
        text: _isCreatingMeal ? 'Gericht erstellen' : 'Gericht bearbeiten',
        scrollController: _scrollController,
        actions: [
          IconButton(
            icon: Icon(
              EvaIcons.downloadOutline,
              color: Theme.of(context).textTheme.bodyText1.color,
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
                child: Container(
                  width: fullWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      MainTextField(
                        controller: _titleController,
                        title: 'Name',
                      ),
                      Divider(),
                      _isLoadingMeal
                          ? EditIngredients(
                              key: UniqueKey(),
                              content: [],
                              onChanged: null,
                              title: 'Zutaten:',
                            )
                          : EditIngredients(
                              content: _meal.ingredients ?? [],
                              onChanged: (results) {
                                setState(() {
                                  _meal.ingredients = results;
                                });
                              },
                              title: 'Zutaten:',
                            ),
                      Divider(),
                      Container(
                        width: double.infinity,
                        child: Text(
                          'Anleitung',
                          style: Theme.of(context).textTheme.bodyText1,
                        ),
                      ),
                      _isLoadingMeal
                          ? MarkdownEditor(
                              key: UniqueKey(),
                              onChange: null,
                              initialValue: '',
                            )
                          : MarkdownEditor(
                              textEditingController: _instructionsController,
                            ),
                      Divider(),
                      _isLoadingMeal
                          ? WrappedImagePicker(
                              key: UniqueKey(),
                              onPick: null,
                            )
                          : WrappedImagePicker(
                              imageUrl: _meal.imageUrl,
                              onPick: (value) => _updatedImage = value,
                            ),
                      Divider(),
                      Row(
                        children: [
                          Flexible(
                            flex: 2,
                            child: MainTextField(
                              controller: _sourceController,
                              title: 'Quelle',
                              placeholder: 'Chefkoch',
                            ),
                          ),
                          SizedBox(width: kPadding / 2),
                          Flexible(
                            flex: 1,
                            child: MainTextField(
                              controller: _durationController,
                              title: 'Dauer (min)',
                              placeholder: '10',
                              textAlign: TextAlign.end,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      Divider(),
                      EditListContent(
                        content: _meal.tags ?? [],
                        onChanged: (list) {
                          setState(() {
                            _meal.tags = list;
                          });
                        },
                        title: 'Kategorien:',
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: kPadding),
                        child: MainButton(
                          text: 'Speichern',
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
          _isLoadingMeal ? FullScreenLoader() : SizedBox(),
        ],
      ),
    );
  }

  void _initialParseId() {
    if (widget.id == 'create') {
      _isLoadingMeal = false;
      _isCreatingMeal = true;
      _titleController = new TextEditingController();
      _sourceController = new TextEditingController();
      _durationController = new TextEditingController();
      _instructionsController = new TextEditingController();
      _meal.ingredients = [];
    } else if (widget.id.startsWith('https') &&
        Uri.decodeComponent(widget.id).startsWith(kChefkochShareEndpoint)) {
      _isLoadingMeal = true;
      _isCreatingMeal = true;
      ChefkochService.getMealFromChefkochUrl(Uri.decodeComponent(widget.id))
          .then((meal) {
        _meal = meal;
        _titleController = new TextEditingController(text: meal.name);
        _sourceController = new TextEditingController(text: meal.source);
        _durationController =
            new TextEditingController(text: meal.duration.toString());
        _instructionsController =
            new TextEditingController(text: meal.instructions);
        _meal.ingredients = _meal.ingredients ?? [];

        setState(() {
          _isLoadingMeal = false;
        });
      }).catchError((err) => print(err));
    } else {
      _isLoadingMeal = true;
      _isCreatingMeal = false;
      MealService.getMealById(widget.id).then((meal) {
        _meal = meal;
        _titleController = new TextEditingController(text: meal.name);
        _sourceController = new TextEditingController(text: meal.source);
        _durationController =
            new TextEditingController(text: meal.duration.toString());
        _instructionsController =
            new TextEditingController(text: meal.instructions);
        _meal.ingredients = _meal.ingredients ?? [];

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

    _meal.name = _titleController.text;
    _meal.source = _sourceController.text;
    _meal.duration = int.tryParse(_durationController.text) ?? 0;
    _meal.instructions = _instructionsController.text;
    _meal.createdBy = _isCreatingMeal
        ? AuthenticationService.currentUser.uid
        : _meal.createdBy;
    _meal.imageUrl = _updatedImage ?? _meal.imageUrl;

    if (_formIsValid()) {
      try {
        final newMeal = _isCreatingMeal
            ? await MealService.createMeal(_meal)
            : await MealService.updateMeal(_meal);
        _buttonState = ButtonState.normal;
        _mealSaved = true;
        ExtendedNavigator.root.pop(newMeal);
      } catch (e) {
        print(e);
        MainSnackbar(
          message:
              'Es ist ein Fehler aufgetreten. Prüfe deine Internetverbindung oder versuche es später erneut.',
          isError: true,
        ).show(context);
        _buttonState = ButtonState.error;
      }
    } else {
      MainSnackbar(
        message: 'Bitte vergib einen Namen und mindestens eine Zutat.',
        isError: true,
      ).show(context);
      _buttonState = ButtonState.error;
    }

    // update button state
    setState(() {});
  }

  bool _formIsValid() {
    return _titleController.text.isNotEmpty && _meal.ingredients.isNotEmpty;
  }

  void _openChefkochImport() async {
    final result = await showModalBottomSheet<Meal>(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(10.0),
        ),
      ),
      isScrollControlled: true,
      context: context,
      builder: (_) => ChefkochImportModal(),
    );

    if (result != null) {
      setState(() {
        _titleController.text = result.name;
        _meal.imageUrl = result.imageUrl;
        _sourceController.text = result.source;
        _durationController.text = result.duration.toString();
        _instructionsController.text = result.instructions;
        _meal.ingredients = result.ingredients ?? [];

        _meal.tags = result.tags;
      });
    }
  }
}
