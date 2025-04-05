import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/upcoming_feature.dart';
import '../../services/lunix_api_service.dart';
import '../../widgets/main_appbar.dart';
import '../../widgets/small_circular_progress_indicator.dart';
import 'upcoming_feature_tile.dart';

class UpcomingFeaturesScreen extends ConsumerStatefulWidget {
  const UpcomingFeaturesScreen({super.key});

  @override
  _UpcomingFeaturesScreenState createState() => _UpcomingFeaturesScreenState();
}

class _UpcomingFeaturesScreenState
    extends ConsumerState<UpcomingFeaturesScreen> {
  final ScrollController _scrollController = ScrollController();

  final AutoDisposeStateProvider<bool> _$isLoading =
      AutoDisposeStateProvider((_) => true);

  List<UpcomingFeature> _upcomingFeatures = [];

  @override
  void initState() {
    super.initState();

    LunixApiService.getUpcomingFeatures().then((value) {
      _upcomingFeatures = value;
      ref.read(_$isLoading.notifier).state = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fullWidth = MediaQuery.of(context).size.width > 699
        ? 700.0
        : MediaQuery.of(context).size.width * 0.9;

    return Scaffold(
      appBar: MainAppBar(
        text: 'upcoming_features_title'.tr(),
        scrollController: _scrollController,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Center(
          child: SizedBox(
            width: fullWidth,
            child: Consumer(builder: (context, ref, _) {
              final isLoading = ref.watch(_$isLoading);
              return isLoading
                  ? const SizedBox(
                      height: 60.0,
                      child: Center(
                        child: SmallCircularProgressIndicator(),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _upcomingFeatures.length,
                      itemBuilder: (context, index) => UpcomingFeatureTile(
                        _upcomingFeatures[index],
                      ),
                    );
            }),
          ),
        ),
      ),
    );
  }
}
