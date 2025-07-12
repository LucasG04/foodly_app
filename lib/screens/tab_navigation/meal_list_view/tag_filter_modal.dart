import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants.dart';
import '../../../providers/state_providers.dart';
import '../../../services/lunix_api_service.dart';
import '../../../utils/of_context_mixin.dart';
import '../../../widgets/small_circular_progress_indicator.dart';

class TagFilterModal extends ConsumerStatefulWidget {
  const TagFilterModal({super.key});

  @override
  _TagFilterModalState createState() => _TagFilterModalState();
}

class _TagFilterModalState extends ConsumerState<TagFilterModal>
    with OfContextMixin {
  // empty_space is a distance of empty padding, only after scrolling through it the content starts getting under the app bar.
  static const double kEmptySpace = kPadding / 2;

  final ScrollController _scrollController = ScrollController();
  final _$isScrollToTop = AutoDisposeStateProvider((_) => true);

  @override
  void initState() {
    _scrollController.addListener(_scrollListener);
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = media.size.width > 700 ? 700.0 : media.size.width * 0.9;

    return SizedBox(
      height: media.size.height * 0.8,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _buildModalHeader(context, width),
          Expanded(
            child: Container(
              width: double.infinity,
              color: theme.scaffoldBackgroundColor,
              padding: EdgeInsets.symmetric(
                horizontal: (media.size.width - width) / 2,
              ),
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    const SizedBox(height: kPadding / 2),
                    FutureBuilder<List<String>>(
                        future: LunixApiService.getAllTagsInPlan(
                          ref.read(planProvider)!.id!,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return _buildLoader();
                          }

                          final tags = snapshot.data ?? [];

                          return Consumer(builder: (context, ref, _) {
                            final selectedTags =
                                ref.watch(mealTagFilterProvider);
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

  Widget _buildModalHeader(BuildContext context, double width) {
    return Consumer(builder: (context, ref, _) {
      return Card(
        margin: EdgeInsets.zero,
        color: theme.scaffoldBackgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10.0),
            topRight: Radius.circular(10.0),
          ),
        ),
        elevation: ref.watch(_$isScrollToTop) ? 0 : 2,
        surfaceTintColor: theme.scaffoldBackgroundColor,
        shadowColor: theme.primaryColor,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: (media.size.width - width) / 2,
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
                onPressed: () =>
                    ref.read(mealTagFilterProvider.notifier).state = [],
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
    });
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
      backgroundColor:
          isSelected ? theme.primaryColor : theme.scaffoldBackgroundColor,
      selected: isSelected,
      selectedColor: theme.primaryColor,
      selectedShadowColor: theme.primaryColor.withValues(alpha: 0.3),
      onSelected: (selected) {
        if (selected) {
          ref.read(mealTagFilterProvider.notifier).state = [
            ...selectedTags,
            tagText
          ];
        } else {
          ref.read(mealTagFilterProvider.notifier).state = [];
          selectedTags.remove(tagText);
          ref.read(mealTagFilterProvider.notifier).state = selectedTags;
        }
      },
    );
  }

  void _scrollListener() {
    if (_scrollController.offset <=
        _scrollController.position.minScrollExtent) {
      if (!ref.read(_$isScrollToTop)) {
        ref.read(_$isScrollToTop.notifier).state = true;
      }
    } else {
      if (_scrollController.offset > kEmptySpace && ref.read(_$isScrollToTop)) {
        ref.read(_$isScrollToTop.notifier).state = false;
      }
    }
  }
}
