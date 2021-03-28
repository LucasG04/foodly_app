import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

import '../../constants.dart';

class EditListContent extends StatelessWidget {
  final List<String> content;
  final void Function(List<String>) onChanged;
  final String title;

  EditListContent({
    Key key,
    @required this.content,
    @required this.onChanged,
    @required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyText1,
          ),
        ),
        ...content.map((value) {
          return Row(
            children: <Widget>[
              Expanded(
                child: _buildTextField(value, content.indexOf(value), context),
              ),
              IconButton(
                icon: Icon(EvaIcons.minusCircleOutline),
                onPressed: () {
                  content.remove(value);
                  onChanged(content);
                },
              ),
            ],
          );
        }).toList(),
        Row(
          children: <Widget>[
            Spacer(),
            IconButton(
              icon: Icon(EvaIcons.plusCircleOutline),
              onPressed: () => _addNewLine(),
            ),
          ],
        ),
      ],
    );
  }

  TextField _buildTextField(
      String ingredient, int index, BuildContext context) {
    final controller = TextEditingController(text: ingredient);
    controller.addListener(() {
      content[index] = controller.text;
      onChanged(content);
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
      onSubmitted: (_) => _addNewLine(),
    );
  }

  void _addNewLine() {
    content.add('');
    onChanged(content);
  }
}
