import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foodly/providers/state_providers.dart';
import 'package:foodly/widgets/small_circular_progress_indicator.dart';
import 'package:group_list_view/group_list_view.dart';

import '../../../constants.dart';
import '../../../models/meal.dart';
import '../../../services/meal_service.dart';
import 'meal_list_tile.dart';
import 'meal_list_title.dart';

class MealListView extends StatefulWidget {
  @override
  _MealListViewState createState() => _MealListViewState();
}

class _MealListViewState extends State<MealListView>
    with AutomaticKeepAliveClientMixin {
  List<Meal> _allMeals;
  List<Meal> _filteredMeals;
  String _searchInput = '';

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: kPadding),
            MealListTitle((search) {
              setState(() {
                _searchInput = search;
                _filterMeals(search);
              });
            }),
            Consumer(builder: (context, watch, _) {
              _allMeals = watch(allMealsProvider).state;
              _filterMeals(_searchInput);
              final tagList = _groupMealsByTags(this._filteredMeals ?? []);
              return GroupListView(
                itemBuilder: (_, item) => MealListTile(
                  tagList[item.section].meals[item.index],
                ),
                sectionsCount: tagList.length,
                groupHeaderBuilder: (_, group) => _buildSubtitle(
                  context,
                  tagList[group].tag,
                ),
                countOfItemInSection: (section) =>
                    tagList[section].meals.length,
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
              );
            })
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitle(context, String value) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width > 599
            ? 600
            : MediaQuery.of(context).size.width * 0.9,
        margin: const EdgeInsets.only(top: kPadding),
        child: Text(
          value,
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  List<TagGroup> _groupMealsByTags(List<Meal> meals) {
    final List<TagGroup> tagList = [];

    for (var meal in meals) {
      for (var tag in meal.tags) {
        if (!tagList.contains(tag)) {
          tagList.add(TagGroup(tag, []));
        }
      }
    }

    for (var group in tagList) {
      group.meals =
          meals.where((element) => element.tags.contains(group.tag)).toList();
    }

    if (meals.any((element) => element.tags == null || element.tags.isEmpty)) {
      tagList.add(
        TagGroup(
          'Ohne Tag',
          meals
              .where((element) => element.tags == null || element.tags.isEmpty)
              .toList(),
        ),
      );
    }

    return tagList;
  }

  void _filterMeals(String query) {
    if (query.isNotEmpty) {
      this._filteredMeals = this
          ._allMeals
          .where((el) => el.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } else {
      this._filteredMeals = this._allMeals;
    }
  }
}

class TagGroup {
  String tag;
  List<Meal> meals;

  TagGroup(this.tag, this.meals);
}
