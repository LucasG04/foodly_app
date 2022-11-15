import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../constants.dart';
import '../services/in_app_purchase_service.dart';
import 'disposable_widget.dart';
import 'list_tile_card.dart';
import 'main_button.dart';
import 'small_circular_progress_indicator.dart';

class GetPremiumModal extends ConsumerStatefulWidget {
  const GetPremiumModal({Key? key}) : super(key: key);

  @override
  _GetPremiumModalState createState() => _GetPremiumModalState();
}

class _GetPremiumModalState extends ConsumerState<GetPremiumModal>
    with DisposableWidget {
  final _log = Logger('GetPremiumModal');
  late final ScrollController _scrollController;
  late final AutoDisposeStateProvider<bool> _$titleShowShadow;
  late final AutoDisposeStateProvider<_PurchaseState> _$purchaseState;
  late final AutoDisposeStateProvider<int> _$selectedPremiumDuration;

  final products = [
    _PremiumDuration('get_premium_modal_monthly'),
    _PremiumDuration('get_premium_modal_yearly'),
  ];

  @override
  void initState() {
    _$titleShowShadow = AutoDisposeStateProvider((_) => false);
    _$purchaseState = AutoDisposeStateProvider(
      (ref) => ref.read(InAppPurchaseService.$userIsSubscribed)
          ? _PurchaseState.purchased
          : _PurchaseState.none,
    );
    _$selectedPremiumDuration = AutoDisposeStateProvider((_) => 1);
    _scrollController = ScrollController();
    _scrollController.addListener(_handleTitleShadowState);
    super.initState();

    _getAdditionalProductInfo();

    // TODO: add "Und viele weitere Vorteile in der Zukunft. Evtl. mit Link auf offene Issues?"
  }

  @override
  void dispose() {
    _scrollController.dispose();
    cancelSubscriptions();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Consumer(
          builder: (context, ref, child) {
            final showShadow = ref.watch(_$titleShowShadow);
            return Container(
              padding: const EdgeInsets.all(kPadding / 2),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: showShadow
                    ? [
                        const BoxShadow(
                          offset: Offset(0, 1),
                          blurRadius: 1,
                          color: Color.fromRGBO(0, 0, 0, .16),
                        )
                      ]
                    : [],
              ),
              child: child,
            );
          },
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: kPadding / 2),
                  child: Text(
                    'get_premium_modal_title'.tr().toUpperCase(),
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
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
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
                      ListTileCard(
                        iconData: EvaIcons.loaderOutline,
                        title: 'get_premium_modal_1_title'.tr(),
                        description: 'get_premium_modal_1_description'.tr(),
                      ),
                      ListTileCard(
                        iconData: EvaIcons.trendingUpOutline,
                        title: 'get_premium_modal_2_title'.tr(),
                        description: 'get_premium_modal_2_description'.tr(),
                      ),
                      ListTileCard(
                        iconData: EvaIcons.messageCircleOutline,
                        title: 'get_premium_modal_4_title'.tr(),
                        description: 'get_premium_modal_4_description'.tr(),
                      ),
                      ListTileCard(
                        iconData: _getSupportAppIcon(),
                        iconColor: Colors.red,
                        title: 'get_premium_modal_3_title'.tr(
                          args: [kAppName],
                        ),
                        description: 'get_premium_modal_3_description'.tr(),
                      ),
                    ],
                  ),
                ),
              ],
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

  Widget _buildPremiumDurationSelector(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
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
                              .read(_$selectedPremiumDuration.state)
                              .state = index,
                          child: Container(
                            height: width * 0.2,
                            width: width * 0.3,
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
                                Text(e.price ?? ''),
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

  void _handleTitleShadowState() {
    final showShadow = ref.read(_$titleShowShadow);
    if (_scrollController.offset > 0 && !showShadow) {
      ref.read(_$titleShowShadow.state).state = true;
    } else if (_scrollController.offset <= 0 && showShadow) {
      ref.read(_$titleShowShadow.state).state = false;
    }
  }

  void _getAdditionalProductInfo() {
    try {
      products[0].price = InAppPurchaseService.products[0].priceString;
      products[1].price = InAppPurchaseService.products[1].priceString;
    } catch (e) {
      _log.severe(e);
    }
  }

  IconData _getSupportAppIcon() {
    final icons = [
      EvaIcons.heartOutline,
      EvaIcons.starOutline,
      EvaIcons.flashOutline,
      Icons.rocket_launch_outlined,
      Icons.cookie_outlined,
    ];

    final index = Random().nextInt(icons.length);
    return icons[index];
  }

  Future<void> _restorePurchase() async {
    ref.read(_$purchaseState.state).state = _PurchaseState.pending;
    final success = await InAppPurchaseService.restore();
    await _handlePurchase(success);
  }

  Future<void> _subscribeToPremium() async {
    ref.read(_$purchaseState.state).state = _PurchaseState.pending;
    final index = ref.read(_$selectedPremiumDuration);
    final products = InAppPurchaseService.products;
    if (products.isNotEmpty) {
      final success =
          await InAppPurchaseService.buy(products[index].identifier);
      await _handlePurchase(success);
    }
  }

  Future<void> _handlePurchase(bool success) async {
    if (success) {
      ref.read(_$purchaseState.state).state = _PurchaseState.purchased;
      await Future<dynamic>.delayed(const Duration(seconds: 1));
      _close();
    } else {
      ref.read(_$purchaseState.state).state = _PurchaseState.none;
    }
  }
}

class _PremiumDuration {
  String title;
  String? price;

  _PremiumDuration(this.title);
}

enum _PurchaseState {
  none,
  pending,
  purchased,
  // ignore: unused_field
  error,
}
