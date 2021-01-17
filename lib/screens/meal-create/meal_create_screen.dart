import 'package:flutter/material.dart';
import 'package:foodly/constants.dart';
import 'package:foodly/widgets/main_image_picker.dart';
import 'package:foodly/widgets/main_text_field.dart';
import 'package:foodly/widgets/page_title.dart';

class MealCreateScreen extends StatefulWidget {
  @override
  _MealCreateScreenState createState() => _MealCreateScreenState();
}

class _MealCreateScreenState extends State<MealCreateScreen> {
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
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Container(
                      width: fullWidth * 0.5,
                      child: Column(
                        children: [
                          MainTextField(
                            controller: _titleController,
                            title: 'Name',
                          ),
                          MainTextField(
                            controller: _titleController,
                            title: 'Name',
                          ),
                          MainTextField(
                            controller: _titleController,
                            title: 'Name',
                          ),
                        ],
                      ),
                    ),
                    MainImagePicker(
                      imageUrl:
                          'https://image.brigitte.de/10912866/t/RC/v3/w1440/r1/-/pfannkuchen.jpg',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
