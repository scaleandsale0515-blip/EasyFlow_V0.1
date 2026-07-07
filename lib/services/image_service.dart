import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ImageService {
  static final ImagePicker _picker = ImagePicker();

  /// Picks an image, compresses it, and saves it into app documents dir.
  /// Returns the saved file path, or null if cancelled.
  static Future<String?> pickAndCompress({required String folder, int quality = 60}) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return null;

    final dir = await getApplicationDocumentsDirectory();
    final targetDir = Directory('${dir.path}/$folder');
    if (!await targetDir.exists()) await targetDir.create(recursive: true);

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final targetPath = '${targetDir.path}/$fileName';

    final result = await FlutterImageCompress.compressAndGetFile(
      picked.path,
      targetPath,
      quality: quality,
      minWidth: 600,
      minHeight: 600,
    );
    return result?.path ?? picked.path;
  }

  static Future<void> deleteIfExists(String? path) async {
    if (path == null) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}
