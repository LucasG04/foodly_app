import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:logging/logging.dart' as app_logger;

import '../../constants.dart';
import '../../providers/state_providers.dart';
import '../../services/link_metadata_service.dart';
import '../../services/lunix_api_service.dart';
import '../../utils/basic_utils.dart';
import '../main_text_field.dart';
import '../skeleton_container.dart';
import '../small_circular_progress_indicator.dart';
import '../user_information.dart';

class WebImagePicker extends ConsumerStatefulWidget {
  final Function(String) onPick;
  final Function() onClose;

  const WebImagePicker({
    required this.onPick,
    required this.onClose,
    Key? key,
  }) : super(key: key);

  @override
  _WebImagePickerState createState() => _WebImagePickerState();
}

class _WebImagePickerState extends ConsumerState<WebImagePicker> {
  final _log = app_logger.Logger('LogRecordService');

  final TextEditingController _inputController = TextEditingController();
  final bool _showLinkError = false;
  final Key _animationLimiterKey = UniqueKey();

  int _imagePage = 0;
  List<String> _images = [];
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
                'image_picker_dialog_web'.tr().toUpperCase(),
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
                        placeholder: 'image_link_picker_input_placeholder'.tr(),
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
                if (_showLinkError)
                  Row(
                    children: [
                      Icon(
                        EvaIcons.alertCircleOutline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: kPadding / 2),
                      Expanded(
                        child: const Text(
                          'image_link_picker_input_error',
                        ).tr(),
                      ),
                    ],
                  ),
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
      title: 'image_link_picker_empty_title'.tr(),
      message: 'image_link_picker_empty_message'.tr(),
    );
  }

  Widget _buildPlaceholderContent() {
    return UserInformation(
      assetPath: 'assets/images/undraw_searching.png',
      title: 'image_link_picker_placeholder_title'.tr(),
      message: 'image_link_picker_placeholder_message'.tr(),
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
                (int index, String url) => MapEntry(
                  index,
                  AnimationConfiguration.staggeredGrid(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    columnCount: 3,
                    child: ScaleAnimation(
                      child: FadeInAnimation(
                        child: _buildImage(url),
                      ),
                    ),
                  ),
                ),
              )
              .values
              .toList(),
        ),
      ),
      if (_images.isNotEmpty) ...[
        Center(
          child: _isLoadingMore && _images.isNotEmpty
              ? const SmallCircularProgressIndicator()
              : TextButton.icon(
                  onPressed: _loadMoreImages,
                  icon: const Icon(EvaIcons.refreshOutline),
                  label: const Text('image_link_picker_load_more').tr(),
                ),
        ),
      ],
    ];
  }

  Widget _buildImage(String url) {
    url = url.replaceFirst('http://', 'https://');
    return _buildImageContainer(
      child: InkWell(
        onTap: () => _selectImage(url),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(kRadius),
          child: ExtendedImage.network(
            url,
            fit: BoxFit.cover,
            loadStateChanged: (state) =>
                state.extendedImageLoadState == LoadState.failed
                    ? _buildErrorWidget()
                    : state.extendedImageLoadState == LoadState.loading
                        ? const SkeletonContainer(
                            width: double.infinity,
                            height: double.infinity,
                          )
                        : state.completedWidget,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Image.asset('assets/images/food_fallback.png');
  }

  Widget _buildImageContainer({required Widget child}) {
    return Container(
      margin: const EdgeInsets.all(5.0),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(4.0)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
    if (_images.isNotEmpty || _noResults) {
      setState(() {
        _images = [];
        _noResults = false;
      });
    }
  }

  Future<void> _search() async {
    setState(() {
      _isLoading = true;
      _noResults = false;
      _images = [];
    });
    final String search = _inputController.text.trim();
    String? imageFromUrl;
    final language = BasicUtils.getActiveLanguage(context);

    try {
      imageFromUrl = await _getImageFromUrl(search);
    } catch (e) {
      _log.severe('ERR: _getImageFromUrl with $search');
    }

    if (imageFromUrl != null) {
      widget.onPick(imageFromUrl);
      return;
    }

    try {
      final response = await LunixApiService.searchImages(
        search,
        _imagePage,
        language,
      );

      if (response == null) {
        throw Exception('API Response is null');
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _images = response.images.map((e) => e.url).toList();
        _noResults = _images.isEmpty;
      });
    } catch (e) {
      _log.severe('ERR: searchImages with $search', e);
      if (!mounted) {
        return;
      }
      setState(() {
        _noResults = true;
      });
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<String?> _getImageFromUrl(String url) async {
    final bool isUrl =
        Uri.tryParse(url) != null && Uri.tryParse(url)!.isAbsolute;
    if (!isUrl) {
      return null;
    }

    final urlMetadata = await LinkMetadataService.getFromApi(url);

    return urlMetadata != null &&
            urlMetadata.image != null &&
            urlMetadata.image!.isNotEmpty
        ? urlMetadata.image
        : null;
  }

  Future<void> _loadMoreImages() async {
    setState(() {
      _isLoadingMore = true;
    });

    final String search = _inputController.text.trim();
    _imagePage++;

    final response = await LunixApiService.searchImages(
      search,
      _imagePage,
      BasicUtils.getActiveLanguage(context),
    );

    if (!mounted) {
      return;
    }

    if (response == null) {
      setState(() {
        _isLoadingMore = false;
      });
      return;
    }

    setState(() {
      _images.addAll(response.images.map((e) => e.url));
      _isLoadingMore = false;
    });
  }

  void _selectImage(String url) {
    widget.onPick(url);
  }
}
