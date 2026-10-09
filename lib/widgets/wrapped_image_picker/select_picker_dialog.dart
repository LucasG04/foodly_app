import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';

import '../../constants.dart';
import '../../models/image_credit.dart';
import '../../services/storage_service.dart';
import '../../utils/image_access.dart';
import '../../utils/main_snackbar.dart';
import '../small_circular_progress_indicator.dart';
import 'web_image_picker.dart';

/// Result of [SelectPickerDialog]: a storage file name or an absolute URL,
/// plus attribution when the image came from a stock photo search.
typedef PickedImage = ({String image, ImageCredit? credit});

class SelectPickerDialog extends StatefulWidget {
  const SelectPickerDialog({super.key});

  @override
  State<SelectPickerDialog> createState() => _SelectPickerDialogState();
}

class _SelectPickerDialogState extends State<SelectPickerDialog> {
  final Logger _log = Logger('SelectPickerDialog');
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = false;
  bool _showWebPicker = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(kPadding),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _isLoading
            ? SizedBox(
                height: MediaQuery.sizeOf(context).width * 0.35,
                width: MediaQuery.sizeOf(context).width * 0.7,
                child: const Center(child: SmallCircularProgressIndicator()),
              )
            : !_showWebPicker
                ? Wrap(
                    alignment: WrapAlignment.center,
                    spacing: kPadding / 2,
                    children: [
                      _buildPickerTypeTile(
                        EvaIcons.globe2Outline,
                        context.tr('image_picker_dialog_web'),
                        () => setState(() => _showWebPicker = true),
                      ),
                      _buildPickerTypeTile(
                        EvaIcons.cameraOutline,
                        context.tr('image_picker_dialog_camera'),
                        () => _uploadLocalImage(ImageSource.camera),
                      ),
                      _buildPickerTypeTile(
                        EvaIcons.imageOutline,
                        context.tr('image_picker_dialog_gallery'),
                        () => _uploadLocalImage(ImageSource.gallery),
                      ),
                    ],
                  )
                : WebImagePicker(
                    onClose: () => setState(() => _showWebPicker = false),
                    onPick: _setWebImageUrl,
                  ),
      ),
    );
  }

  Widget _buildPickerTypeTile(
      IconData iconData, String text, Function() onTap) {
    return Container(
      height: 80.0,
      width: 80.0,
      margin: const EdgeInsets.all(kPadding / 2),
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(iconData, color: Theme.of(context).primaryColor),
            Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _uploadLocalImage(ImageSource source) async {
    XFile? image;
    try {
      image = await _imagePicker.pickImage(source: source);
      // if none is picked, `getImage` will `return` automatically
      // so show error if `image` is null
      if (image == null) {
        if (mounted) {
          _showErrorSnackBar(context.tr('image_picker_dialog_error_not_found'));
        }
        return;
      }
    } catch (e) {
      if (ImageAccess.isDenied(e)) {
        if (mounted) {
          ImageAccess.request(context, source);
        }
        return;
      }
      _log.severe('Error getImage', e);
      if (mounted) {
        _showErrorSnackBar(context.tr('image_picker_dialog_error_not_found'));
      }
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });
      final storedRef = await StorageService.uploadFile(image);
      if (storedRef == null) {
        throw Exception('upload task is null');
      }
      _isLoading = false;

      if (!mounted) {
        return;
      }
      Navigator.pop<PickedImage>(
          context, (image: storedRef.name, credit: null));
    } catch (e) {
      _log.severe('ERR: StorageService.uploadFile', e);
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar(context.tr('image_picker_dialog_error_not_found'));
    }
  }

  void _setWebImageUrl(String url, ImageCredit? credit) {
    final parsedUri = Uri.tryParse(url);
    if (parsedUri != null && parsedUri.isAbsolute) {
      Navigator.pop<PickedImage>(context, (image: url, credit: credit));
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) {
      return;
    }
    MainSnackbar(
      message: message,
      isError: true,
    ).show(context);
  }
}
