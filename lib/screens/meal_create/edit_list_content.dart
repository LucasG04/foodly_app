import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

import '../../constants.dart';

class EditListContent extends StatefulWidget {
  final List<String>? content;
  final void Function(List<String>?)? onChanged;
  final String? title;

  const EditListContent({
    this.content,
    this.onChanged,
    this.title,
  });

  @override
  _EditListContentState createState() => _EditListContentState();
}

class _EditListContentState extends State<EditListContent> {
  List<String>? _content = [];

  @override
  void initState() {
    _content = widget.content;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          child: Text(
            widget.title!,
            style: Theme.of(context).textTheme.bodyText1,
          ),
        ),
        ..._content!.map((item) {
          return Row(
            children: <Widget>[
              Expanded(
                child: _buildTextField(item, _content!.indexOf(item), context),
              ),
              IconButton(
                  icon: Icon(EvaIcons.minusCircleOutline),
                  onPressed: () {
                    setState(() {
                      _content!.remove(item);
                      widget.onChanged!(_content);
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
                  _content!.add('');
                  widget.onChanged!(_content);
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  TextField _buildTextField(String item, int index, BuildContext context) {
    final controller = TextEditingController(text: item);
    controller.addListener(() {
      _content![index] = controller.text;
      widget.onChanged!(_content);
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
