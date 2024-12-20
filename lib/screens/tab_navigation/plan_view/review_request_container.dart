import 'package:custom_rating_bar/custom_rating_bar.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReviewRequestContainer extends ConsumerStatefulWidget {
  const ReviewRequestContainer({Key? key}) : super(key: key);

  @override
  _ReviewRequestContainerState createState() => _ReviewRequestContainerState();
}

class _ReviewRequestContainerState
    extends ConsumerState<ReviewRequestContainer> {
  final double _rating = 0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(EvaIcons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Row(
                children: [
                  RatingBar(
                    filledIcon: EvaIcons.star,
                    filledColor: Theme.of(context).primaryColor,
                    emptyIcon: EvaIcons.starOutline,
                    onRatingChanged: (value) => debugPrint('$value'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
