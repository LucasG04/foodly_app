import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/image_cache_manager.dart';
import 'skeleton_container.dart';

class FoodlyNetworkImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit boxFit;

  const FoodlyNetworkImage(
    this.imageUrl, {
    this.boxFit = BoxFit.cover,
    super.key,
  });

  @override
  State<FoodlyNetworkImage> createState() => _FoodlyNetworkImageState();
}

class _FoodlyNetworkImageState extends State<FoodlyNetworkImage> {
  late Future<Uint8List?> _imageFuture;

  @override
  void initState() {
    super.initState();
    _imageFuture = ImageCacheManager.loadImage(widget.imageUrl);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
        future: _imageFuture,
        builder: (context, snapshot) {
          Widget child;
          if (snapshot.connectionState == ConnectionState.waiting) {
            child = _buildLoader();
          } else if (snapshot.hasError) {
            child = _buildFallbackImage();
          } else if (snapshot.hasData) {
            child = Image.memory(
              key: const ValueKey(0),
              snapshot.data!,
              fit: widget.boxFit,
              width: double.infinity,
              height: double.infinity,
            );
          } else {
            child = _buildFallbackImage();
          }

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: child,
          );
        },
      );

  Image _buildFallbackImage() {
    return Image.asset(
      'assets/images/food_fallback.png',
      key: const ValueKey(1),
      fit: widget.boxFit,
      width: double.infinity,
      height: double.infinity,
    );
  }

  SkeletonContainer _buildLoader() {
    return const SkeletonContainer(
      key: ValueKey(2),
      width: double.infinity,
      height: double.infinity,
    );
  }
}
