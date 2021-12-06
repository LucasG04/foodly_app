import 'package:concentric_transition/concentric_transition.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foodly/services/meal_service.dart';
import 'package:group_list_view/group_list_view.dart';

import '../../../constants.dart';
import '../../../models/meal.dart';
import '../../../providers/state_providers.dart';
import '../../../widgets/user_information.dart';
import '../settings_view/help_slides/help_slide_share_import.dart';
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
            MealListTitle(
              onSearch: (search) {
                setState(() {
                  _searchInput = search;
                  _filterMeals(
                      search, context.read(mealTagFilterProvider).state);
                });
              },
            ),
            Consumer(builder: (context, watch, _) {
              _allMeals = watch(allMealsProvider).state;
              final tagFilter = watch(mealTagFilterProvider).state;
              _filteredMeals = _filterMeals(_searchInput, tagFilter);

              return _filteredMeals != null && _filteredMeals.isNotEmpty
                  ? tagFilter.isEmpty
                      ? _buildRawMealList(_filteredMeals)
                      : _buildGroupedTagList(
                          _groupMealsByTags(
                            this._filteredMeals ?? [],
                            tagFilter,
                          ),
                        )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        UserInformation(
                          'assets/images/undraw_empty.png',
                          'meal_list_empty_title'.tr(),
                          'meal_list_empty_subtitle'.tr(),
                        ),
                        SizedBox(height: kPadding),
                        TextButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            ConcentricPageRoute(
                              builder: (_) => HelpSlideShareImport(),
                            ),
                          ),
                          icon: Icon(EvaIcons.questionMarkCircleOutline),
                          label: Text('meal_list_help_import').tr(),
                        ),
                        SizedBox(height: kPadding),
                        IconButton(
                          onPressed: _refreshMeals,
                          icon: Icon(
                            EvaIcons.refreshOutline,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
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
            ? 600.0
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

  Widget _buildRawMealList(List<Meal> meals) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kPadding / 2),
      child: ListView.builder(
        itemCount: meals.length,
        itemBuilder: (_, index) => MealListTile(meals[index]),
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
      ),
    );
  }

  Widget _buildGroupedTagList(List<TagGroup> groups) {
    return GroupListView(
      itemBuilder: (_, item) => MealListTile(
        groups[item.section].meals[item.index],
      ),
      sectionsCount: groups.length,
      groupHeaderBuilder: (_, group) => _buildSubtitle(
        context,
        groups[group].tag,
      ),
      countOfItemInSection: (section) => groups[section].meals.length,
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
    );
  }

  List<TagGroup> _groupMealsByTags(List<Meal> meals, List<String> tags) {
    final List<TagGroup> tagList =
        tags.map((tag) => new TagGroup(tag, [])).toList();

    for (var group in tagList) {
      group.meals =
          meals.where((element) => element.tags.contains(group.tag)).toList();
    }

    return tagList;
  }

  List<Meal> _filterMeals(String query, List<String> tagList) {
    final mealsCopy = [..._allMeals];
    mealsCopy.sort((m1, m2) => m1.name.compareTo(m2.name));

    if (query.isNotEmpty) {
      return [
        ...mealsCopy
            .where((el) => el.name.toLowerCase().contains(query.toLowerCase()))
            .toList(),
        ...mealsCopy
            .where((el) => el.tags
                .any((t) => t.toLowerCase().contains(query.toLowerCase())))
            .toList(),
        ...mealsCopy
            .where((el) => el.tags.any((tag) => tagList.contains(tag)))
            .toList()
      ].toSet().toList();
    }
    return mealsCopy;
  }

  Future<void> _refreshMeals() async {
    final activePlan = context.read(planProvider).state;
    final meals = await MealService.getAllMeals(activePlan.id);
    context.read(allMealsProvider).state = meals;
  }
}

class TagGroup {
  List<Meal> meals;
  String tag;

  TagGroup(this.tag, this.meals);
}
