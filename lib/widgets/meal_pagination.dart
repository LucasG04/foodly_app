import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants.dart';
import '../models/meal.dart';
import '../screens/tab_navigation/meal_list_view/meal_list_tile.dart';
import '../utils/basic_utils.dart';
import 'small_circular_progress_indicator.dart';
import 'user_information.dart';

class MealPagination extends ConsumerStatefulWidget {
  /// Returns the next page of meals.
  /// The last loaded meal id will be passed
  /// (if it's the first load, `null` is passed).
  final Future<List<Meal>> Function(String?) loadNextMeals;

  /// Builds a meal tile with the passed meal
  final Widget Function(Meal) buildMeal;

  final ScrollController scrollController;

  const MealPagination({
    required this.loadNextMeals,
    required this.buildMeal,
    required this.scrollController,
    Key? key,
  }) : super(key: key);

  @override
  _MealPaginationState createState() => _MealPaginationState();
}

class _MealPaginationState extends ConsumerState<MealPagination> {
  late AutoDisposeStateProvider<bool> _$isLoading;
  late StateProvider<bool> _$isLoadingPagination;
  late StateProvider<List<Meal>> _$loadedMeals;

  bool _paginationAtEnd = false;

  @override
  void initState() {
    _$isLoading = StateProvider.autoDispose<bool>((_) => true);
    _$isLoadingPagination = StateProvider<bool>((_) => false);
    _$loadedMeals = StateProvider<List<Meal>>((_) => []);

    _loadNextMeals().then((_) => ref.read(_$isLoading.state).state = false);
    widget.scrollController.addListener(_scrollListener);
    super.initState();
  }

  @override
  void dispose() {
    widget.scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, watch, _) {
      final loadedMeals = ref.watch(_$loadedMeals);
      final isLoading = ref.watch(_$isLoading);

      if (isLoading) {
        return _buildLoadingMealList();
      }

      if (loadedMeals.isEmpty) {
        return _buildEmptyMeals();
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: ListView.builder(
              itemCount: loadedMeals.length,
              itemBuilder: (_, index) => widget.buildMeal(loadedMeals[index]),
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
            ),
          ),
          Consumer(builder: (context, watch, _) {
            final isLoadingPagination = ref.watch(_$isLoadingPagination);
            return isLoadingPagination
                ? Container(
                    margin: const EdgeInsets.only(
                      bottom: kPadding,
                    ),
                    width: double.infinity,
                    child: const Center(
                      child: SmallCircularProgressIndicator(),
                    ),
                  )
                : const SizedBox();
          }),
        ],
      );
    });
  }

  Padding _buildLoadingMealList() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kPadding / 2),
      child: ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(
          10,
          (_) => const MealListTile(null),
        ),
      ),
    );
  }

  Widget _buildEmptyMeals() {
    return Column(
      children: [
        UserInformation(
          assetPath: 'assets/images/undraw_empty.png',
          title: 'meal_list_empty_title'.tr(),
          message: 'meal_list_empty_subtitle'.tr(),
        ),
      ],
    );
  }

  void _scrollListener() {
    if (_paginationAtEnd) {
      return;
    }
    final loadNew = widget.scrollController.offset >=
        widget.scrollController.position.maxScrollExtent * 0.7;

    if (!loadNew) {
      return;
    }
    _loadNextMeals();
  }

  Future<void> _loadNextMeals() async {
    if (!mounted) {
      return;
    }
    BasicUtils.afterBuild(
        () => ref.read(_$isLoadingPagination.state).state = true);
    const pageSize = 30;
    final currentMeals = ref.read(_$loadedMeals);

    final nextMeals = await widget.loadNextMeals(
      currentMeals.isEmpty ? null : currentMeals.last.id,
    );

    _paginationAtEnd = nextMeals.length < pageSize;

    if (!mounted) {
      return;
    }

    ref.read(_$loadedMeals.state).state = [...currentMeals, ...nextMeals];
    ref.read(_$isLoadingPagination.state).state = false;
  }
}
