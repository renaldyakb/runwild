import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

abstract interface class ShareCardService {
  Future<bool> shareImage(Uint8List pngBytes, {String? title, String? text});
  Future<String?> saveImage(Uint8List pngBytes, {String? fileName});
}

final shareCardServiceProvider = Provider<ShareCardService>((ref) {
  return const DeviceShareCardService();
});

class DeviceShareCardService implements ShareCardService {
  const DeviceShareCardService();

  @override
  Future<bool> shareImage(
    Uint8List pngBytes, {
    String? title,
    String? text,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/runwild_share_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(pngBytes, flush: true);
      final xFile = XFile(file.path, mimeType: 'image/png');
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          text: text ?? 'RUNWILD · RUN. TRACK. IMPROVE. GO WILD.',
          subject: title ?? 'Sesi Lari RUNWILD',
        ),
      );
      return result.status == ShareResultStatus.success;
    } on Exception catch (error) {
      debugPrint('Share card failed: ${error.runtimeType}');
      return false;
    }
  }

  @override
  Future<String?> saveImage(Uint8List pngBytes, {String? fileName}) async {
    if (pngBytes.isEmpty) return null;
    try {
      Directory? targetDir;
      if (Platform.isAndroid) {
        final dirs = await getExternalStorageDirectories(
          type: StorageDirectory.pictures,
        );
        if (dirs != null && dirs.isNotEmpty) targetDir = dirs.first;
      }
      targetDir ??= await getApplicationDocumentsDirectory();
      final name =
          fileName ?? 'runwild_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${targetDir.path}/$name');
      await file.writeAsBytes(pngBytes, flush: true);
      return file.path;
    } on Exception catch (error) {
      debugPrint('Save share card failed: ${error.runtimeType}');
      return null;
    }
  }
}
