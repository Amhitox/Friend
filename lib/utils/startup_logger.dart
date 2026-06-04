import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Best-effort file logger for tracing cold-start on real devices.
///
/// Writes to `<app-files>/startup.log`.  Call [init] as soon as
/// [path_provider] is available, then use [log] anywhere.
class StartupLogger {
  static final StringBuffer _buffer = StringBuffer();
  static bool _initialized = false;
  static late File _file;

  static void log(String message) {
    final line =
        '[${DateTime.now().toIso8601String()}] $message';
    _buffer.writeln(line);
    if (_initialized) {
      try {
        _file.writeAsStringSync('$line\n', mode: FileMode.append);
      } catch (_) {
        // Best-effort: if the file write fails, the buffer still holds it.
      }
    }
  }

  static Future<void> init() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      _file = File('${dir.path}/startup.log');
      await _file.writeAsString(_buffer.toString(), mode: FileMode.write);
      _initialized = true;
    } catch (e) {
      // path_provider may fail in extreme demo scenarios — ignore.
    }
  }
}
