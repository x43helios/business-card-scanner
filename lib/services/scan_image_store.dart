import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Copies a picked/captured image into app-controlled storage and validates
/// that the file is readable before OCR / ML Kit sees it.
class ScanImageStore {
  ScanImageStore._();

  static const _minBytes = 32;
  static const _maxBytes = 40 * 1024 * 1024; // 40 MB safety cap

  /// Returns a stable absolute path under the app temp/docs directory.
  /// Throws [StateError] with a clear message when the source is unusable.
  static Future<String> persistAndValidate(String sourcePath) async {
    if (sourcePath.trim().isEmpty) {
      throw StateError('Image path is empty.');
    }

    final source = File(sourcePath);
    if (!await source.exists()) {
      throw StateError('Image file does not exist: $sourcePath');
    }

    final length = await source.length();
    if (length < _minBytes) {
      throw StateError('Image file is empty or too small ($length bytes).');
    }
    if (length > _maxBytes) {
      throw StateError('Image file is too large ($length bytes).');
    }

    // Read a small header to reject non-image / corrupt files before ML Kit.
    final header = await source.openRead(0, 16).first;
    if (!_looksLikeImage(header)) {
      throw StateError(
        'File does not look like a supported image (JPEG/PNG/WebP/GIF).',
      );
    }

    final dir = await _scanDir();
    final ext = _safeExt(sourcePath, header);
    final destPath = p.join(dir.path, 'scan_${const Uuid().v4()}$ext');
    final dest = await source.copy(destPath);

    final copiedLen = await dest.length();
    if (copiedLen < _minBytes) {
      throw StateError('Failed to copy image into app storage.');
    }

    debugPrint('ScanImageStore: persisted $copiedLen bytes → ${dest.path}');
    return dest.path;
  }

  static Future<Directory> _scanDir() async {
    final base = await getTemporaryDirectory();
    final dir = Directory(p.join(base.path, 'card_scans'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static String _safeExt(String path, List<int> header) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png') || _isPng(header)) return '.png';
    if (lower.endsWith('.webp') || _isWebp(header)) return '.webp';
    if (lower.endsWith('.gif') || _isGif(header)) return '.gif';
    return '.jpg';
  }

  static bool _looksLikeImage(List<int> h) {
    if (h.length < 3) return false;
    return _isJpeg(h) || _isPng(h) || _isWebp(h) || _isGif(h);
  }

  static bool _isJpeg(List<int> h) =>
      h.length >= 3 && h[0] == 0xFF && h[1] == 0xD8 && h[2] == 0xFF;

  static bool _isPng(List<int> h) =>
      h.length >= 8 &&
      h[0] == 0x89 &&
      h[1] == 0x50 &&
      h[2] == 0x4E &&
      h[3] == 0x47;

  static bool _isGif(List<int> h) =>
      h.length >= 4 &&
      h[0] == 0x47 &&
      h[1] == 0x49 &&
      h[2] == 0x46 &&
      h[3] == 0x38;

  static bool _isWebp(List<int> h) =>
      h.length >= 12 &&
      h[0] == 0x52 &&
      h[1] == 0x49 &&
      h[2] == 0x46 &&
      h[3] == 0x46 &&
      h[8] == 0x57 &&
      h[9] == 0x45 &&
      h[10] == 0x42 &&
      h[11] == 0x50;
}
