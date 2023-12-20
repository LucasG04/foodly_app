import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import '../utils/basic_utils.dart';
import 'skeleton_container.dart';

class FoodlyNetworkImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit boxFit;

  const FoodlyNetworkImage(
    this.imageUrl, {
    this.boxFit = BoxFit.cover,
    Key? key,
  }) : super(key: key);

  @override
  State<FoodlyNetworkImage> createState() => _FoodlyNetworkImageState();
}

class _FoodlyNetworkImageState extends State<FoodlyNetworkImage> {
  @override
  Widget build(BuildContext context) {
    if (BasicUtils.isStorageMealImage(widget.imageUrl)) {
      return FutureBuilder(
        future: StorageService.getMealImageUrl(widget.imageUrl),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoader();
          } else if (snapshot.hasData) {
            return _buildCachedImage(snapshot.data!);
          } else {
            return _buildFallbackImage();
          }
        },
      );
    }
    return _buildCachedImage(widget.imageUrl);
  }

  FastCachedImage _buildCachedImage(String imageUrl) {
    return FastCachedImage(
      url: imageUrl,
      fit: widget.boxFit,
      errorBuilder: (_, __, ___) => _buildFallbackImage(),
      loadingBuilder: (_, __) => _buildLoader(),
      disableErrorLogs: true,
    );
  }

  Image _buildFallbackImage() {
    return Image.asset(
      'assets/images/food_fallback.png',
      fit: widget.boxFit,
    );
  }

  SkeletonContainer _buildLoader() {
    return const SkeletonContainer(
      width: double.infinity,
      height: double.infinity,
    );
  }
}
