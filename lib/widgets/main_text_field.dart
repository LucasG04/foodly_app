import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

import '../constants.dart';

class MainTextField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? title;
  final String? placeholder;
  final bool isMultiline;
  final TextInputAction textInputAction;
  final TextInputType keyboardType;
  final void Function()? onSubmit;
  final void Function(String)? onChange;
  final bool isDense;
  final bool obscureText;
  final bool autofocus;
  final TextAlign textAlign;
  final Widget? suffix;
  final String? errorText;
  final String Function(String?)? validator;
  final bool required;

  const MainTextField({
    required this.controller,
    this.focusNode,
    this.title,
    this.placeholder,
    this.isMultiline = false,
    this.textInputAction = TextInputAction.done,
    this.keyboardType = TextInputType.text,
    this.onSubmit,
    this.onChange,
    this.isDense = true,
    this.obscureText = false,
    this.autofocus = false,
    this.textAlign = TextAlign.start,
    this.suffix,
    this.errorText,
    this.validator,
    this.required = false,
    Key? key,
  }) : super(key: key);

  @override
  State<MainTextField> createState() => _MainTextFieldState();
}

class _MainTextFieldState extends State<MainTextField> {
  late bool _obscureText;
  bool _hasFocus = false;
  FocusNode? _focusNode;

  @override
  void initState() {
    _obscureText = widget.obscureText;
    _focusNode = widget.focusNode ?? FocusNode();
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.title != null
            ? [
                Text(
                  widget.required
                      ? '${widget.title} *'.trim()
                      : widget.title ?? '',
                  style: const TextStyle(color: Colors.black),
                ),
                const SizedBox(height: 5),
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
        autofocus: widget.autofocus,
        focusNode: _focusNode,
        decoration: InputDecoration(
          hintText: widget.placeholder,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[300]!),
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
                        ? const Icon(EvaIcons.eyeOutline, size: kIconHeight)
                        : const Icon(EvaIcons.eyeOff2Outline,
                            size: kIconHeight),
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

          if (widget.onSubmit != null) {
            widget.onSubmit!();
          }
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
