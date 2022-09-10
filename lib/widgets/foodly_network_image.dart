import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter/material.dart';

import '../services/image_cache_service.dart';
import '../services/storage_service.dart';
import '../utils/basic_utils.dart';
import 'skeleton_container.dart';

class FoodlyNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit boxFit;

  FoodlyNetworkImage(
    this.imageUrl, {
    this.boxFit = BoxFit.cover,
    Key? key,
  }) : super(key: key);

  final _dio = Dio()
    ..interceptors.add(
      DioCacheInterceptor(
        options: CacheOptions(store: ImageCacheService.hiveCacheStore),
      ),
    );

  @override
  Widget build(BuildContext context) {
    return BasicUtils.isStorageMealImage(imageUrl)
        ? FutureBuilder<String>(
            future: StorageService.getMealImageUrl(imageUrl),
            builder: (context, snapshot) {
              return snapshot.data != null && snapshot.data!.isNotEmpty
                  ? _buildCachedNetworkImage(snapshot.data!)
                  : _buildLoader();
            },
          )
        : _buildImageChecker(
            child: _buildCachedNetworkImage(imageUrl),
          );
  }

  CachedNetworkImage _buildCachedNetworkImage(String url) {
    url = url.replaceFirst('http://', 'https://');
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => _buildLoader(),
      errorWidget: (_, __, dynamic ___) => _buildFallbackImage(),
    );
  }

  FutureBuilder _buildImageChecker({required CachedNetworkImage child}) {
    return FutureBuilder<bool>(
      future: _imageIsAvailable(imageUrl),
      builder: (context, snapshot) =>
          snapshot.connectionState == ConnectionState.waiting
              ? _buildLoader()
              : snapshot.hasData && snapshot.data!
                  ? child
                  : _buildFallbackImage(),
    );
  }

  Image _buildFallbackImage() {
    return Image.asset(
      'assets/images/food_fallback.png',
    );
  }

  SkeletonContainer _buildLoader() {
    return const SkeletonContainer(
      width: double.infinity,
      height: double.infinity,
    );
  }

  Future<bool> _imageIsAvailable(String url) async {
    try {
      final response = await _dio.head<dynamic>(url);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
