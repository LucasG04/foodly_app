import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../constants.dart';
import '../providers/state_providers.dart';
import '../services/in_app_purchase_service.dart';
import '../utils/analytics.dart';
import '../utils/widget_utils.dart';
import 'disposable_widget.dart';
import 'list_tile_card.dart';
import 'main_button.dart';
import 'scroll_shadow_layout.dart';
import 'small_circular_progress_indicator.dart';

/// Premium features, in the order the paywall lists them by default.
enum PremiumFeature {
  ai,
  suggestions,
  shoppingListSort,
  autocomplete,
  stats,
  color,
}

class GetPremiumModal extends ConsumerStatefulWidget {
  /// Where the paywall was opened from, sent with the paywall/purchase events.
  final String source;

  /// Listed first, e.g. the feature whose limit the user just hit.
  final PremiumFeature? highlight;

  const GetPremiumModal({required this.source, this.highlight, super.key});

  /// Opens the paywall. Drag-to-dismiss is off because it fights the inner
  /// scroll view.
  static Future<void> show(
    BuildContext context, {
    required String source,
    PremiumFeature? highlight,
  }) {
    return WidgetUtils.showFoodlyBottomSheet<void>(
      context: context,
      enableDrag: false,
      builder: (_) => GetPremiumModal(source: source, highlight: highlight),
    );
  }

  @override
  _GetPremiumModalState createState() => _GetPremiumModalState();
}

