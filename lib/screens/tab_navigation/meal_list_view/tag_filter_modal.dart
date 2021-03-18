import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/all.dart';
import 'package:foodly/models/meal.dart';
import 'package:foodly/providers/state_providers.dart';

import '../../../constants.dart';

class TagFilterModal extends StatefulWidget {
  @override
  _TagFilterModalState createState() => _TagFilterModalState();
}

class _TagFilterModalState extends State<TagFilterModal> {
  // empty_space is a distance of empty padding, only after scrolling through it the content starts getting under the app bar.
  static const double EMPTY_SPACE = kPadding / 2;

  bool _isScrollToTop = true;
  ScrollController _scrollController;

  @override
  void dispose() {
    if (_scrollController != null) {
      _scrollController.dispose();
    }

    super.dispose();
  }

  @override
  void initState() {
    _scrollController = new ScrollController();
    _scrollController.addListener(_scrollListener);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final allTags = _getAllTagsFromMeals(context.read(allMealsProvider).state);

    final width = MediaQuery.of(context).size.width > 599
        ? 580.0
        : MediaQuery.of(context).size.width * 0.8;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _buildModalHeader(context, width),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: (MediaQuery.of(context).size.width - width) / 2,
              ),
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    SizedBox(height: kPadding / 2),
                    Consumer(builder: (context, watch, _) {
                      final selectedTags = watch(mealTagFilterProvider).state;
                      return Wrap(
                        runSpacing: kPadding / 2,
                        spacing: kPadding / 2,
                        children: allTags.map(
                          (String tagText) {
                            final bool isSelected =
                                selectedTags.contains(tagText);
                            return _buildFilterChip(
                              tagText,
                              isSelected,
                              selectedTags,
                            );
                          },
                        ).toList(),
                      );
                    }),
                    SizedBox(height: kPadding),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _scrollListener() {
    if (_scrollController.offset <=
        _scrollController.position.minScrollExtent) {
      if (!_isScrollToTop) {
        setState(() {
          _isScrollToTop = true;
        });
      }
    } else {
      if (_scrollController.offset > EMPTY_SPACE && _isScrollToTop) {
        setState(() {
          _isScrollToTop = false;
        });
      }
    }
  }

  Card _buildModalHeader(BuildContext context, double width) {
    return Card(
      margin: const EdgeInsets.all(0),
      color: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: new BorderRadius.only(
          topLeft: const Radius.circular(10.0),
          topRight: const Radius.circular(10.0),
        ),
      ),
      elevation: _isScrollToTop ? 0 : 4.0,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: (MediaQuery.of(context).size.width - width) / 2,
          vertical: kPadding / 2,
        ),
        child: Row(
          children: [
            Text(
              'FILTER',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Spacer(),
            IconButton(
              icon: Icon(EvaIcons.trash2Outline),
              onPressed: () => (context.read(mealTagFilterProvider).state = []),
            ),
            SizedBox(width: kPadding / 2),
            IconButton(
              icon: Icon(EvaIcons.arrowIosDownwardOutline),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  FilterChip _buildFilterChip(
      String tagText, bool isSelected, List<String> selectedTags) {
    return FilterChip(
      label: Text(
        tagText,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
        ),
      ),
      selected: isSelected,
      selectedColor: Theme.of(context).primaryColor,
      selectedShadowColor: Theme.of(context).primaryColor.withOpacity(0.3),
      onSelected: (selected) {
        if (selected) {
          context.read(mealTagFilterProvider).state = [
            ...selectedTags,
            tagText
          ];
        } else {
          context.read(mealTagFilterProvider).state.remove(tagText);
          context.read(mealTagFilterProvider).state =
              context.read(mealTagFilterProvider).state;
        }
      },
    );
  }

  List<String> _getAllTagsFromMeals(List<Meal> meals) {
    final result = meals.map((e) => e.tags).toList(); // get all tags
    final flatResults = result.expand((e) => e).toList(); // flatten the list
    return flatResults.toSet().toList(); // remove duplicates
  }
}
