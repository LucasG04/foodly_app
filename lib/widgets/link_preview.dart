import 'package:auto_size_text/auto_size_text.dart';
import 'package:clipboard/clipboard.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import '../models/link_metadata.dart';
import '../services/link_metadata_service.dart';
import '../utils/basic_utils.dart';
import '../utils/main_snackbar.dart';
import '../utils/of_context_mixin.dart';
import '../utils/widget_utils.dart';
import 'foodly_network_image.dart';
import 'options_modal/options_modal.dart';
import 'options_modal/options_modal_option.dart';
import 'skeleton_container.dart';

class LinkPreview extends StatefulWidget {
  final String link;
  final bool isSmall;

  const LinkPreview(
    this.link, {
    this.isSmall = true,
    super.key,
  });

  @override
  State<LinkPreview> createState() => _LinkPreviewState();
}

class _LinkPreviewState extends State<LinkPreview> with OfContextMixin {
  Future<LinkMetadata?>? _metadataFuture;

  @override
  void initState() {
    super.initState();
    _initFuture(widget.link);
  }

  @override
  void didUpdateWidget(LinkPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.link != widget.link) {
      _initFuture(widget.link);
    }
  }

  void _initFuture(String link) {
    if (BasicUtils.isValidUri(link) && !LinkMetadataService.isCached(link)) {
      _metadataFuture = LinkMetadataService.getFromApi(link);
    } else {
      _metadataFuture = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!BasicUtils.isValidUri(widget.link)) {
      return const SizedBox();
    }
    LinkMetadata? metadata;
    if (LinkMetadataService.isCached(widget.link)) {
      metadata = LinkMetadataService.getFromCache(widget.link);
    }
    return metadata != null
        ? widget.isSmall
            ? _buildSmallCard(metadata)
            : _buildLargeCard(metadata)
        : FutureBuilder<LinkMetadata?>(
            future: _metadataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return widget.isSmall
                    ? _buildSmallSkeletonCard(context)
                    : _buildLargeSkeletonCard(context);
              } else if (!snapshot.hasData) {
                return const SizedBox();
              }

              return widget.isSmall
                  ? _buildSmallCard(snapshot.data!)
                  : _buildLargeCard(snapshot.data!);
            },
          );
  }

  Widget _buildLargeCard(LinkMetadata metadata) {
    return GestureDetector(
      onTap: metadata.url != null
          ? () => launchUrl(Uri.parse(metadata.url!))
          : () {},
      onLongPress: metadata.url != null
          ? () => _openLinkOptions(context, metadata.url!)
          : () {},
      child: Card(
        child: Column(
          children: [
            if (metadata.image != null)
              SizedBox(
                height: _getLargeImageHeight(),
                width: double.infinity,
                child: FoodlyNetworkImage(metadata.image!),
              ),
            Padding(
              padding: const EdgeInsets.all(kPadding / 2),
              child: Column(
                children: [
                  Text(
                    metadata.title!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: kPadding / 4),
                  Text(
                    metadata.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallCard(LinkMetadata metadata) {
    final height = _getSmallCardHeight();
    return GestureDetector(
      onTap: metadata.url != null
          ? () => launchUrl(Uri.parse(metadata.url!))
          : () {},
      onLongPress: metadata.url != null
          ? () => _openLinkOptions(context, metadata.url!)
          : () {},
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          boxShadow: const [kSmallShadow],
          borderRadius: BorderRadius.circular(kRadius),
          color: Colors.white,
        ),
        child: Row(
          children: [
            SizedBox(
              height: height,
              width: height,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(kRadius),
                child: metadata.image != null && metadata.image!.isNotEmpty
                    ? FoodlyNetworkImage(metadata.image!)
                    : Image.asset(
                        'assets/images/food_fallback.png',
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (metadata.title != null && metadata.title!.isNotEmpty)
                      AutoSizeText(
                        metadata.title!,
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (metadata.description != null &&
                        metadata.description!.isNotEmpty)
                      AutoSizeText(
                        metadata.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLargeSkeletonCard(BuildContext context) {
    return Card(
      child: Column(
        children: [
          SkeletonContainer(
            width: mediaSize.width,
            height: theme.textTheme.bodyLarge!.fontSize,
          ),
          Padding(
            padding: const EdgeInsets.all(kPadding / 2),
            child: Column(
              children: [
                SkeletonContainer(
                  width: mediaSize.width * 0.5,
                  height: _getLargeImageHeight(),
                ),
                const SizedBox(height: kPadding / 4),
                SkeletonContainer(
                  width: mediaSize.width,
                  height: theme.textTheme.bodyLarge!.fontSize! * 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallSkeletonCard(BuildContext context) {
    final height = _getSmallCardHeight();
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        boxShadow: const [kSmallShadow],
        borderRadius: BorderRadius.circular(kRadius),
        color: Colors.white,
      ),
      child: Row(
        children: [
          SkeletonContainer(
            height: height,
            width: height,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonContainer(
                    width: mediaSize.width * 0.4,
                    height: Theme.of(context).textTheme.bodyLarge!.fontSize,
                  ),
                  SkeletonContainer(
                    width: mediaSize.width * 0.6,
                    height:
                        Theme.of(context).textTheme.bodyLarge!.fontSize! * 2,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getLargeImageHeight() => mediaSize.height * 0.2;

  double _getSmallCardHeight() => 75.0;

  void _openLinkOptions(BuildContext context, String url) {
    WidgetUtils.showFoodlyBottomSheet<void>(
      context: context,
      builder: (_) => OptionsSheet(options: [
        OptionsSheetOptions(
          title: 'link_preview_options_open_link'.tr(),
          icon: EvaIcons.externalLinkOutline,
          onTap: () =>
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        ),
        OptionsSheetOptions(
          title: 'link_preview_options_copy_link'.tr(),
          icon: EvaIcons.copyOutline,
          onTap: () async {
            await FlutterClipboard.copy(url);
            if (!context.mounted) {
              return;
            }
            MainSnackbar(
              message: 'link_preview_options_copy_link_success'.tr(),
              duration: 3,
              isDismissible: true,
              isCountdown: true,
            ).show(context);
          },
        ),
      ]),
    );
  }
}
