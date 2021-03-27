import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  StorageService._();

  static final String _storageMealImageFolder = 'meal-images/';

  static Future<UploadTask> uploadFile(PickedFile file) async {
    if (file == null) {
      return null;
    }

    String fileName = new DateTime.now().microsecondsSinceEpoch.toString();
    UploadTask uploadTask;
    // Create a Reference to the file
    Reference ref = FirebaseStorage.instance
        .ref()
        .child(_storageMealImageFolder)
        .child('$fileName.jpg');

    if (kIsWeb) {
      uploadTask = ref.putData(await file.readAsBytes());
    } else {
      uploadTask = ref.putFile(File(file.path));
    }

    return Future.value(uploadTask);
  }

  static Future<String> getMealImageUrl(String fileName) {
    if (fileName == null || fileName.isEmpty) {
      return null;
    }

    // Create a Reference to the file
    Reference ref = FirebaseStorage.instance
        .ref()
        .child(_storageMealImageFolder)
        .child(fileName);

    return ref.getDownloadURL();
  }
}
