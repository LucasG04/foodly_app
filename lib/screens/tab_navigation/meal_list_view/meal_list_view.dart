import 'package:flutter/material.dart';
import 'package:foodly/constants.dart';
import 'package:foodly/models/meal.dart';
import 'package:foodly/screens/tab_navigation/meal_list_view/meal_list_tile.dart';
import 'package:foodly/services/meal_service.dart';
import 'package:foodly/widgets/page_title.dart';
import 'package:group_list_view/group_list_view.dart';

class MealListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: kPadding),
            PageTitle(text: 'Gerichte'),
            FutureBuilder<List<Meal>>(
              future: MealService.getMeals(100),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final tagList = _groupMealsByTags(snapshot.data);

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
                } else {
                  // TODO: Skeleton
                  return Container();
                }
              },
            ),
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
}

class TagGroup {
  String tag;
  List<Meal> meals;

  TagGroup(this.tag, this.meals);
}
