import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

import '../constants.dart';

class MainTextField extends StatefulWidget {
  final TextEditingController controller;
  final String title;
  final String placeholder;
  final bool isMultiline;
  final TextInputAction textInputAction;
  final TextInputType keyboardType;
  final void Function() onSubmit;
  final void Function(String) onChange;
  final bool isDense;
  final bool obscureText;
  final TextAlign textAlign;
  final Widget suffix;
  final String errorText;
  final String Function(String) validator;

  const MainTextField({
    @required this.controller,
    this.title,
    this.placeholder,
    this.isMultiline = false,
    this.textInputAction = TextInputAction.done,
    this.keyboardType = TextInputType.text,
    this.onSubmit,
    this.onChange,
    this.isDense = true,
    this.obscureText = false,
    this.textAlign = TextAlign.start,
    this.suffix,
    this.errorText,
    this.validator,
  });

  @override
  _MainTextFieldState createState() => _MainTextFieldState();
}

class _MainTextFieldState extends State<MainTextField> {
  bool _hasFocus = false;
  bool _obscureText;

  @override
  void initState() {
    _obscureText = widget.obscureText;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.isDense
          ? const EdgeInsets.symmetric(vertical: 8.0)
          : const EdgeInsets.symmetric(
              horizontal: kPadding,
              vertical: kPadding / 2,
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.title != null
            ? [
                Text(
                  widget.title ?? '',
                  style: TextStyle(color: Colors.black),
                ),
                SizedBox(height: 5),
                _buildInput(),
              ]
            : [
                _buildInput(),
              ],
      ),
    );
  }

  Widget _buildInput() {
    return Focus(
      child: TextFormField(
        controller: widget.controller,
        decoration: InputDecoration(
          hintText: widget.placeholder,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[300]),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[300]),
          ),
          fillColor: _hasFocus
              ? Theme.of(context).scaffoldBackgroundColor
              : Colors.grey[300],
          filled: false,
          isDense: true,
          suffixIcon: widget.obscureText
              ? GestureDetector(
                  onTap: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 125),
                    child: _obscureText
                        ? Icon(EvaIcons.eyeOutline, size: kIconHeight)
                        : Icon(EvaIcons.eyeOff2Outline, size: kIconHeight),
                  ),
                )
              : null,
          errorText: widget.errorText,
        ),
        obscureText: _obscureText,
        textAlign: widget.textAlign,
        keyboardType:
            widget.isMultiline ? TextInputType.multiline : widget.keyboardType,
        textInputAction: widget.textInputAction,
        maxLines: widget.isMultiline ? 5 : 1,
        onEditingComplete: () {
          if (widget.textInputAction == TextInputAction.next) {
            FocusScope.of(context).nextFocus();
          } else {
            FocusScope.of(context).unfocus();
          }

          widget.onSubmit();
        },
        onChanged: widget.onChange,
        validator: widget.validator,
      ),
      onFocusChange: (value) {
        setState(() {
          _hasFocus = value;
        });
      },
    );
  }
}
