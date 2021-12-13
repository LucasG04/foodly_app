import 'dart:async';

import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

import '../../widgets/animate_icons.dart';

class SearchBar extends StatefulWidget {
  final void Function(String) onSearch;

  SearchBar({
    required this.onSearch,
  });

  @override
  _SearchBarState createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  FocusNode _focusNode = FocusNode();
  TextEditingController? _textEditingController;
  AnimateIconController? _closeIconController;
  Timer? _debounce;

  late bool _isLoading;

  @override
  void initState() {
    _isLoading = false;
    _textEditingController = new TextEditingController();
    _closeIconController = new AnimateIconController();
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
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                style: TextStyle(fontSize: 20.0),
                decoration: InputDecoration(
                  suffixIcon: _buildClearIcon(),
                  icon: Icon(EvaIcons.searchOutline),
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                ),
                onChanged: (text) {
                  if (_debounce?.isActive ?? false) _debounce!.cancel();
                  _debounce = Timer(const Duration(milliseconds: 500), () {
                    widget.onSearch(text);
                  });
                },
              ),
            ),
            SizedBox(
              height: 4.0,
              child: _isLoading ? LinearProgressIndicator() : SizedBox(),
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
      duration: Duration(milliseconds: 300),
      color: Theme.of(context).textTheme.bodyText1!.color,
    );
  }
}
