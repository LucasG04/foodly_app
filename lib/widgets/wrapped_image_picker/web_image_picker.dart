import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:logging/logging.dart' as app_logger;

import '../../constants.dart';
import '../../models/image_credit.dart';
import '../../models/lunix_image.dart';
import '../../providers/state_providers.dart';
import '../../services/lunix_api_service.dart';
import '../../utils/basic_utils.dart';
import '../foodly_network_image.dart';
import '../main_text_field.dart';
import '../skeleton_container.dart';
import '../small_circular_progress_indicator.dart';
import '../user_information.dart';

class WebImagePicker extends ConsumerStatefulWidget {
  final Function(String url, ImageCredit? credit) onPick;
  final Function() onClose;

  const WebImagePicker({
    required this.onPick,
    required this.onClose,
    super.key,
  });

  @override
  _WebImagePickerState createState() => _WebImagePickerState();
}

class _WebImagePickerState extends ConsumerState<WebImagePicker> {
  final _log = app_logger.Logger('LogRecordService');

  final TextEditingController _inputController = TextEditingController();
  final Key _animationLimiterKey = UniqueKey();

  int _imagePage = 0;
  bool _hasMore = false;
  // Bumped by every new search or query edit; async results from an older
  // request are dropped so they can't land under a different query.
  int _requestId = 0;
  List<LunixImage> _images = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _noResults = false;

  @override
  void initState() {
    super.initState();
    BasicUtils.afterBuild(
      () => _initialSearch(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(EvaIcons.arrowBackOutline),
              onPressed: widget.onClose,
            ),
            Expanded(
              child: Text(
                context.tr('image_picker_dialog_web').toUpperCase(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: kPadding / 2),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: MainTextField(
                        controller: _inputController,
                        onSubmit: _search,
                        placeholder:
                            context.tr('image_link_picker_input_placeholder'),
                        onChange: (_) => _clearResults(),
                      ),
                    ),
                    IconButton(
                      onPressed: _search,
                      icon: const Icon(EvaIcons.searchOutline),
                    ),
                  ],
                ),
                const SizedBox(height: kPadding / 2),
                if (_isLoading) _buildLoadingGrid(),
                if (!_isLoading && _images.isNotEmpty) ..._buildContent(),
                if (!_isLoading && _images.isEmpty && _noResults)
                  _buildEmptyContent(),
                if (!_isLoading && _images.isEmpty && !_noResults)
                  _buildPlaceholderContent(),
                const SizedBox(height: kPadding),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingGrid() {
    return AnimationLimiter(
      key: _animationLimiterKey,
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 3,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(
          15,
          (int index) => AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 375),
            columnCount: 3,
            child: ScaleAnimation(
              child: FadeInAnimation(
                child: _buildImageContainer(
                  child: const SkeletonContainer(
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
            ),
          ),
        ).toList(),
      ),
    );
  }

  Widget _buildEmptyContent() {
    return UserInformation(
      assetPath: 'assets/images/undraw_empty.png',
      title: context.tr('image_link_picker_empty_title'),
      message: context.tr('image_link_picker_empty_message'),
    );
  }

  Widget _buildPlaceholderContent() {
    return UserInformation(
      assetPath: 'assets/images/undraw_searching.png',
      title: context.tr('image_link_picker_placeholder_title'),
      message: context.tr('image_link_picker_placeholder_message'),
    );
  }

  List<Widget> _buildContent() {
    return [
      AnimationLimiter(
        key: _animationLimiterKey,
        child: GridView.count(
          shrinkWrap: true,
          crossAxisCount: 3,
          physics: const NeverScrollableScrollPhysics(),
          children: _images
              .asMap()
              .map(
                (int index, LunixImage image) => MapEntry(
                  index,
                  AnimationConfiguration.staggeredGrid(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    columnCount: 3,
                    child: ScaleAnimation(
                      child: FadeInAnimation(
                        child: _buildImage(image),
                      ),
                    ),
                  ),
                ),
              )
              .values
              .toList(),
        ),
      ),
      if (_images.isNotEmpty && _hasMore) ...[
        Center(
          child: _isLoadingMore && _images.isNotEmpty
              ? const SmallCircularProgressIndicator()
              : TextButton.icon(
                  onPressed: _loadMoreImages,
                  icon: const Icon(EvaIcons.refreshOutline),
                  label: Text(context.tr('image_link_picker_load_more')),
                ),
        ),
      ],
    ];
  }

  Widget _buildImage(LunixImage image) {
    final url = image.url.replaceFirst('http://', 'https://');
    return _buildImageContainer(
      child: InkWell(
        onTap: () => widget.onPick(url, image.credit),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(kRadius),
          child: FoodlyNetworkImage(url),
        ),
      ),
    );
  }

