import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants.dart';
import '../../../providers/state_providers.dart';
import '../../../services/lunix_api_service.dart';
import '../../../widgets/small_circular_progress_indicator.dart';

class TagFilterModal extends StatefulWidget {
  const TagFilterModal({Key? key}) : super(key: key);

  @override
  State<TagFilterModal> createState() => _TagFilterModalState();
}

class _TagFilterModalState extends State<TagFilterModal> {
  // empty_space is a distance of empty padding, only after scrolling through it the content starts getting under the app bar.
  static const double kEmptySpace = kPadding / 2;

  final ScrollController _scrollController = ScrollController();
  bool _isScrollToTop = true;

  @override
  void initState() {
    _scrollController.addListener(_scrollListener);
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    final selectedTags = context.read(mealTagFilterProvider).state;
    if (selectedTags.isNotEmpty) {
      FirebaseAnalytics.instance.logEvent(
        name: 'meal_tag_filter',
        parameters: {'tags': selectedTags.join(', ')},
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width > 700
        ? 700.0
        : MediaQuery.of(context).size.width * 0.9;

    return SizedBox(
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
                    const SizedBox(height: kPadding / 2),
                    FutureBuilder<List<String>>(
                        future: LunixApiService.getAllTagsInPlan(
                          context.read(planProvider).state!.id!,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return _buildLoader();
                          }

                          final tags = snapshot.data ?? [];

                          return Consumer(builder: (context, watch, _) {
                            final selectedTags =
                                watch(mealTagFilterProvider).state;
                            return Wrap(
                              runSpacing: kPadding / 2,
                              spacing: kPadding / 2,
                              children: tags.map(
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
                          });
                        }),
                    const SizedBox(height: kPadding),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoader() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: kPadding),
      child: SmallCircularProgressIndicator(),
    );
  }

  Card _buildModalHeader(BuildContext context, double width) {
    return Card(
      margin: EdgeInsets.zero,
      color: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10.0),
          topRight: Radius.circular(10.0),
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
            const Text(
              'FILTER',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(EvaIcons.trash2Outline),
              onPressed: () => context.read(mealTagFilterProvider).state = [],
            ),
            const SizedBox(width: kPadding / 2),
            IconButton(
              icon: const Icon(EvaIcons.arrowIosDownwardOutline),
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
          context.read(mealTagFilterProvider).state = [];
          selectedTags.remove(tagText);
          context.read(mealTagFilterProvider).state = selectedTags;
        }
      },
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
      if (_scrollController.offset > kEmptySpace && _isScrollToTop) {
        setState(() {
          _isScrollToTop = false;
        });
      }
    }
  }
}
