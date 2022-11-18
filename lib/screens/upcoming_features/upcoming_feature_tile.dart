import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:like_button/like_button.dart';

import '../../constants.dart';
import '../../models/upcoming_feature.dart';
import '../../providers/state_providers.dart';

class UpcomingFeatureTile extends ConsumerWidget {
  final UpcomingFeature upcomingFeature;

  const UpcomingFeatureTile(this.upcomingFeature, {Key? key}) : super(key: key);

  TextStyle get _titleStyle => const TextStyle(fontSize: 16);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.read(userProvider)!.id!;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(kPadding / 2),
        child: Row(
          children: [
            Expanded(child: Text(upcomingFeature.title, style: _titleStyle)),
            const SizedBox(width: kPadding / 2),
            LikeButton(
              bubblesColor: BubblesColor(
                dotPrimaryColor: Theme.of(context).primaryColor,
                dotSecondaryColor: Theme.of(context).secondaryHeaderColor,
              ),
              isLiked: upcomingFeature.votes.contains(userId),
              likeCount: upcomingFeature.votes.length,
              likeBuilder: (bool isLiked) => Icon(
                Icons.thumb_up_rounded,
                color: isLiked ? Theme.of(context).primaryColor : Colors.grey,
                size: 20.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
