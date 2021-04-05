import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import '../utils/basic_utils.dart';
import 'skeleton_container.dart';

class FoodlyNetworkImage extends StatelessWidget {
  final String imageUrl;

  FoodlyNetworkImage(this.imageUrl);

  @override
  Widget build(BuildContext context) {
    return BasicUtils.isStorageMealImage(imageUrl)
        ? FutureBuilder<String>(
            future: StorageService.getMealImageUrl(imageUrl),
            builder: (context, snapshot) {
              return snapshot.data.isNotEmpty
                  ? _buildCachedNetworkImage(snapshot.data)
                  : SkeletonContainer(
                      width: double.infinity,
                      height: double.infinity,
                    );
            },
          )
        : _buildCachedNetworkImage(imageUrl);
  }

  CachedNetworkImage _buildCachedNetworkImage(String url) {
    url = url.replaceFirst('http://', 'https://');
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => SkeletonContainer(
        width: double.infinity,
        height: double.infinity,
      ),
      errorWidget: (_, __, ___) => Image.asset(
        'assets/images/food_fallback.png',
      ),
      // cacheManager: HiveCacheManager(box: ImageCacheService.box)
    );
  }
}
