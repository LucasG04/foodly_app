import 'package:auto_route/auto_route.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

import '../../../app_router.gr.dart';
import '../../../constants.dart';

class MealListTitle extends StatefulWidget {
  MealListTitle(this.onInputChanged);

  @override
  _MealListTitleState createState() => _MealListTitleState();

  final void Function(String) onInputChanged;
}

class _MealListTitleState extends State<MealListTitle> {
  bool _searchActive = false;
  TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();

    _textEditingController = new TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Center(
        child: Container(
          height: 50.0,
          width: MediaQuery.of(context).size.width > 599
              ? 600
              : MediaQuery.of(context).size.width * 0.9,
          child: Row(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _searchActive ? _buildSearchField() : _buildTitle(),
                ),
              ),
              SizedBox(width: kPadding),
              !_searchActive
                  ? IconButton(
                      icon: Icon(EvaIcons.plusCircleOutline),
                      onPressed: () => ExtendedNavigator.root.push(
                        Routes.mealCreateScreen(id: 'create'),
                      ),
                      splashRadius: 25.0,
                    )
                  : SizedBox(),
              SizedBox(width: kPadding / 2),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _searchActive
                    ? IconButton(
                        icon: Icon(EvaIcons.closeOutline),
                        onPressed: () {
                          _textEditingController.clear();
                          widget.onInputChanged('');
                          setState(() {
                            _searchActive = !_searchActive;
                          });
                        },
                        splashRadius: 25.0,
                      )
                    : IconButton(
                        icon: Icon(EvaIcons.searchOutline),
                        onPressed: () {
                          setState(() {
                            _searchActive = !_searchActive;
                          });
                        },
                        splashRadius: 25.0,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Container(
      width: double.infinity,
      child: Text(
        'Gerichte',
        style: TextStyle(
          fontSize: 32.0,
          fontWeight: FontWeight.w700,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextFormField(
      controller: _textEditingController,
      autofocus: true,
      maxLines: 1,
      onChanged: widget.onInputChanged,
      style: TextStyle(
        fontSize: 32.0,
        fontWeight: FontWeight.w700,
        fontFamily: 'Poppins',
      ),
      decoration: InputDecoration(
        hintText: 'Suchen...',
      ),
    );
  }
}
