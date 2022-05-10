import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  StorageService._();

  static const String _storageMealImageFolder = 'meal-images/';

  static Future<UploadTask?> uploadFile(PickedFile? file) async {
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

  static Future<String> getMealImageUrl(String? fileName) async {
    if (fileName == null || fileName.isEmpty) {
      return '';
    }

    // Create a Reference to the file
    final Reference ref = FirebaseStorage.instance
        .ref()
        .child(_storageMealImageFolder)
        .child(fileName);

    return ref.getDownloadURL();
  }

  static Future<void> removeFile(String? fileName) async {
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
