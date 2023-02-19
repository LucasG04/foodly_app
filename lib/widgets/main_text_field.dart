import 'package:clipboard/clipboard.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants.dart';

class MainTextField extends ConsumerStatefulWidget {
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
  final int? errorMaxLines;
  final String Function(String?)? validator;
  final bool required;
  final List<String>? autofillHints;
  final TextCapitalization? textCapitalization;
  final bool pasteFromClipboard;
  final bool Function(String)? pasteValidator;
  final bool submitOnPaste;

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
    this.errorMaxLines,
    this.validator,
    this.required = false,
    this.autofillHints,
    this.textCapitalization,
    this.pasteFromClipboard = false,
    this.pasteValidator,
    this.submitOnPaste = false,
    Key? key,
  })  : assert(
            (obscureText && !pasteFromClipboard) ||
                (!obscureText && pasteFromClipboard) ||
                (!obscureText && !pasteFromClipboard),
            'You cannot use both obscureText and pastFromClipboard'),
        super(key: key);

  @override
  ConsumerState<MainTextField> createState() => _MainTextFieldState();
}

class _MainTextFieldState extends ConsumerState<MainTextField> {
  final _$hasFocus = AutoDisposeStateProvider<bool>((_) => false);
  late bool _obscureText;
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
      onFocusChange: (value) {
        ref.read(_$hasFocus.notifier).state = value;
        if (!value) {
          // prevent repeated unwanted focus after unfocus by modal
          // FocusScope.of(context).requestFocus(FocusNode());
        }
      },
      child: TextFormField(
        controller: widget.controller,
        autofocus: widget.autofocus,
        focusNode: _focusNode,
        autofillHints: widget.autofillHints,
        textCapitalization:
            widget.textCapitalization ?? TextCapitalization.none,
        cursorColor: Theme.of(context).primaryColor,
        decoration: InputDecoration(
          hintText: widget.placeholder,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
          ),
          fillColor: ref.read(_$hasFocus)
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
                        ? Icon(
                            EvaIcons.eyeOutline,
                            size: kIconHeight,
                            color: Theme.of(context).primaryColor,
                          )
                        : Icon(
                            EvaIcons.eyeOff2Outline,
                            size: kIconHeight,
                            color: Theme.of(context).primaryColor,
                          ),
                  ),
                )
              : widget.pasteFromClipboard
                  ? IconButton(
                      onPressed: () async {
                        final text = (await FlutterClipboard.paste()).trim();

                        if (text.isEmpty) {
                          return;
                        }
                        if (widget.pasteValidator == null ||
                            !widget.pasteValidator!(text)) {
                          return;
                        }
                        widget.controller!.text = text;
                        if (widget.submitOnPaste) {
                          widget.onSubmit!();
                        }
                      },
                      icon: const Icon(EvaIcons.clipboardOutline),
                      splashRadius: kIconHeight,
                    )
                  : null,
          errorText: widget.errorText,
          errorMaxLines: widget.errorMaxLines,
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
    );
  }
}
