import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants.dart';
import '../../models/grocery_group.dart';
import '../../providers/data_provider.dart';
import '../../services/settings_service.dart';
import '../../utils/basic_utils.dart';
import '../../widgets/main_appbar.dart';
import '../../widgets/small_circular_progress_indicator.dart';

class ReorderProductGroupsScreen extends StatefulWidget {
  const ReorderProductGroupsScreen({Key? key}) : super(key: key);

  @override
  State<ReorderProductGroupsScreen> createState() =>
      _ReorderProductGroupsScreenState();
}

class _ReorderProductGroupsScreenState
    extends State<ReorderProductGroupsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(
        text: 'reorder_product_groups_title'.tr(),
        scrollController: _scrollController,
      ),
      body: SizedBox(
        width: BasicUtils.contentWidth(context, smallMultiplier: 1),
        child: Consumer(builder: (context, ref, _) {
          final productGroups = ref.watch(dataGroceryGroupsProvider);
          return productGroups == null
              ? const SizedBox(
                  height: 200,
                  child: SmallCircularProgressIndicator(),
                )
              : SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: [
                      StreamBuilder(
                        stream: SettingsService.streamProductGroupOrder(),
                        builder: (context, _) {
                          final sortedGroups = BasicUtils.sortGroceryGroups(
                            productGroups,
                            SettingsService.productGroupOrder,
                          );
                          return ReorderableListView.builder(
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
                            onReorder: (oldIndex, newIndex) =>
                                _updateProductGroupsOrder(
                              oldIndex,
                              newIndex,
                              productGroups,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: kPadding * 2)
                    ],
                  ),
                );
        }),
      ),
    );
  }

  void _updateProductGroupsOrder(
    int oldIndex,
    int newIndex,
    List<GroceryGroup> productGroups,
  ) {
    final List<String> order = List.from(SettingsService.productGroupOrder);
    if (order.length < productGroups.length) {
      order.addAll(productGroups
          .map((e) => e.id)
          .where((element) => !order.contains(element)));
    }
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = order.removeAt(oldIndex);
    order.insert(newIndex, item);
    SettingsService.setProductGroupOrder(order);
  }
}
