import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logging/logging.dart';

import '../constants.dart';
import '../services/in_app_purchase_service.dart';
import 'disposable_widget.dart';
import 'list_tile_card.dart';
import 'main_button.dart';
import 'small_circular_progress_indicator.dart';

class GetPremiumModal extends StatefulWidget {
  const GetPremiumModal({Key? key}) : super(key: key);

  @override
  State<GetPremiumModal> createState() => _GetPremiumModalState();
}

class _GetPremiumModalState extends State<GetPremiumModal>
    with DisposableWidget {
  final _log = Logger('GetPremiumModal');
  late final ScrollController _scrollController;
  late final AutoDisposeStateProvider<bool> _$titleShowShadow;
  late final AutoDisposeStateProvider<_PurchaseState> _$purchaseState;
  late final AutoDisposeStateProvider<int> _$selectedPremiumDuration;

  final premiumDurations = [
    _PremiumDuration('get_premium_modal_monthly'),
    _PremiumDuration('get_premium_modal_yearly'),
  ];

  @override
  void initState() {
    _$titleShowShadow = AutoDisposeStateProvider((_) => false);
    _$purchaseState =
        AutoDisposeStateProvider((_) => _getCurrentPurchaseStateFromService());
    _$selectedPremiumDuration = AutoDisposeStateProvider((_) => 1);
    _scrollController = ScrollController();
    _scrollController.addListener(_handleTitleShadowState);
    super.initState();

    _listenOnPurchaseStatus();
    _getPricesFromService();

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
            final showShadow = ref(_$titleShowShadow).state;
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
      builder: (context, watch, _) {
        final purchaseState = watch(_$purchaseState).state;
        final selectedDuration = watch(_$selectedPremiumDuration).state;
        return Container(
          decoration: purchaseState == _PurchaseState.pending
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(kRadius),
                  color: Colors.grey[200],
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
                    )
                  ]
                : purchaseState == _PurchaseState.purchased
                    ? [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: kPadding,
                          ),
                          child: Text(
                            'get_premium_modal_thanks'.tr(args: ['🙂']),
                          ),
                        )
                      ]
                    : premiumDurations.map((e) {
                        final index = premiumDurations.indexOf(e);
                        final isSelected = selectedDuration == index;
                        return InkWell(
                          onTap: () =>
                              watch(_$selectedPremiumDuration).state = index,
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

  _PurchaseState _getCurrentPurchaseStateFromService() {
    final status = InAppPurchaseService.currentPurchaseStatus;
    if (status == PurchaseStatus.purchased ||
        status == PurchaseStatus.restored) {
      return _PurchaseState.purchased;
    } else if (status == PurchaseStatus.error ||
        status == PurchaseStatus.canceled) {
      return _PurchaseState.error;
    } else if (status == PurchaseStatus.pending) {
      return _PurchaseState.pending;
    } else {
      return _PurchaseState.none;
    }
  }

  void _close() {
    if (!mounted) {
      return;
    }
    Navigator.pop(context);
  }

  void _handleTitleShadowState() {
    final showShadow = context.read(_$titleShowShadow).state;
    if (_scrollController.offset > 0 && !showShadow) {
      context.read(_$titleShowShadow).state = true;
    } else if (_scrollController.offset <= 0 && showShadow) {
      context.read(_$titleShowShadow).state = false;
    }
  }

  void _listenOnPurchaseStatus() {
    InAppPurchaseService.$purchaseStatus.listen((status) {
      if (status == PurchaseStatus.purchased ||
          status == PurchaseStatus.restored) {
        context.read(_$purchaseState).state = _PurchaseState.purchased;
        Future.delayed(const Duration(seconds: 3), () => _close());
      }
      if (status == PurchaseStatus.error || status == PurchaseStatus.canceled) {
        context.read(_$purchaseState).state = _PurchaseState.error;
      }
      if (status == PurchaseStatus.pending) {
        context.read(_$purchaseState).state = _PurchaseState.pending;
      }
    }).canceledBy(this);
  }

  void _getPricesFromService() {
    try {
      premiumDurations[0].price = InAppPurchaseService.products[0].price;
      premiumDurations[1].price = InAppPurchaseService.products[1].price;
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
    context.read(_$purchaseState).state = _PurchaseState.pending;
    await InAppPurchaseService.restore();
  }

  Future<void> _subscribeToPremium() async {
    context.read(_$purchaseState).state = _PurchaseState.pending;
    final index = context.read(_$selectedPremiumDuration).state;
    final products = InAppPurchaseService.products;
    if (products.isNotEmpty) {
      await InAppPurchaseService.buy(products[index]);
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
  error,
}
