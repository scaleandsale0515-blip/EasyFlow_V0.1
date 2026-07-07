import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../models/app_settings.dart';
import '../../services/hive_service.dart';
import '../../services/backup_service.dart';
import '../../utils/helpers.dart';
import '../../utils/app_theme.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  bool _busy = false;

  Future<void> _createBackup() async {
    setState(() => _busy = true);
    try {
      final file = await BackupService.createBackup();
      if (mounted) {
        await Share.shareXFiles([XFile(file.path)], text: 'EasyFlow Backup');
        setState(() {});
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restoreBackup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Backup?'),
        content: const Text('This will replace all current app data with the data from the backup file. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restore')),
        ],
      ),
    );
    if (confirm != true) return;

    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['zip']);
    if (result == null || result.files.single.path == null) return;

    setState(() => _busy = true);
    try {
      await BackupService.restoreBackup(File(result.files.single.path!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restore complete. Please restart the app.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsBox = Hive.box<AppSettings>(HiveBoxes.appSettings);
    final lastBackup = settingsBox.isNotEmpty ? settingsBox.getAt(0)!.lastBackupDate : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.accentCyan),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          lastBackup == null
                              ? 'No backup taken yet. It\'s recommended to back up regularly.'
                              : 'Last backup: ${Fmt.date(lastBackup)}',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Backup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                const Text(
                  'Creates a complete backup of all your data - Production, Transport, Workers, Transporters, Item Catalog, Company Profile, and photos (compressed to keep file size small).',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(onPressed: _createBackup, icon: const Icon(Icons.backup_outlined), label: const Text('Create & Share Backup')),
                const SizedBox(height: 32),
                const Text('Restore', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                const Text(
                  'Restores app data from a previously created backup .zip file. This will overwrite all current data.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(onPressed: _restoreBackup, icon: const Icon(Icons.restore_outlined), label: const Text('Restore from Backup File')),
              ],
            ),
    );
  }
}
