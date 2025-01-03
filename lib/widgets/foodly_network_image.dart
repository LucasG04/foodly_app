import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/image_cache_manager.dart';
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
  final Dio _dio = Dio();
  late Future<Uint8List?> _imageFuture;

  @override
  void initState() {
    super.initState();
    _imageFuture = _loadImage(widget.imageUrl);
  }

  Future<Uint8List?> _loadImage(String url) async {
    // Attempt to load the image from the cache first
    final cachedImage = ImageCacheManager.get(url);
    if (cachedImage != null) {
      return cachedImage;
    }

    // Determine the actual image URL based on the type of URL
    String imageUrl = url;
    if (BasicUtils.isStorageMealImage(url)) {
      final storageUrl = await StorageService.getMealImageUrl(url);
      if (storageUrl != null) {
        imageUrl = storageUrl;
      } else {
        throw Exception('Storage URL could not be retrieved for $url');
      }
    }

    try {
      final response = await _dio.get(imageUrl,
          options: Options(responseType: ResponseType.bytes));
      if (response.statusCode == 200 && response.data != null) {
        ImageCacheManager.put(url, response.data);
        return response.data;
      } else {
        throw Exception('Failed to load image: ${response.statusCode}');
      }
    } catch (e) {
      // Handle network errors gracefully
      throw Exception('Error loading image from $imageUrl: $e');
    }
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
              snapshot.data!,
              fit: widget.boxFit,
              width: double.infinity,
              height: double.infinity,
            );
          } else {
            child = _buildFallbackImage();
          }

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: child,
          );
        },
      );

  Image _buildFallbackImage() {
    return Image.asset(
      'assets/images/food_fallback.png',
      fit: widget.boxFit,
      width: double.infinity,
      height: double.infinity,
    );
  }

  SkeletonContainer _buildLoader() {
    return const SkeletonContainer(
      width: double.infinity,
      height: double.infinity,
    );
  }
}
