import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import '../../constants.dart';
import '../../services/storage_service.dart';
import '../../utils/basic_utils.dart';
import '../foodly_network_image.dart';
import 'select_picker_dialog.dart';

class WrappedImagePicker extends StatefulWidget {
  /// Returns the new image url
  final Function(String)? onPick;

  /// Determines the length of the widgets edges
  final double edgeLength;

  /// Used to display a already selected image
  final String? imageUrl;

  const WrappedImagePicker({
    Key? key,
    required this.onPick,
    this.edgeLength = 200.0,
    this.imageUrl,
  }) : super(key: key);

  @override
  _WrappedImagePickerState createState() => _WrappedImagePickerState();
}

class _WrappedImagePickerState extends State<WrappedImagePicker> {
  String? _imageUrl;

  @override
  void initState() {
    _imageUrl = widget.imageUrl != null && widget.imageUrl!.isNotEmpty
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
        border: Border.all(),
        borderRadius: BorderRadius.circular(kRadius),
      ),
      child: InkWell(
        onTap: _selectImage,
        child: _imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(kRadius),
                child: FoodlyNetworkImage(_imageUrl!),
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
    final String? result = await showBarModalBottomSheet<String?>(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(10.0),
        ),
      ),
      context: context,
      builder: (_) => const SelectPickerDialog(),
    );

    if (result != null) {
      if (BasicUtils.isStorageMealImage(result)) {
        final storageUrl = await StorageService.getMealImageUrl(result);
        setState(() {
          _imageUrl = storageUrl;
        });
        widget.onPick!(result);
      } else if (Uri.tryParse(result)!.isAbsolute) {
        setState(() {
          _imageUrl = result;
        });
        widget.onPick!(result);
      }
    }
  }
}
