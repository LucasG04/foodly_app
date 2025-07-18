import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import '../models/link_metadata.dart';
import '../services/link_metadata_service.dart';
import '../utils/basic_utils.dart';
import '../utils/of_context_mixin.dart';
import 'foodly_network_image.dart';
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
            future: LinkMetadataService.getFromApi(widget.link),
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
            width: media.size.width,
            height: theme.textTheme.bodyLarge!.fontSize,
          ),
          Padding(
            padding: const EdgeInsets.all(kPadding / 2),
            child: Column(
              children: [
                SkeletonContainer(
                  width: media.size.width * 0.5,
                  height: _getLargeImageHeight(),
                ),
                const SizedBox(height: kPadding / 4),
                SkeletonContainer(
                  width: media.size.width,
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
                    width: media.size.width * 0.4,
                    height: Theme.of(context).textTheme.bodyLarge!.fontSize,
                  ),
                  SkeletonContainer(
                    width: media.size.width * 0.6,
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

  double _getLargeImageHeight() => media.size.height * 0.2;

  double _getSmallCardHeight() => 75.0;
}
