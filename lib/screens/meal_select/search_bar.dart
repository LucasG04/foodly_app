import 'dart:async';

import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

import '../../utils/of_context_mixin.dart';
import '../../widgets/animate_icons.dart';

class SearchBar extends StatefulWidget {
  final void Function(String) onSearch;

  /// Lets the caller set the text (e.g. a prefilled query).
  final TextEditingController? controller;
  final String? hintText;

  const SearchBar({
    required this.onSearch,
    this.controller,
    this.hintText,
    super.key,
  });

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> with OfContextMixin {
  final FocusNode _focusNode = FocusNode();
  TextEditingController? _textEditingController;
  AnimateIconController? _closeIconController;
  Timer? _debounce;

  @override
  void initState() {
    _textEditingController = widget.controller ?? TextEditingController();
    _closeIconController = AnimateIconController();
    super.initState();
    _focusNode.addListener(() {
      if (mounted && _focusNode.hasFocus) {
        _closeIconController!.animateToEnd!();
      } else {
        _closeIconController!.animateToStart!();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: mediaSize.width > 649 ? 650.0 : mediaSize.width * 0.95,
      child: Card(
        child: TextFormField(
          focusNode: _focusNode,
          controller: _textEditingController,
          style: const TextStyle(fontSize: 20.0),
          cursorColor: theme.primaryColor,
          decoration: InputDecoration(
            hintText: widget.hintText,
            suffixIcon: _buildClearIcon(),
            prefixIcon: Icon(
              EvaIcons.searchOutline,
              color: theme.primaryColor,
            ),
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
          ),
          onChanged: (text) {
            if (_debounce?.isActive ?? false) {
              _debounce!.cancel();
            }
            _debounce = Timer(const Duration(milliseconds: 500), () {
              widget.onSearch(text);
            });
          },
        ),
      ),
    );
  }

  Widget _buildClearIcon() {
    return AnimateIcons(
      onTap: () {
        if (_focusNode.hasFocus) {
          _focusNode.unfocus();
          _textEditingController!.clear();
          widget.onSearch('');
        }
      },
      controller: _closeIconController,
      startIcon: null,
      endIcon: EvaIcons.close,
      color: theme.textTheme.bodyLarge!.color,
    );
  }
}
