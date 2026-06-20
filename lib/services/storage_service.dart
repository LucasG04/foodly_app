import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:isar/isar.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

import '../models/link_metadata.dart';
import '../services/app_review_service.dart';
import '../services/plan_service.dart';
import '../services/settings_service.dart';
import '../services/version_service.dart';

class StorageService {
  static final _log = Logger('StorageService');

  StorageService._();

  static const String _storageMealImageFolder = 'meal-images/';

  // Memoize the Future, not the resolved value, so concurrent first callers
  // share a single Isar.open() instead of racing multiple opens.
  static Future<Isar>? _isarFuture;

  static Future<Isar> getIsar() {
    return _isarFuture ??= _openIsar();
  }

  static Future<Isar> _openIsar() async {
    final dir = await getApplicationDocumentsDirectory();
    return Isar.open(
      [
        LinkMetadataSchema,
        SettingsDataSchema,
        VersionDataSchema,
        AppReviewDataSchema,
        PlanDataSchema,
      ],
      directory: dir.path,
    );
  }

  static Future<Reference?> uploadFile(XFile? file) async {
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
        .child('$fileName.webp');

    if (kIsWeb) {
      uploadTask = ref.putData(await file.readAsBytes());
    } else {
      final compressed = await FlutterImageCompress.compressWithFile(
        file.path,
        quality: 85,
        format: CompressFormat.webp,
      );
      if (compressed == null) {
        return null;
      }
      uploadTask = ref.putData(compressed);
    }

    final uploadResult = await uploadTask;

    return uploadResult.ref;
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
