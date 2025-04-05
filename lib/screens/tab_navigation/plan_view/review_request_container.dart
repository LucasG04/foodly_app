import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:custom_rating_bar/custom_rating_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';

import '../../../app_router.gr.dart';
import '../../../constants.dart';
import '../../../services/app_review_service.dart';
import '../../../utils/main_snackbar.dart';

class ReviewRequestContainer extends ConsumerStatefulWidget {
  const ReviewRequestContainer({super.key});

  @override
  _ReviewRequestContainerState createState() => _ReviewRequestContainerState();
}

class _ReviewRequestContainerState extends ConsumerState<ReviewRequestContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _ratingProvider = StateProvider<double>((ref) => 0);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: InAppReview.instance.isAvailable(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!) {
          return const SizedBox();
        }
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Center(
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: const [kSmallShadow],
                  gradient: SweepGradient(
                    colors: const [
                      Colors.pink,
                      Colors.red,
                      Colors.purple,
                      Colors.deepPurple,
                      Colors.red,
                    ],
                    transform: GradientRotation(_controller.value * 2 * 3.14),
                  ),
                  borderRadius: BorderRadius.circular(kRadius),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(kRadius),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topRight,
                            child: _buildDiscardButton(context),
                          ),
                          Center(
                            child: _buildContentColumn(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDiscardButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        AppReviewService.discardRequest();
      },
      child: SizedBox(
        width: (Theme.of(context).iconTheme.size ?? 24) + 10,
        height: (Theme.of(context).iconTheme.size ?? 24) + 10,
        child: const Align(
          alignment: Alignment.topRight,
          child: Icon(EvaIcons.close),
        ),
      ),
    );
  }

  Widget _buildContentColumn(BuildContext context) {
    return Consumer(
      builder: (context, watch, _) => AnimatedCrossFade(
        firstChild: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'plan_rate_title'.tr(args: [kAppName]),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5.0),
            RatingBar(
              filledIcon: EvaIcons.star,
              emptyIcon: EvaIcons.starOutline,
              onRatingChanged: (v) =>
                  ref.read(_ratingProvider.notifier).state = v,
              filledColor: Theme.of(context).primaryColor,
              alignment: Alignment.center,
            ),
          ],
        ),
        secondChild: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              onPressed: () {
                AutoRouter.of(context).push(const FeedbackScreenRoute());
                AppReviewService.discardRequest();
              },
              label: const Text('plan_rate_feedback').tr(),
              icon: const Icon(EvaIcons.paperPlaneOutline),
            ),
            if (ref.watch(_ratingProvider) >= 4)
              TextButton.icon(
                onPressed: () {
                  AppReviewService.requestReview();
                  MainSnackbar(
                    message: 'feedback_thanks'.tr(args: ['🎉🎉']),
                    isSuccess: true,
                  ).show(context);
                },
                label: const Text('plan_rate_review')
                    .tr(args: Platform.isIOS ? ['App'] : ['Play']),
                icon: const Icon(EvaIcons.starOutline),
              ),
          ],
        ),
        crossFadeState: ref.watch(_ratingProvider) == 0
            ? CrossFadeState.showFirst
            : CrossFadeState.showSecond,
        duration: const Duration(milliseconds: 500),
      ),
    );
  }
}
