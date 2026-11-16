import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

abstract interface class ShareCardService {
  Future<bool> shareImage(Uint8List pngBytes, {String? title, String? text});
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
    } catch (_) {
      return false;
    }
  }
}
