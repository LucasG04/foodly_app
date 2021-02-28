import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foodly/providers/state_providers.dart';

import '../../constants.dart';
import '../../models/meal.dart';
import '../../services/meal_service.dart';
import '../../utils/main_snackbar.dart';
import '../../widgets/main_button.dart';
import '../../widgets/main_text_field.dart';
import '../../widgets/markdown_editor.dart';
import '../../widgets/page_title.dart';
import '../../widgets/progress_button.dart';
import 'edit_list_content.dart';

class MealCreateScreen extends StatefulWidget {
  @override
  _MealCreateScreenState createState() => _MealCreateScreenState();
}

class _MealCreateScreenState extends State<MealCreateScreen> {
  Meal _meal = new Meal();
  TextEditingController _titleController = new TextEditingController();
  TextEditingController _urlController = new TextEditingController();
  TextEditingController _sourceController = new TextEditingController();
  TextEditingController _durationController = new TextEditingController();

  ButtonState _buttonState = ButtonState.normal;

  @override
  Widget build(BuildContext context) {
    _meal.planId = context.read(planProvider).state.id;
    final fullWidth = MediaQuery.of(context).size.width > 699
        ? 700
        : MediaQuery.of(context).size.width * 0.8;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Center(
            child: Container(
              width: fullWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: kPadding),
                  PageTitle(text: 'Gericht erstellen', showBackButton: true),
                  MainTextField(
                    controller: _titleController,
                    title: 'Name',
                  ),
                  Divider(),
                  EditListContent(
                    content: _meal.ingredients,
                    onChanged: (list) => _meal.ingredients = list,
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
                  MarkdownEditor(onChange: (v) => _meal.instruction = v),
                  Divider(),
                  MainTextField(
                    controller: _urlController,
                    title: 'Link zum Bild',
                    placeholder: 'https://image.food.com/cake.jpg',
                  ),
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
                        ),
                      ),
                    ],
                  ),
                  // Divider(),
                  // EditListContent(
                  //   content: _meal.ingredients,
                  //   onChanged: (list) => _meal.ingredients = list,
                  //   title: 'Tags:',
                  // ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: kPadding),
                    child: MainButton(
                      text: 'Erstellen',
                      onTap: _createMeal,
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
    );
  }

  Future<void> _createMeal() async {
    setState(() {
      _buttonState = ButtonState.inProgress;
    });

    _meal.name = _titleController.text;
    _meal.imageUrl = _urlController.text;
    _meal.source = _sourceController.text;
    _meal.duration = int.tryParse(_titleController.text) ?? 0;

    if (_formIsValid()) {
      try {
        final newMeal = await MealService.createMeal(_meal);
        await Future.delayed(const Duration(seconds: 1));
        _buttonState = ButtonState.normal;
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
      print('Form invalid');
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
}