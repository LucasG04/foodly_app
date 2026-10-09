import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'main_snackbar.dart';

/// image_picker's camera/photo access errors (iOS), shared by every picker.
// ignore: avoid_classes_with_only_static_members
class ImageAccess {
  static bool isDenied(Object error) =>
      error is PlatformException &&
      const {'camera_access_denied', 'photo_access_denied'}
          .contains(error.code);

  /// Asks for [source]'s permission again; explains in a snackbar if it stays
  /// denied.
  static Future<void> request(BuildContext context, ImageSource source) async {
    final isCamera = source == ImageSource.camera;
    final status =
        await (isCamera ? Permission.camera : Permission.photos).request();
    if (!context.mounted || !(status.isDenied || status.isPermanentlyDenied)) {
      return;
    }
    MainSnackbar(
      message: context.tr(isCamera
          ? 'image_picker_dialog_camera_access_denied'
          : 'image_picker_dialog_photo_access_denied'),
      isError: true,
    ).show(context);
  }
}
