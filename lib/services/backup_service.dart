import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../models/app_settings.dart';
import 'hive_service.dart';

class BackupService {
  /// Creates a single .zip file containing every Hive box file and every
  /// image folder (worker photos, company logo - already compressed on
  /// save, so backup size stays minimal). Returns the zip file.
  static Future<File> createBackup() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final archive = Archive();

    // Hive stores each box as <boxName>.hive (+ .lock) directly in the
    // documents dir when initFlutter() is used without a subdirectory.
    final hiveFiles = docsDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.hive'));
    for (final f in hiveFiles) {
      final bytes = await f.readAsBytes();
      final name = f.path.split(Platform.pathSeparator).last;
      archive.addFile(ArchiveFile('hive/$name', bytes.length, bytes));
    }

    // Image folders
    for (final folder in ['worker_photos', 'company_logo']) {
      final dir = Directory('${docsDir.path}/$folder');
      if (await dir.exists()) {
        final files = dir.listSync().whereType<File>();
        for (final f in files) {
          final bytes = await f.readAsBytes();
          final name = f.path.split(Platform.pathSeparator).last;
          archive.addFile(ArchiveFile('$folder/$name', bytes.length, bytes));
        }
      }
    }

    final zipData = ZipEncoder().encode(archive);
    final backupDir = Directory('${docsDir.path}/backups');
    if (!await backupDir.exists()) await backupDir.create(recursive: true);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final zipFile = File('${backupDir.path}/EasyFlow_Backup_$timestamp.zip');
    await zipFile.writeAsBytes(zipData);

    // Record backup date for the 30-day reminder banner.
    final settingsBox = Hive.box<AppSettings>(HiveBoxes.appSettings);
    final settings = settingsBox.getAt(0);
    if (settings != null) {
      settings.lastBackupDate = DateTime.now();
      await settings.save();
    }

    return zipFile;
  }

  /// Restores from a previously created backup zip. Closes all Hive boxes,
  /// overwrites the box files + image folders, then reopens everything.
  static Future<void> restoreBackup(File zipFile) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    await HiveService.closeAll();

    for (final file in archive) {
      if (!file.isFile) continue;
      final parts = file.name.split('/');
      if (parts.length < 2) continue;
      final folder = parts[0];
      final fileName = parts.sublist(1).join('/');

      String targetPath;
      if (folder == 'hive') {
        targetPath = '${docsDir.path}/$fileName';
      } else {
        final targetDir = Directory('${docsDir.path}/$folder');
        if (!await targetDir.exists()) await targetDir.create(recursive: true);
        targetPath = '${targetDir.path}/$fileName';
      }
      final outFile = File(targetPath);
      await outFile.writeAsBytes(file.content as List<int>);
    }

    await HiveService.init();
  }
}
