import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:foodly/services/storage_service.dart';
import 'package:foodly/utils/basic_utils.dart';
import 'package:foodly/widgets/foodly_network_image.dart';
import 'package:foodly/widgets/wrapped_image_picker/select_picker_dialog.dart';

import '../../constants.dart';

class WrappedImagePicker extends StatefulWidget {
  /// Returns the new image url
  final Function(String) onPick;

  /// Determines the length of the widgets edges
  final double edgeLength;

  /// Used to display a already selected image
  final String imageUrl;

  WrappedImagePicker({
    Key key,
    @required this.onPick,
    this.edgeLength = 200.0,
    this.imageUrl,
  }) : super(key: key);

  @override
  _WrappedImagePickerState createState() => _WrappedImagePickerState();
}

class _WrappedImagePickerState extends State<WrappedImagePicker> {
  String _imageUrl;

  @override
  void initState() {
    _imageUrl = widget.imageUrl != null && widget.imageUrl.isNotEmpty
        ? widget.imageUrl
        : null;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.edgeLength,
      height: widget.edgeLength,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1.0),
        borderRadius: BorderRadius.circular(kRadius),
      ),
      child: InkWell(
        onTap: _selectImage,
        child: _imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(kRadius),
                child: FoodlyNetworkImage(_imageUrl),
              )
            : Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      EvaIcons.plus,
                      color: Theme.of(context).primaryColor,
                      size: 12.0,
                    ),
                    Icon(
                      EvaIcons.image2,
                      color: Theme.of(context).primaryColor,
                    ),
                  ],
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
      } else if (Uri.tryParse(result).isAbsolute) {
        setState(() {
          _imageUrl = result;
        });
        widget.onPick(result);
      }
    }
  }
}
