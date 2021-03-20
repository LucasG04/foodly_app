import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:foodly/services/storage_service.dart';
import 'package:foodly/utils/basic_utils.dart';
import 'package:foodly/widgets/wrapped_image_picker/select_picker_dialog.dart';

import '../../constants.dart';
import '../small_circular_progress_indicator.dart';

class WrappedImagePicker extends StatefulWidget {
  /// Returns the new image url
  final Function(String) onPick;

  /// Determines the length of the widgets edges
  final double edgeLength;

  /// Used to display a already selected image
  final String imageUrl;

  WrappedImagePicker({
    @required this.onPick,
    this.edgeLength = 250.0,
    this.imageUrl,
  });

  @override
  _WrappedImagePickerState createState() => _WrappedImagePickerState();
}

class _WrappedImagePickerState extends State<WrappedImagePicker> {
  String _imageUrl;

  @override
  void initState() {
    _imageUrl = widget.imageUrl;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.edgeLength,
      height: widget.edgeLength,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).primaryColor, width: 1.0),
        borderRadius: BorderRadius.circular(kRadius),
      ),
      child: InkWell(
        onTap: _selectImage,
        child: _imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(kRadius),
                child: CachedNetworkImage(
                  imageUrl: _imageUrl,
                  progressIndicatorBuilder: (context, url, progress) => Center(
                    child: SmallCircularProgressIndicator(),
                  ),
                ),
              )
            : Center(
                child: Icon(
                  EvaIcons.image2,
                  color: Theme.of(context).primaryColor,
                ),
              ),
      ),
    );
  }

  void _selectImage() async {
    final result = await showDialog(
      context: context,
      builder: (_) => Dialog(child: SelectPickerDialog()),
    );

    if (result != null) {
      if (BasicUtils.isStorageImage(result)) {
        final storageUrl = await StorageService.getMealImageUrl(result);
        setState(() {
          _imageUrl = storageUrl;
        });
        widget.onPick(result);
      } else if (Uri.tryParse(result) != null) {
        setState(() {
          _imageUrl = result;
        });
        widget.onPick(result);
      }
    }
  }
}
