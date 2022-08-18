import 'dart:async';

import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

import '../../widgets/animate_icons.dart';

class SearchBar extends StatefulWidget {
  final void Function(String) onSearch;

  const SearchBar({required this.onSearch, Key? key}) : super(key: key);

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  final FocusNode _focusNode = FocusNode();
  TextEditingController? _textEditingController;
  AnimateIconController? _closeIconController;
  Timer? _debounce;

  late bool _isLoading;

  @override
  void initState() {
    _isLoading = false;
    _textEditingController = TextEditingController();
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
      width: MediaQuery.of(context).size.width > 649
          ? 650.0
          : MediaQuery.of(context).size.width * 0.95,
      child: Card(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: TextFormField(
                focusNode: _focusNode,
                controller: _textEditingController,
                style: const TextStyle(fontSize: 20.0),
                decoration: InputDecoration(
                  suffixIcon: _buildClearIcon(),
                  icon: const Icon(EvaIcons.searchOutline),
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
            SizedBox(
              height: 4.0,
              child: _isLoading
                  ? const LinearProgressIndicator()
                  : const SizedBox(),
            ),
          ],
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
      color: Theme.of(context).textTheme.bodyText1!.color,
    );
  }
}