  Widget _buildImageContainer({required Widget child}) {
    return Container(
      margin: const EdgeInsets.all(5.0),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(4.0)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4.0,
            offset: const Offset(0.0, 4.0),
          ),
        ],
      ),
      child: child,
    );
  }

  void _initialSearch() {
    if (!mounted) {
      return;
    }

    final initialSearch = ref.read(initSearchWebImagePickerProvider);
    if (initialSearch.isEmpty) {
      return;
    }

    _inputController.text = initialSearch;
    _search();
  }

  void _clearResults() {
    if (_images.isEmpty && !_noResults && !_isLoading && !_isLoadingMore) {
      return;
    }
    _requestId++;
    setState(() {
      _images = [];
      _noResults = false;
      _isLoading = false;
      _isLoadingMore = false;
      _imagePage = 0;
      _hasMore = false;
    });
  }

  Future<void> _search() async {
    final requestId = ++_requestId;
    final String search = _inputController.text.trim();
    final language = BasicUtils.getActiveLanguage(context);

    final cache = ref.read(webImagePickerCacheProvider);
    final isCached =
        cache != null && cache.query == search && cache.language == language;
    setState(() {
      _isLoading = !isCached;
      _isLoadingMore = false;
      _noResults = false;
      _images = isCached ? List.of(cache.images) : [];
      _imagePage = isCached ? cache.page : 0;
      _hasMore = isCached && cache.hasMore;
    });
    if (isCached) {
      return;
    }

    LunixImageResponse? response;
    try {
      response = await LunixApiService.searchImages(
        search,
        _imagePage,
        language,
      );
    } catch (e) {
      _log.severe('ERR: searchImages with $search', e);
    }
    if (!mounted || requestId != _requestId) {
      return;
    }

    setState(() {
      _images = response?.images ?? [];
      _hasMore = response?.hasMore ?? false;
      _noResults = _images.isEmpty;
      _isLoading = false;
    });
    if (_images.isNotEmpty) {
      ref.read(webImagePickerCacheProvider.notifier).state = (
        query: search,
        language: language,
        page: _imagePage,
        hasMore: _hasMore,
        images: List.of(_images),
      );
    }
  }

  Future<void> _loadMoreImages() async {
    final requestId = _requestId;
    setState(() {
      _isLoadingMore = true;
    });

    final String search = _inputController.text.trim();
    final language = BasicUtils.getActiveLanguage(context);
    // Read before the await: `ref` is unusable once the picker is closed.
    final cache = ref.read(webImagePickerCacheProvider.notifier);
    final loadedImages = List.of(_images);
    // Only advance on success so a failed request can be retried.
    final nextPage = _imagePage + 1;

    LunixImageResponse? response;
    try {
      response = await LunixApiService.searchImages(
        search,
        nextPage,
        language,
      );
    } catch (e) {
      _log.severe('ERR: loadMoreImages with $search', e);
    }

    // Cache even if the picker closed or the query changed meanwhile, so a
    // paid page isn't fetched (and billed) again.
    if (response != null) {
      cache.state = (
        query: search,
        language: language,
        page: nextPage,
        hasMore: response.hasMore,
        images: [...loadedImages, ...response.images],
      );
    }
    if (!mounted || requestId != _requestId) {
      return;
    }

    setState(() {
      if (response != null) {
        _images.addAll(response.images);
        _imagePage = nextPage;
        _hasMore = response.hasMore;
      }
      _isLoadingMore = false;
    });
  }
}
