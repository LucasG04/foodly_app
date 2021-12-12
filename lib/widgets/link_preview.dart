import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/link_metadata.dart';
import '../services/link_metadata_service.dart';
import '../utils/basic_utils.dart';
import 'foodly_network_image.dart';
import 'skeleton_container.dart';

class LinkPreview extends StatelessWidget {
  final String link;
  const LinkPreview(this.link, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!BasicUtils.isValidUri(link)) {
      return SizedBox();
    }
    LinkMetadata metadata;
    if (LinkMetadataService.isCached(link)) {
      metadata = LinkMetadataService.getFromCache(link);
    }
    return metadata != null
        ? _buildCard(metadata)
        : FutureBuilder(
            future: LinkMetadataService.getFromApi(link),
            builder: (context, snapshot) {
              print(snapshot.connectionState);
              print(snapshot.hasData);
              print(snapshot.data);
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildSkeletonCard(context);
              } else if (!snapshot.hasData) {
                return SizedBox();
              }

              return _buildCard(snapshot.data);
            },
          );
  }

  Widget _buildCard(LinkMetadata metadata) {
    return Card(
      child: Column(
        children: [
          FoodlyNetworkImage(metadata.image),
          Padding(
            padding: const EdgeInsets.all(kPadding / 2),
            child: Column(
              children: [
                Text(
                  metadata.title,
                  style: TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: kPadding / 4),
                Text(
                  metadata.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Card(
      child: Column(
        children: [
          SkeletonContainer(
            width: size.width,
            height: Theme.of(context).textTheme.bodyText1.fontSize,
          ),
          Padding(
            padding: const EdgeInsets.all(kPadding / 2),
            child: Column(
              children: [
                SkeletonContainer(
                  width: size.width * 0.5,
                  height: Theme.of(context).textTheme.bodyText1.fontSize,
                ),
                SizedBox(height: kPadding / 4),
                SkeletonContainer(
                  width: size.width,
                  height: Theme.of(context).textTheme.bodyText1.fontSize * 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
