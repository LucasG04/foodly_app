import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import '../models/link_metadata.dart';
import '../services/link_metadata_service.dart';
import '../utils/basic_utils.dart';
import 'foodly_network_image.dart';
import 'skeleton_container.dart';

class LinkPreview extends StatefulWidget {
  final String link;
  final bool isSmall;

  const LinkPreview(
    this.link, {
    this.isSmall = true,
    Key? key,
  }) : super(key: key);

  @override
  State<LinkPreview> createState() => _LinkPreviewState();
}

class _LinkPreviewState extends State<LinkPreview> {
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
            ? _buildSmallCard(metadata, context)
            : _buildLargeCard(metadata, context)
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
                  ? _buildSmallCard(snapshot.data!, context)
                  : _buildLargeCard(snapshot.data!, context);
            },
          );
  }

  Widget _buildLargeCard(LinkMetadata metadata, BuildContext context) {
    return GestureDetector(
      onTap: metadata.url != null
          ? () => launchUrl(Uri.parse(metadata.url!))
          : () {},
      child: Card(
        child: Column(
          children: [
            if (metadata.image != null)
              SizedBox(
                height: _getLargeImageHeight(context),
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

  Widget _buildSmallCard(LinkMetadata metadata, BuildContext context) {
    final height = _getSmallCardHeight(context);
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
    final size = MediaQuery.of(context).size;
    return Card(
      child: Column(
        children: [
          SkeletonContainer(
            width: size.width,
            height: Theme.of(context).textTheme.bodyLarge!.fontSize,
          ),
          Padding(
            padding: const EdgeInsets.all(kPadding / 2),
            child: Column(
              children: [
                SkeletonContainer(
                  width: size.width * 0.5,
                  height: _getLargeImageHeight(context),
                ),
                const SizedBox(height: kPadding / 4),
                SkeletonContainer(
                  width: size.width,
                  height: Theme.of(context).textTheme.bodyLarge!.fontSize! * 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallSkeletonCard(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = _getSmallCardHeight(context);
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
                    width: size.width * 0.4,
                    height: Theme.of(context).textTheme.bodyLarge!.fontSize,
                  ),
                  SkeletonContainer(
                    width: size.width * 0.6,
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

  double _getLargeImageHeight(BuildContext context) =>
      MediaQuery.of(context).size.height * 0.2;

  double _getSmallCardHeight(BuildContext context) => 75.0;
}
