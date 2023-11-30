import 'dart:async';
import 'dart:io';

import 'package:external_path/external_path.dart';
import 'package:permission_handler/permission_handler.dart';

class HerdDump {
  static final HerdDump _instance = HerdDump._();
  static HerdDump get instance => _instance;

  HerdDump._() {
    _loadFile();
  }

  Future<void> _loadFile() async {
    var status = await Permission.storage.status;

    if (!status.isGranted) {
      await Permission.storage.request();

      status = await Permission.storage.status;
    }

    await Process.run('logcat', ['-c']);
    await Process.run('logcat', ['-G', '16M']);

    while (true) {
      var todayDate = DateTime.now();
      var fileName = 'logcat-${todayDate.millisecondsSinceEpoch}.txt';

      var path = await ExternalPath.getExternalStoragePublicDirectory(
        ExternalPath.DIRECTORY_DOWNLOADS,
      );

      File logcatFile = File('$path/$fileName');

      var sink = logcatFile.openWrite(mode: FileMode.append);

      await logcatFile.writeAsString(
        '$fileName\n',
        mode: FileMode.append,
        flush: true,
      );

      await sink.close();

      var result = await Process.run('logcat', ['-f', '$path/$fileName']);

      sink = logcatFile.openWrite(mode: FileMode.append);

      await logcatFile.writeAsString(
        '\n logcat stopped stdout: ${result.stdout} stderr: ${result.stderr}',
        mode: FileMode.append,
        flush: true,
      );

      await sink.close();
    }
  }

  Future<File> get _dumpFile async {
    // TODO: One day this should be configurable, and USUALLY it should use the
    // ApplicationDocumentsDirectory() -- however, that is not exposed to file
    // system by default, as such, hard-code for now, to unblock initial raw
    // usage for file dumping of the herd.
    //final path = await _localPath;
    //return path
    return File('/storage/emulated/0/Download/herdDump.txt');
  }

  Future<String> readFile() async {
    try {
      final file = await _dumpFile;

      // Read the file
      final contents = await file.readAsString();

      return contents;
    } catch (e) {
      // If encountering an error, return 0
      return '';
    }
  }

  Future<File> writeData(String jsonBlob) async {
    final file = await _dumpFile;

    // Write the file
    return file.writeAsString(jsonBlob);
  }
}