class _GetPremiumModalState extends ConsumerState<GetPremiumModal>
    with DisposableWidget {
  final _log = Logger('GetPremiumModal');
  late final AutoDisposeStateProvider<_PurchaseState> _$purchaseState;
  late final AutoDisposeStateProvider<int> _$selectedPremiumDuration;

  final products = [
    _PremiumDuration('get_premium_modal_monthly'),
    _PremiumDuration('get_premium_modal_yearly'),
  ];

  @override
  void initState() {
    _$purchaseState = AutoDisposeStateProvider(
      (ref) => ref.read(InAppPurchaseService.$userIsSubscribed)
          ? _PurchaseState.purchased
          : _PurchaseState.none,
    );
    _$selectedPremiumDuration = AutoDisposeStateProvider((_) => 1);
    super.initState();

    if (!ref.read(InAppPurchaseService.$userIsSubscribed)) {
      logEvent(AnalyticsEvent.paywallView, {'source': widget.source});
    }
    _getAdditionalProductInfo();
  }

  @override
  void dispose() {
    cancelSubscriptions();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ScrollShadowLayout(
            header: Container(
              padding: const EdgeInsets.all(kPadding / 2),
              color: Theme.of(context).dialogTheme.backgroundColor,
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: kPadding / 2),
                      child: Text(
                        'get_premium_modal_title'
                            .tr(args: [kAppName]).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(EvaIcons.close),
                    onPressed: _close,
                  ),
                ],
              ),
            ),
            body: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: kPadding),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: kPadding / 2),
                          child: Text(
                            'get_premium_modal_subtitle'.tr(),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        ..._buildFeatures(),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: kPadding),
                          child: Center(
                            child: Text(
                              'get_premium_modal_3_description'.tr(),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.only(
            top: kPadding / 2,
            bottom: kPadding / 2,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPremiumDurationSelector(context),
              if (Platform.isIOS || Platform.isMacOS)
                Padding(
                  padding: const EdgeInsets.only(top: kPadding / 4),
                  child: Text(
                    'get_premium_modal_7_description'.tr(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: kPadding / 2),
              MainButton(
                onTap: _subscribeToPremium,
                text: 'get_premium_modal_cta'.tr(args: [kAppName]),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: _close,
                    child: Text('get_premium_modal_not_now'.tr()),
                  ),
                  TextButton(
                    onPressed: _restorePurchase,
                    child: Text('get_premium_modal_restore'.tr()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFeatures() {
    final limits = ref.watch(aiLimitsProvider).valueOrNull;
    final features = {
      PremiumFeature.ai: ListTileCard(
        iconData: Icons.auto_awesome,
        title: 'get_premium_modal_8_title'.tr(),
        description: [
          'get_premium_modal_8_description'.tr(),
          if (limits != null)
            'get_premium_modal_8_free_limits'.tr(
              args: [limits.text, limits.instagram, limits.kcal]
                  .map((e) => e.toString())
                  .toList(),
            ),
        ].join('\n'),
      ),
      PremiumFeature.suggestions: ListTileCard(
        iconData: EvaIcons.trendingUpOutline,
        title: 'get_premium_modal_2_title'.tr(),
        description: 'get_premium_modal_2_description'.tr(),
      ),
      PremiumFeature.shoppingListSort: ListTileCard(
        iconData: Icons.sort_rounded,
        title: 'get_premium_modal_5_title'.tr(),
        description: 'get_premium_modal_5_description'.tr(),
      ),
      PremiumFeature.autocomplete: ListTileCard(
        iconData: EvaIcons.loaderOutline,
        title: 'get_premium_modal_1_title'.tr(),
        description: 'get_premium_modal_1_description'.tr(),
      ),
      PremiumFeature.stats: ListTileCard(
        iconData: EvaIcons.activityOutline,
        title: 'get_premium_modal_4_title'.tr(),
        description: 'get_premium_modal_4_description'.tr(),
      ),
      PremiumFeature.color: ListTileCard(
        iconData: EvaIcons.colorPaletteOutline,
        title: 'get_premium_modal_6_title'.tr(),
        description: 'get_premium_modal_6_description'.tr(args: [kAppName]),
      ),
    };
    return [
      if (widget.highlight != null) widget.highlight!,
      ...PremiumFeature.values.where((e) => e != widget.highlight),
    ].map((e) => features[e]!).toList();
  }

  Widget _buildPremiumDurationSelector(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Consumer(
      builder: (context, ref, _) {
        final purchaseState = ref.watch(_$purchaseState);
        final selectedDuration = ref.watch(_$selectedPremiumDuration);
        return Container(
          decoration: purchaseState == _PurchaseState.none
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(kRadius),
                  color: kGreyBackgroundColor,
                )
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: purchaseState == _PurchaseState.pending
                ? [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: kPadding),
                      child: SmallCircularProgressIndicator(),
                    ),
                  ]
                : purchaseState == _PurchaseState.purchased
                    ? [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: kPadding,
                          ),
                          child: Text(
                            'get_premium_modal_thanks'.tr(args: ['🙂']),
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ]
                    : products.map((e) {
                        final index = products.indexOf(e);
                        final isSelected = selectedDuration == index;
                        return InkWell(
                          onTap: () => ref
                              .read(_$selectedPremiumDuration.notifier)
                              .state = index,
                          child: Container(
                            height: width * 0.2,
                            width: width * 0.4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(kRadius),
                              border: isSelected
                                  ? Border.all(
                                      color: Theme.of(context).primaryColor,
                                      width: 2.5,
                                    )
                                  : null,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  e.title.tr(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(e.price ?? '-'),
                                if (e.pricePerMonth != null)
                                  Text(
                                    'get_premium_modal_yearly_detail'.tr(
                                      args: [e.pricePerMonth!],
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
          ),
        );
      },
    );
  }

  void _close() {
    if (!mounted) {
      return;
    }
    Navigator.pop(context);
  }

  void _getAdditionalProductInfo() {
    try {
      final yearly = InAppPurchaseService.products[1];
      products[0].price = InAppPurchaseService.products[0].priceString;
      products[1]
        ..price = yearly.priceString
        ..pricePerMonth = yearly.pricePerMonthString;
    } catch (e) {
      _log.severe(e);
    }
  }

  Future<void> _restorePurchase() async {
    ref.read(_$purchaseState.notifier).state = _PurchaseState.pending;
    final success = await InAppPurchaseService.restore();
    logEvent(AnalyticsEvent.purchaseRestore, {'success': success.toString()});
    if (mounted) {
      await _handlePurchase(success);
    }
  }

  Future<void> _subscribeToPremium() async {
    ref.read(_$purchaseState.notifier).state = _PurchaseState.pending;
    final index = ref.read(_$selectedPremiumDuration);
    final products = InAppPurchaseService.products;
    if (products.isNotEmpty) {
      final product = products[index].identifier;
      logEvent(
        AnalyticsEvent.purchaseStart,
        {'product': product, 'source': widget.source},
      );
      final success = await InAppPurchaseService.buy(products[index]);
      logEvent(
        AnalyticsEvent.purchaseResult,
        {
          'product': product,
          'source': widget.source,
          'success': success.toString(),
        },
      );
      if (mounted) {
        await _handlePurchase(success);
      }
    } else {
      ref.read(_$purchaseState.notifier).state = _PurchaseState.none;
    }
  }

  Future<void> _handlePurchase(bool success) async {
    if (success) {
      ref.read(_$purchaseState.notifier).state = _PurchaseState.purchased;
      await Future<dynamic>.delayed(const Duration(seconds: 1));
      _close();
    } else {
      ref.read(_$purchaseState.notifier).state = _PurchaseState.none;
    }
  }
}

class _PremiumDuration {
  String title;
  String? price;

  /// Only set for the yearly plan.
  String? pricePerMonth;

  _PremiumDuration(this.title);
}

enum _PurchaseState {
  none,
  pending,
  purchased,
  // ignore: unused_field
  error,
}
