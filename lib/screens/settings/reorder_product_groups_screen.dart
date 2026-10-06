import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants.dart';
import '../../models/grocery_group.dart';
import '../../providers/data_provider.dart';
import '../../services/settings_service.dart';
import '../../utils/basic_utils.dart';
import '../../widgets/main_appbar.dart';
import '../../widgets/small_circular_progress_indicator.dart';

class ReorderProductGroupsScreen extends ConsumerStatefulWidget {
  const ReorderProductGroupsScreen({super.key});

  @override
  ConsumerState<ReorderProductGroupsScreen> createState() =>
      _ReorderProductGroupsScreenState();
}

class _ReorderProductGroupsScreenState
    extends ConsumerState<ReorderProductGroupsScreen> {
  final ScrollController _scrollController = ScrollController();

  /// Created once: a new stream per build would resubscribe the Hive watch.
  final _orderStream = SettingsService.streamProductGroupOrder();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productGroups = ref.watch(dataGroceryGroupsProvider).valueOrNull;
    return StreamBuilder(
      stream: _orderStream,
      builder: (context, _) {
        final sortedGroups = productGroups == null
            ? null
            : BasicUtils.sortGroceryGroups(
                productGroups,
                SettingsService.productGroupOrder,
              );
        final isOrderChanged = sortedGroups != null &&
            !listEquals(
              sortedGroups.map((e) => e.id).toList(),
              productGroups!.map((e) => e.id).toList(),
            );

        return Scaffold(
          appBar: MainAppBar(
            text: context.tr('reorder_product_groups_title'),
            scrollController: _scrollController,
            actions: [
              if (isOrderChanged)
                IconButton(
                  icon: Icon(
                    EvaIcons.refreshOutline,
                    color: Theme.of(context).textTheme.bodyLarge?.color ??
                        Colors.black,
                  ),
                  splashRadius: kPadding,
                  tooltip: context.tr('reset'),
                  onPressed: _resetOrder,
                ),
            ],
          ),
          body: Center(
            child: SizedBox(
              width: BasicUtils.contentWidth(context, smallMultiplier: 1),
              child: sortedGroups == null
                  ? const SingleChildScrollView(
                      child: SizedBox(
                        height: 200,
                        child: SmallCircularProgressIndicator(),
                      ),
                    )
                  : SingleChildScrollView(
                      controller: _scrollController,
                      child: Column(
                        children: [
                          ReorderableListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: sortedGroups.length,
                            itemBuilder: (context, index) {
                              return Container(
                                key: ValueKey(sortedGroups[index].id),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: kPadding / 2,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Theme.of(context).dividerColor,
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                                child: ListTile(
                                  title: Text(sortedGroups[index].name),
                                  trailing: const Icon(EvaIcons.menu),
                                ),
                              );
                            },
                            onReorderItem: (oldIndex, newIndex) =>
                                _updateProductGroupsOrder(
                              oldIndex,
                              newIndex,
                              sortedGroups,
                            ),
                          ),
                          const SizedBox(height: kPadding * 2)
                        ],
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _resetOrder() async {
    final result = await showOkCancelAlertDialog(
      context: context,
      title: context.tr('reorder_product_groups_reset_dialog_title'),
      message: context.tr('reorder_product_groups_reset_dialog_description'),
      okLabel: context.tr('reset'),
      isDestructiveAction: true,
    );
    if (result == OkCancelResult.ok) {
      await SettingsService.setProductGroupOrder([]);
    }
  }

  void _updateProductGroupsOrder(
    int oldIndex,
    int newIndex,
    List<GroceryGroup> sortedGroups,
  ) {
    final order = sortedGroups.map((e) => e.id).toList();
    order.insert(newIndex, order.removeAt(oldIndex));
    SettingsService.setProductGroupOrder(order);
  }
}
