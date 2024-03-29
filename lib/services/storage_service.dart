import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';

class StorageService {
  static final _log = Logger('StorageService');

  StorageService._();

  static const String _storageMealImageFolder = 'meal-images/';

  static Future<UploadTask?> uploadFile(PickedFile? file) async {
    _log.finer('Call uploadFile');
    if (file == null) {
      return null;
    }

    final String fileName = DateTime.now().microsecondsSinceEpoch.toString();
    UploadTask uploadTask;
    // Create a Reference to the file
    final Reference ref = FirebaseStorage.instance
        .ref()
        .child(_storageMealImageFolder)
        .child('$fileName.jpg');

    if (kIsWeb) {
      uploadTask = ref.putData(await file.readAsBytes());
    } else {
      final compressed = await FlutterNativeImage.compressImage(
        file.path,
        quality: 25,
      );
      uploadTask = ref.putFile(compressed);
    }

    return Future.value(uploadTask);
  }

  static Future<String?> getMealImageUrl(String? fileName) async {
    _log.finer('Call getMealImageUrl with $fileName');
    if (fileName == null || fileName.isEmpty) {
      return null;
    }

    // Create a Reference to the file
    final Reference ref = FirebaseStorage.instance
        .ref()
        .child(_storageMealImageFolder)
        .child(fileName);

    try {
      return ref.getDownloadURL();
    } catch (e) {
      _log.severe('Could not get download url for $fileName', e);
      return null;
    }
  }

  static Future<void> removeFile(String? fileName) async {
    _log.finer('Call removeFile with $fileName');
    if (fileName == null || fileName.isEmpty) {
      return;
    }

    // Create a Reference to the file
    final Reference ref = FirebaseStorage.instance
        .ref()
        .child(_storageMealImageFolder)
        .child(fileName);

    await ref.delete();
  }
}
