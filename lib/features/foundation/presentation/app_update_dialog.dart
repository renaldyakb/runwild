import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/app_update_service.dart';
import '../../../design/components/rw_button.dart';
import '../../../design/tokens/rw_tokens.dart';

class AppUpdateDialog extends StatelessWidget {
  const AppUpdateDialog({required this.info, super.key});

  final AppUpdateInfo info;

  static Future<void> show(BuildContext context, AppUpdateInfo info) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AppUpdateDialog(info: info),
    );
  }

  Future<void> _openDownload() async {
    final uri = Uri.parse(info.downloadUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RwRadius.lg),
      ),
      backgroundColor: Colors.white,
      elevation: 8,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(RwSpace.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Icon & Badges
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: RwColors.lime500,
                      borderRadius: BorderRadius.circular(RwRadius.md),
                      boxShadow: [
                        BoxShadow(
                          color: RwColors.lime600.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.system_update_rounded,
                      color: RwColors.ink950,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: RwSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Pembaruan Baru',
                              style: TextStyle(
                                fontFamily: RwType.family,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: RwColors.ink950,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: RwColors.lime100,
                                borderRadius: BorderRadius.circular(
                                  RwRadius.pill,
                                ),
                              ),
                              child: Text(
                                'v${info.latestVersion}',
                                style: const TextStyle(
                                  fontFamily: RwType.family,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: RwColors.ink950,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Versi saat ini: v${info.currentVersion}',
                          style: const TextStyle(
                            fontFamily: RwType.family,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: RwColors.mutedTextOnLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: RwSpace.md),

              // Catatan Rilis
              const Text(
                'APA YANG BARU:',
                style: TextStyle(
                  fontFamily: RwType.family,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: RwColors.mutedTextOnLight,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: RwColors.paper50,
                  borderRadius: BorderRadius.circular(RwRadius.md),
                  border: Border.all(color: const Color(0xFFE2E6DC)),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    info.releaseNotes.trim().isEmpty
                        ? 'Peningkatan performa, pembaruan antarmuka, dan perbaikan bug untuk pengalaman lari yang lebih mulus.'
                        : info.releaseNotes,
                    style: const TextStyle(
                      fontFamily: RwType.family,
                      fontSize: 13,
                      height: 1.45,
                      color: RwColors.ink800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: RwSpace.lg),

              // Tombol Aksi
              RwButton.primary(
                label: 'Perbarui Sekarang',
                icon: Icons.download_rounded,
                onPressed: () {
                  Navigator.of(context).pop();
                  _openDownload();
                },
              ),
              const SizedBox(height: RwSpace.xs),
              RwButton.secondary(
                label: 'Nanti Saja',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
