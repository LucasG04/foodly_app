import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../constants.dart';
import '../../services/storage_service.dart';
import '../../utils/main_snackbar.dart';
import '../small_circular_progress_indicator.dart';
import 'web_image_picker.dart';

class SelectPickerDialog extends StatefulWidget {
  const SelectPickerDialog({super.key});

  @override
  State<SelectPickerDialog> createState() => _SelectPickerDialogState();
}

class _SelectPickerDialogState extends State<SelectPickerDialog> {
  final Logger _log = Logger('SelectPickerDialog');
  final ImagePicker _imagePicker = ImagePicker();
  final _kPhotoAccessDeniedKey = 'photo_access_denied';
  final _kCameraAccessDeniedKey = 'camera_access_denied';

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
                height: MediaQuery.of(context).size.width * 0.35,
                width: MediaQuery.of(context).size.width * 0.7,
                child: const Center(child: SmallCircularProgressIndicator()),
              )
            : !_showWebPicker
                ? Wrap(
                    alignment: WrapAlignment.center,
                    spacing: kPadding / 2,
                    children: [
                      _buildPickerTypeTile(
                        EvaIcons.globe2Outline,
                        'image_picker_dialog_web'.tr(),
                        () => setState(() => _showWebPicker = true),
                      ),
                      _buildPickerTypeTile(
                        EvaIcons.cameraOutline,
                        'image_picker_dialog_camera'.tr(),
                        () => _uploadLocalImage(ImageSource.camera),
                      ),
                      _buildPickerTypeTile(
                        EvaIcons.imageOutline,
                        'image_picker_dialog_gallery'.tr(),
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
        _showErrorSnackBar('image_picker_dialog_error_not_found'.tr());
        return;
      }
    } catch (e) {
      if (e is PlatformException &&
          [_kCameraAccessDeniedKey, _kPhotoAccessDeniedKey].contains(e.code)) {
        _checkPermission(source);
        return;
      }
      _log.severe('Error getImage', e);
      _showErrorSnackBar('image_picker_dialog_error_not_found'.tr());
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
      Navigator.pop(context, storedRef.name);
    } catch (e) {
      _log.severe('ERR: StorageService.uploadFile', e);
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('image_picker_dialog_error_not_found'.tr());
    }
  }

  void _setWebImageUrl(String url) {
    final parsedUri = Uri.tryParse(url);
    if (parsedUri != null && parsedUri.isAbsolute) {
      Navigator.pop(context, url);
    }
  }

  Future<void> _checkPermission(ImageSource source) async {
    final status = await (source == ImageSource.camera
        ? Permission.camera.request()
        : Permission.photos.request());

    if (_permissionStatusIsInvalid(status)) {
      _showErrorSnackBar(
        (source == ImageSource.camera
                ? 'image_picker_dialog_camera_access_denied'
                : 'image_picker_dialog_photo_access_denied')
            .tr(),
      );
    }
  }

  bool _permissionStatusIsInvalid(PermissionStatus status) {
    return status == PermissionStatus.denied ||
        status == PermissionStatus.permanentlyDenied;
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) {
      return;
    }
    MainSnackbar(
      message: message,
      isError: true,
      isDismissible: true,
    ).show(context);
  }
}
