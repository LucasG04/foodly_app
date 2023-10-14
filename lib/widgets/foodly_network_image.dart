import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/image_cache_service.dart';
import '../services/storage_service.dart';
import '../utils/basic_utils.dart';
import 'skeleton_container.dart';

class FoodlyNetworkImage extends ConsumerStatefulWidget {
  final String imageUrl;
  final BoxFit boxFit;

  const FoodlyNetworkImage(
    this.imageUrl, {
    this.boxFit = BoxFit.cover,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<FoodlyNetworkImage> createState() => _FoodlyNetworkImageState();
}

class _FoodlyNetworkImageState extends ConsumerState<FoodlyNetworkImage> {
  final _dio = Dio()
    ..interceptors.add(
      DioCacheInterceptor(
        options: CacheOptions(store: ImageCacheService.hiveCacheStore),
      ),
    );
  final _$isLoading = AutoDisposeStateProvider<bool>((_) => true);
  final _$hasError = AutoDisposeStateProvider<bool>((_) => false);
  String _storageUrl = '';

  @override
  void initState() {
    super.initState();

    BasicUtils.afterBuild(() async {
      final isStorageImage = BasicUtils.isStorageMealImage(widget.imageUrl);
      if (isStorageImage) {
        await _loadAndSetStorageUrl();
      }
      if (mounted) {
        ref.read(_$isLoading.notifier).state = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        if (ref.watch(_$isLoading)) {
          return child!;
        } else if (ref.watch(_$hasError)) {
          return _buildFallbackImage();
        }
        return _buildCachedNetworkImage(
          BasicUtils.isStorageMealImage(widget.imageUrl)
              ? _storageUrl
              : widget.imageUrl,
        );
      },
      child: _buildLoader(),
    );
  }

  Widget _buildCachedNetworkImage(String url) {
    url = url.replaceFirst('http://', 'https://');

    return FutureBuilder(
      future: _imageIsAvailable(url),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return _buildLoader();
        } else if (snap.hasError) {
          return _buildFallbackImage();
        } else if (snap.data == null || !snap.data!) {
          return _buildFallbackImage();
        }

        return ExtendedImage.network(
          url,
          fit: widget.boxFit,
          loadStateChanged: (state) =>
              state.extendedImageLoadState == LoadState.failed
                  ? _buildFallbackImage()
                  : state.extendedImageLoadState == LoadState.loading
                      ? _buildLoader()
                      : state.completedWidget,
        );
      },
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

  Future<void> _loadAndSetStorageUrl() async {
    final storageUrl = await StorageService.getMealImageUrl(
      widget.imageUrl,
    );
    if (storageUrl != null && storageUrl.isNotEmpty) {
      _storageUrl = storageUrl;
    }
  }

  Future<bool> _imageIsAvailable(String url) async {
    try {
      final response = await _dio.head<dynamic>(url);
      // check if content-type contains image
      if (response.headers.value('content-type')?.contains('image') != true) {
        return false;
      }
      return [200, 201, 202, 203].contains(response.statusCode);
    } catch (error) {
      return false;
    }
  }
}
