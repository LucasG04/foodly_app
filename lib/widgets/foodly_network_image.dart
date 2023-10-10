import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

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
  static final _log = Logger('FoodlyNetworkImage');
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
    try {
      final isStorageImage = BasicUtils.isStorageMealImage(widget.imageUrl);
      if (isStorageImage) {
        StorageService.getMealImageUrl(widget.imageUrl).then((url) {
          if (!mounted || url == null) {
            return;
          }
          _storageUrl = url;
          ref.read(_$isLoading.notifier).state = false;
        });
      } else {
        _imageIsAvailable(widget.imageUrl).then((available) {
          if (!mounted) {
            return;
          }
          if (available) {
            ref.read(_$isLoading.notifier).state = false;
          } else {
            ref.read(_$isLoading.notifier).state = false;
            ref.read(_$hasError.notifier).state = true;
          }
        });
      }
    } catch (e) {
      _log.finer('Init of FoodlyNetworkImage failed.', e);
      BasicUtils.afterBuild(() {
        if (!mounted) {
          return;
        }
        ref.read(_$hasError.notifier).state = true;
        ref.read(_$isLoading.notifier).state = false;
      });
    }
    super.initState();
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

  ExtendedImage _buildCachedNetworkImage(String url) {
    url = url.replaceFirst('http://', 'https://');
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

  Future<bool> _imageIsAvailable(String url) async {
    try {
      final response = await _dio.head<dynamic>(url);
      return [200, 201, 202, 203].contains(response.statusCode);
    } catch (error) {
      return false;
    }
  }
}
