import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../constants.dart';
import '../../services/link_metadata_service.dart';
import '../../services/lunix_api_service.dart';
import '../main_text_field.dart';
import '../skeleton_container.dart';

class ImageLinkPicker extends StatefulWidget {
  final Function(String) onPick;
  final Function() onClose;

  const ImageLinkPicker({
    required this.onPick,
    required this.onClose,
    Key? key,
  }) : super(key: key);

  @override
  State<ImageLinkPicker> createState() => _ImageLinkPickerState();
}

class _ImageLinkPickerState extends State<ImageLinkPicker> {
  final TextEditingController _inputController = TextEditingController();
  final bool _showLinkError = false;
  final Key _animationLimiterKey = UniqueKey();

  int _imagePage = 0;
  List<String> _images = [];

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
                        onSubmit: () => _search(),
                        placeholder: 'http://food.com/images/23342',
                      ),
                    ),
                    IconButton(
                      onPressed: () => _search,
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
                        color: Theme.of(context).errorColor,
                      ),
                      const SizedBox(height: kPadding / 2),
                      Expanded(
                        child: const Text(
                          'image_link_picker_input_error',
                        ).tr(),
                      ),
                    ],
                  ),
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
                    child: TextButton.icon(
                      onPressed: _loadMoreImages,
                      icon: const Icon(EvaIcons.refreshOutline),
                      label: const Text('image_link_picker_load_more').tr(),
                    ),
                  ),
                ],
                const SizedBox(height: kPadding),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImage(String url) {
    url = url.replaceFirst('http://', 'https://');
    return _buildImageContainer(
      child: CachedNetworkImage(
        imageUrl: url,
        // fit: BoxFit.cover,
        imageBuilder: (context, image) => Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(kRadius)),
            image: DecorationImage(image: image, fit: BoxFit.cover),
          ),
        ),
        placeholder: (_, __) => const SkeletonContainer(
          width: double.infinity,
          height: double.infinity,
        ),
        errorWidget: (_, __, dynamic ___) => const SizedBox(),
      ),
    );
  }

  Widget _buildImageContainer({required Widget child}) {
    return Container(
      margin: const EdgeInsets.all(5.0),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(4.0)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4.0,
            offset: Offset(0.0, 4.0),
          ),
        ],
      ),
      child: child,
    );
  }

  Future<void> _search() async {
    final String search = _inputController.text.trim();
    final imageFromUrl = await _getImageFromUrl(search);

    if (imageFromUrl != null) {
      widget.onPick(search);
      return;
    }

    final response = await LunixApiService.searchImages(
      search,
      _imagePage,
      context.locale.languageCode,
    );

    setState(() {
      _images = response.images.map((e) => e.url).toList();
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
    final String search = _inputController.text.trim();
    _imagePage++;

    final response = await LunixApiService.searchImages(
      search,
      _imagePage,
      context.locale.languageCode,
    );

    setState(() {
      _images.addAll(response.images.map((e) => e.url));
    });
  }
}
