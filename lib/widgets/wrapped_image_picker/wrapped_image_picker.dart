import 'package:dotted_border/dotted_border.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../screens/meal/border_icon.dart';
import '../../services/storage_service.dart';
import '../../utils/basic_utils.dart';
import '../../utils/widget_utils.dart';
import '../foodly_network_image.dart';
import 'select_picker_dialog.dart';

class WrappedImagePicker extends StatefulWidget {
  final Function(String) onPick;
  final Function()? onRemove;
  final double edgeLength;

  /// Used to display a already selected image
  final String? imageUrl;

  const WrappedImagePicker({
    Key? key,
    required this.onPick,
    this.onRemove,
    this.edgeLength = 200.0,
    this.imageUrl,
  }) : super(key: key);

  @override
  State<WrappedImagePicker> createState() => _WrappedImagePickerState();
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
    return DottedBorder(
      dashPattern: const [10, 8],
      radius: const Radius.circular(kRadius),
      child: SizedBox(
        width: widget.edgeLength,
        height: widget.edgeLength,
        child:
            _imageUrl == null || _imageUrl!.isEmpty || widget.onRemove == null
                ? _buildPicker(context)
                : Stack(
                    children: [
                      Positioned.fill(
                        child: _buildPicker(context),
                      ),
                      Align(
                        alignment: Alignment.topRight,
                        child: BorderIcon(
                          height: 40,
                          width: 40,
                          child: InkWell(
                            onTap: _removeImage,
                            child: const Icon(
                              EvaIcons.trash2Outline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  InkWell _buildPicker(BuildContext context) {
    return InkWell(
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
    );
  }

  void _selectImage() async {
    final String? result = await WidgetUtils.showFoodlyBottomSheet<String?>(
      context: context,
      builder: (_) => const SelectPickerDialog(),
    );

    if (result != null) {
      if (BasicUtils.isStorageMealImage(result)) {
        final storageUrl = await StorageService.getMealImageUrl(result);
        setState(() {
          _imageUrl = storageUrl;
        });
        print('3kil4 storage up $_imageUrl');
        widget.onPick(result);
      } else if (Uri.tryParse(result)!.isAbsolute) {
        setState(() {
          _imageUrl = result;
        });
        widget.onPick(result);
      }
    }
  }

  void _removeImage() async {
    setState(() {
      _imageUrl = null;
    });
    if (widget.onRemove != null) {
      widget.onRemove!();
    }
  }
}
