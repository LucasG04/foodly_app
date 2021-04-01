import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

import '../../constants.dart';

class EditListContent extends StatefulWidget {
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
  _EditListContentState createState() => _EditListContentState();
}

class _EditListContentState extends State<EditListContent> {
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
        ...widget.content
            .asMap()
            .map((index, value) {
              return MapEntry(
                index,
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _ListInput(
                        initialValue: value,
                        onChanged: (newValue) {
                          widget.content[index] = newValue;
                          widget.onChanged(widget.content);
                        },
                        onAdd: _addNewLine,
                      ),
                    ),
                    IconButton(
                      icon: Icon(EvaIcons.minusCircleOutline),
                      onPressed: () {
                        widget.content.removeAt(index);
                        widget.onChanged(widget.content);
                      },
                    ),
                  ],
                ),
              );
            })
            .values
            .toList(),
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

  void _addNewLine() {
    widget.content.add('');
    widget.onChanged(widget.content);
  }
}

class _ListInput extends StatefulWidget {
  final String initialValue;
  final Function(String) onChanged;
  final Function() onAdd;

  _ListInput({
    this.initialValue,
    this.onChanged,
    this.onAdd,
  });

  @override
  _ListInputState createState() => _ListInputState();
}

class _ListInputState extends State<_ListInput> {
  TextEditingController _controller;

  @override
  void initState() {
    _controller = new TextEditingController(text: widget.initialValue);
    _controller.addListener(() {
      widget.onChanged(_controller.text);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
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
      onSubmitted: (_) => widget.onAdd,
    );
  }
}
