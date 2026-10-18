import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Append-only crash / error log under app documents for post-mortem on device.
class CrashLog {
  CrashLog._();

  static Future<File>? _fileFuture;

  static Future<File> _file() {
    return _fileFuture ??= () async {
      final dir = await getApplicationDocumentsDirectory();
      final f = File(p.join(dir.path, 'crash_log.txt'));
      if (!await f.exists()) {
        await f.writeAsString('--- crash_log opened ${DateTime.now().toIso8601String()} ---\n');
      }
      return f;
    }();
  }

  static Future<void> log(String message, [Object? error, StackTrace? stack]) async {
    final buf = StringBuffer()
      ..writeln('[${DateTime.now().toIso8601String()}] $message');
    if (error != null) buf.writeln('  error: $error');
    if (stack != null) buf.writeln('  stack: $stack');
    final line = buf.toString();
    debugPrint(line);
    try {
      final f = await _file();
      await f.writeAsString(line, mode: FileMode.append, flush: true);
    } catch (e) {
      debugPrint('CrashLog write failed: $e');
    }
  }
}
