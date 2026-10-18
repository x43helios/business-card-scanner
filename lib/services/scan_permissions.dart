import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// Requests camera / photos permissions before [ImagePicker] pick/capture.
/// Returns null when allowed; otherwise a user-facing reason string.
class ScanPermissions {
  ScanPermissions._();

  static Future<String?> ensureFor(ImageSource source) async {
    if (kIsWeb) return null;
    try {
      if (!Platform.isAndroid && !Platform.isIOS) return null;
    } catch (_) {
      return null;
    }

    if (source == ImageSource.camera) {
      return _ensureCamera();
    }
    return _ensurePhotos();
  }

  static Future<String?> _ensureCamera() async {
    var status = await Permission.camera.status;
    if (status.isGranted || status.isLimited) return null;

    status = await Permission.camera.request();
    if (status.isGranted || status.isLimited) return null;

    if (status.isPermanentlyDenied) {
      return 'Camera permission is permanently denied. Enable it in system settings.';
    }
    return 'Camera permission is required to take a business card photo.';
  }

  static Future<String?> _ensurePhotos() async {
    // Android 13+ photo picker often needs no storage permission; still request
    // when the platform reports it as denied so older gallery paths work.
    Permission permission;
    if (Platform.isAndroid) {
      // photos → READ_MEDIA_IMAGES (API 33+); storage for older APIs.
      final photos = await Permission.photos.status;
      if (photos.isGranted || photos.isLimited) return null;

      // On API < 33, photos may map to storage / be unavailable.
      final storage = await Permission.storage.status;
      if (storage.isGranted) return null;

      final photoReq = await Permission.photos.request();
      if (photoReq.isGranted || photoReq.isLimited) return null;

      final storageReq = await Permission.storage.request();
      if (storageReq.isGranted) return null;

      // Many devices can still use the system photo picker without grant.
      // Do not hard-block; let image_picker try and surface its own error.
      if (photoReq.isPermanentlyDenied && storageReq.isPermanentlyDenied) {
        return 'Photos permission is permanently denied. Enable it in system settings.';
      }
      return null;
    }

    // iOS
    permission = Permission.photos;
    var status = await permission.status;
    if (status.isGranted || status.isLimited) return null;
    status = await permission.request();
    if (status.isGranted || status.isLimited) return null;
    if (status.isPermanentlyDenied) {
      return 'Photos permission is permanently denied. Enable it in system settings.';
    }
    return 'Photos permission is required to pick a business card image.';
  }
}
