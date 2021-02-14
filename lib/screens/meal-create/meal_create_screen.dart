import 'package:flutter/material.dart';
import 'package:foodly/constants.dart';
import 'package:foodly/models/meal.dart';
import 'package:foodly/screens/meal-create/edit_ingredients.dart';
import 'package:foodly/widgets/main_image_picker.dart';
import 'package:foodly/widgets/main_text_field.dart';
import 'package:foodly/widgets/page_title.dart';

class MealCreateScreen extends StatefulWidget {
  @override
  _MealCreateScreenState createState() => _MealCreateScreenState();
}

class _MealCreateScreenState extends State<MealCreateScreen> {
  Meal _meal = new Meal();

  TextEditingController _titleController = new TextEditingController();

  @override
  Widget build(BuildContext context) {
    final fullWidth = MediaQuery.of(context).size.width > 699
        ? 700
        : MediaQuery.of(context).size.width * 0.9;

    return Scaffold(
      body: SingleChildScrollView(
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
                MainImagePicker(
                  imageUrl:
                      'https://image.brigitte.de/10912866/t/RC/v3/w1440/r1/-/pfannkuchen.jpg',
                ),
                Divider(),
                EditIngredients(
                  ingredients: _meal.ingredients,
                  onChanged: (list) => _meal.ingredients = list,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
