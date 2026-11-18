import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/app_update_service.dart';
import '../../../design/components/rw_button.dart';
import '../../../design/tokens/rw_tokens.dart';
import '../../../domain/release_notes.dart';
import '../../../l10n/generated/app_localizations.dart';

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

  Future<void> _openDownload(BuildContext context) async {
    try {
      final opened = await launchUrl(
        Uri.parse(info.downloadUrl),
        mode: LaunchMode.externalApplication,
      );
      if (opened) return;
    } catch (error) {
      debugPrint('Update link unavailable: ${error.runtimeType}');
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).updateDownloadError),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final notes = parseReleaseNotes(info.releaseNotes);
    return Dialog(
      backgroundColor: RwColors.paper100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RwRadius.lg),
      ),
      insetPadding: const EdgeInsets.all(RwSpace.screen),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(RwSpace.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                s.updateTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: RwSpace.xs),
              Text(
                'v${info.latestVersion}',
                style: const TextStyle(
                  fontFamily: RwType.family,
                  fontSize: RwType.displayM,
                  fontWeight: FontWeight.w900,
                  color: RwColors.ink950,
                ),
              ),
              const SizedBox(height: RwSpace.xxs),
              Text(
                s.updateInstalled(info.currentVersion),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: RwSpace.lg),
              Text(
                s.updateChanges,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Divider(height: RwSpace.lg),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.3,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (notes.isEmpty) Text(s.updateEmpty),
                      for (final note in notes)
                        Padding(
                          padding: const EdgeInsets.only(bottom: RwSpace.sm),
                          child: note.kind == ReleaseNoteKind.bullet
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: RwSpace.xs),
                                      child: SizedBox(
                                        width: RwSpace.xxs,
                                        height: RwSpace.xxs,
                                        child: ColoredBox(
                                          color: RwColors.lime700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: RwSpace.sm),
                                    Expanded(child: Text(note.text)),
                                  ],
                                )
                              : Text(
                                  note.text,
                                  style: note.kind == ReleaseNoteKind.heading
                                      ? Theme.of(context).textTheme.titleSmall
                                      : null,
                                ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: RwSpace.md),
              RwButton.primary(
                label: s.updateDownload,
                icon: Icons.download_outlined,
                onPressed: () => _openDownload(context),
              ),
              const SizedBox(height: RwSpace.xs),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(s.updateLater),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
