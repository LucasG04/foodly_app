import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

import '../../constants.dart';

class EditListContent extends StatefulWidget {
  final List<String> content;
  final void Function(List<String>) onChanged;
  final String title;

  const EditListContent({
    this.content,
    this.onChanged,
    this.title,
  });

  @override
  _EditListContentState createState() => _EditListContentState();
}

class _EditListContentState extends State<EditListContent> {
  List<String> _questions = [];

  @override
  void initState() {
    _questions = widget.content;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          child: Text(
            widget.title,
            style: Theme.of(context).textTheme.bodyText1,
          ),
        ),
        ..._questions.map((feedbackquestion) {
          return Row(
            children: <Widget>[
              Expanded(
                child: _buildTextField(feedbackquestion,
                    _questions.indexOf(feedbackquestion), context),
              ),
              IconButton(
                  icon: Icon(EvaIcons.minusCircleOutline),
                  onPressed: () {
                    setState(() {
                      _questions.remove(feedbackquestion);
                      widget.onChanged(_questions);
                    });
                  }),
            ],
          );
        }).toList(),
        Row(
          children: <Widget>[
            Spacer(),
            IconButton(
              icon: Icon(EvaIcons.plusCircleOutline),
              onPressed: () {
                setState(() {
                  _questions.add('');
                  widget.onChanged(_questions);
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  TextField _buildTextField(
      String feedbackquestion, int index, BuildContext context) {
    final controller = TextEditingController(text: feedbackquestion);
    controller.addListener(() {
      _questions[index] = controller.text;
      widget.onChanged(_questions);
    });

    return TextField(
      controller: controller,
      decoration: new InputDecoration(
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        contentPadding: EdgeInsets.only(
          left: kPadding / 2,
          bottom: 11,
          top: 11,
          right: 5,
        ),
        hintText: '...',
      ),
      style: Theme.of(context).textTheme.bodyText2,
    );
  }
}
