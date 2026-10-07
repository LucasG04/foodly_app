import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants.dart';
import '../../../providers/state_providers.dart';
import '../../../services/lunix_api_service.dart';
import '../../../utils/of_context_mixin.dart';
import '../../../utils/widget_utils.dart';
import '../../../widgets/scroll_shadow_layout.dart';
import '../../../widgets/sheet_header.dart';
import '../../../widgets/small_circular_progress_indicator.dart';
import '../../../widgets/tag_chip.dart';

class TagFilterModal extends ConsumerStatefulWidget {
  const TagFilterModal({super.key});

  /// Returns a new list with [tag] added or removed; never mutates [tags].
  static List<String> toggleTag(List<String> tags, String tag) =>
      tags.contains(tag)
          ? tags.where((t) => t != tag).toList()
          : [...tags, tag];

  @override
  _TagFilterModalState createState() => _TagFilterModalState();
}

class _TagFilterModalState extends ConsumerState<TagFilterModal>
    with OfContextMixin {
  // Fetched once: the sheet sizes to its content, so refetching on rebuild
  // would collapse it to the loader.
  late final Future<List<String>> _tagsFuture =
      LunixApiService.getAllTagsInPlan(ref.read(planProvider)!.id!);

  @override
  Widget build(BuildContext context) {
    final width = mediaSize.width > 700 ? 700.0 : mediaSize.width * 0.9;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: mediaSize.height * 0.8),
      child: ScrollShadowLayout(
        header: _buildModalHeader(context, width),
        body: Container(
          width: double.infinity,
          color: theme.scaffoldBackgroundColor,
          padding: EdgeInsets.symmetric(
            horizontal: (mediaSize.width - width) / 2,
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                FutureBuilder<List<String>>(
                    future: _tagsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildLoader();
                      }

                      final tags = snapshot.data ?? [];

                      return Consumer(builder: (context, ref, _) {
                        final selectedTags = ref.watch(mealTagFilterProvider);
                        return Wrap(
                          runSpacing: kPadding / 2,
                          spacing: kPadding / 2,
                          children: [
                            for (final tagText in tags)
                              TagChip(
                                label: tagText,
                                selected: selectedTags.contains(tagText),
                                onTap: () {
                                  final filter =
                                      ref.read(mealTagFilterProvider.notifier);
                                  filter.state = TagFilterModal.toggleTag(
                                    selectedTags,
                                    tagText,
                                  );
                                },
                              ),
                          ],
                        );
                      });
                    }),
                SizedBox(height: WidgetUtils.sheetBottomPadding(context)),
              ],
            ),
          ),
        ),
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
    return Card(
      margin: EdgeInsets.zero,
      color: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10.0),
          topRight: Radius.circular(10.0),
        ),
      ),
      elevation: 0,
      surfaceTintColor: theme.scaffoldBackgroundColor,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: (mediaSize.width - width) / 2,
        ),
        child: SheetHeader(
          title: 'Filter',
          padding: const EdgeInsets.only(top: kPadding, bottom: kPadding / 2),
          actions: [
            IconButton(
              icon: const Icon(EvaIcons.trash2Outline),
              onPressed: () =>
                  ref.read(mealTagFilterProvider.notifier).state = [],
            ),
          ],
        ),
      ),
    );
  }
}
