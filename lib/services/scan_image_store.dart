import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'crash_log.dart';

/// Copies a picked/captured image into app-controlled storage, validates
/// magic bytes, and downscales large images before OCR / ML Kit sees them.
class ScanImageStore {
  ScanImageStore._();

  static const _minBytes = 32;
  static const _maxBytes = 40 * 1024 * 1024; // 40 MB safety cap
  static const _maxEdge = 2000;
  static const _downscaleOverBytes = 1 * 1024 * 1024; // 1 MB

  /// Returns a stable absolute path under the app documents directory.
  /// Throws [StateError] with a clear message when the source is unusable.
  static Future<String> persistAndValidate(String sourcePath) async {
    await CrashLog.log('ScanImageStore.persistAndValidate start: $sourcePath');

    if (sourcePath.trim().isEmpty) {
      throw StateError('Image path is empty.');
    }

    // content:// and other non-file schemes cannot be opened as File.
    if (sourcePath.startsWith('content:') ||
        sourcePath.startsWith('http:') ||
        sourcePath.startsWith('https:')) {
      throw StateError(
        'Unsupported image URI scheme (expected a local file path): $sourcePath',
      );
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

    final finalPath = await _maybeDownscale(dest);
    await CrashLog.log(
      'ScanImageStore: persisted → $finalPath '
      '(${await File(finalPath).length()} bytes)',
    );
    return finalPath;
  }

  /// Decode + resize large images so ML Kit / Image.file stay memory-safe.
  static Future<String> _maybeDownscale(File file) async {
    try {
      final bytes = await file.readAsBytes();
      if (bytes.length < _downscaleOverBytes) {
        // Still check dimensions — camera JPEGs can be huge but compressed small.
      }

      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        await CrashLog.log('ScanImageStore: decode failed; keeping original');
        return file.path;
      }

      final needsResize =
          decoded.width > _maxEdge || decoded.height > _maxEdge;
      final needsReencode = bytes.length > _downscaleOverBytes || needsResize;
      if (!needsReencode) return file.path;

      img.Image sized = decoded;
      if (needsResize) {
        if (decoded.width >= decoded.height) {
          sized = img.copyResize(
            decoded,
            width: _maxEdge,
            interpolation: img.Interpolation.average,
          );
        } else {
          sized = img.copyResize(
            decoded,
            height: _maxEdge,
            interpolation: img.Interpolation.average,
          );
        }
      }

      final jpg = Uint8List.fromList(img.encodeJpg(sized, quality: 85));
      // Always write .jpg after re-encode for ML Kit friendliness.
      final outPath = p.setExtension(file.path, '.jpg');
      final out = File(outPath);
      await out.writeAsBytes(jpg, flush: true);
      if (outPath != file.path) {
        try {
          await file.delete();
        } catch (_) {}
      }
      await CrashLog.log(
        'ScanImageStore: downscaled ${decoded.width}x${decoded.height} '
        '→ ${sized.width}x${sized.height} (${jpg.length} bytes)',
      );
      return out.path;
    } catch (e, st) {
      await CrashLog.log('ScanImageStore downscale failed; keeping original', e, st);
      return file.path;
    }
  }

  static Future<Directory> _scanDir() async {
    // Documents survive better than temp across activity / process edges.
    final base = await getApplicationDocumentsDirectory();
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
