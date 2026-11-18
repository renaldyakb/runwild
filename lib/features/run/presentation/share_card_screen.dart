import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/services/share_card_service.dart';
import '../../../design/components/rw_button.dart';
import '../../../design/components/rw_chip.dart';
import '../../../design/components/rw_page.dart';
import '../../../design/components/rw_route_view.dart';
import '../../../design/tokens/rw_tokens.dart';
import '../../../domain/stats/stats_engine.dart';
import '../../../domain/tracking/run_summary.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../foundation/application/home_stats_provider.dart';
import '../../profile/application/profile_service.dart';
import '../application/run_journal.dart';
import 'share_card_widget.dart';

class ShareCardScreen extends ConsumerStatefulWidget {
  const ShareCardScreen({required this.summary, super.key});
  final RunSummary summary;

  @override
  ConsumerState<ShareCardScreen> createState() => _ShareCardScreenState();
}

class _ShareCardScreenState extends ConsumerState<ShareCardScreen> {
  final _boundaryKey = GlobalKey();
  var _theme = ShareCardTheme.primeLime;
  var _format = ShareCardFormat.story;
  var _hideRoute = false;
  var _initializedPrivacy = false;
  var _sharing = false;
  Uint8List? _customImage;
  Set<int> _segmentStarts = const {};
  List<LatLngPoint> _routePoints = const [];

  @override
  void initState() {
    super.initState();
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    final sessionId = widget.summary.sessionId;
    if (sessionId != null) {
      try {
        final pts = await ref.read(runJournalProvider).sessionPoints(sessionId);
        if (mounted && pts.isNotEmpty) {
          setState(() {
            _segmentStarts = {
              for (var i = 0; i < pts.length; i++)
                if (pts[i].segmentStart) i,
            };
            _routePoints = [
              for (final p in pts)
                (latitude: p.latitude, longitude: p.longitude),
            ];
          });
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).shareRouteError),
            ),
          );
        }
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 88,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        if (mounted) setState(() => _customImage = bytes);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).shareImageError)),
        );
      }
    }
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final boundary =
          _boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(
        pixelRatio: RwSize.shareExportWidth / boundary.size.width,
      );
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (byteData == null) return;
      final pngBytes = byteData.buffer.asUint8List();

      final service = ref.read(shareCardServiceProvider);
      final shared = await service.shareImage(
        pngBytes,
        title: 'Sesi Lari RUNWILD',
        text: 'Lari bersama RUNWILD · RUN FREE, GO WILD.',
      );
      if (!shared) throw StateError('Image share failed');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).shareError)),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initializedPrivacy) {
      final profile = ref.watch(userProfileProvider).value;
      if (profile != null) {
        _hideRoute = profile.privacy.hideStartEnd;
        _initializedPrivacy = true;
      }
    }

    final s = AppLocalizations.of(context);
    final records = ref.watch(personalRecordsProvider).value;
    final pbs = records == null
        ? const <String>[]
        : StatsEngine.detectPersonalBestsForSession(
            startedAt: widget.summary.startedAt,
            records: records,
          );
    return Scaffold(
      backgroundColor: RwColors.paper50,
      appBar: AppBar(title: Text(s.shareTitle)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(RwSpace.md),
          child: RwButton.primary(
            label: s.shareAction,
            icon: Icons.ios_share,
            loading: _sharing,
            onPressed: _share,
          ),
        ),
      ),
      body: SafeArea(
        child: RwPage(
          children: [
            Center(
              child: SizedBox(
                width: _format == ShareCardFormat.story
                    ? RwSize.sharePreviewWidth
                    : RwSize.shareCanvas,
                child: RepaintBoundary(
                  key: _boundaryKey,
                  child: ShareCardWidget(
                    summary: widget.summary,
                    theme: _theme,
                    format: _format,
                    hideRoute: _hideRoute,
                    routePoints: _routePoints,
                    segmentStarts: _segmentStarts,
                    backgroundImageBytes: _customImage,
                    personalBests: pbs,
                  ),
                ),
              ),
            ),
            const SizedBox(height: RwSpace.xs),
            Center(
              child: Text(
                s.sharePreview,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            const SizedBox(height: RwSpace.lg),
            Text(s.shareFormat, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: RwSpace.xs),
            RwSegmentedControl<ShareCardFormat>(
              items: [
                RwSegmentItem(
                  value: ShareCardFormat.story,
                  label: s.shareStory,
                ),
                RwSegmentItem(
                  value: ShareCardFormat.square,
                  label: s.shareSquare,
                ),
              ],
              selectedValue: _format,
              onChanged: (value) => setState(() => _format = value),
            ),
            const SizedBox(height: RwSpace.lg),
            Text(s.shareTheme, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: RwSpace.xs),
            RwSegmentedControl<ShareCardTheme>(
              items: [
                RwSegmentItem(
                  value: ShareCardTheme.primeLime,
                  label: s.shareLime,
                ),
                RwSegmentItem(
                  value: ShareCardTheme.cleanPaper,
                  label: s.sharePaper,
                ),
                RwSegmentItem(
                  value: ShareCardTheme.boldCharcoal,
                  label: s.shareCharcoal,
                ),
              ],
              selectedValue: _theme,
              onChanged: (value) => setState(() {
                _theme = value;
                _customImage = null;
              }),
            ),
            const SizedBox(height: RwSpace.lg),
            Text(s.sharePhoto, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: RwSpace.xs),
            Wrap(
              spacing: RwSpace.xs,
              runSpacing: RwSpace.xs,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(s.shareCamera),
                ),
                OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(s.shareGallery),
                ),
                if (_customImage != null)
                  TextButton(
                    onPressed: () => setState(() => _customImage = null),
                    child: Text(s.shareRemovePhoto),
                  ),
              ],
            ),
            const SizedBox(height: RwSpace.md),
            const Divider(),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(s.sharePrivate),
              subtitle: Text(s.sharePrivateHint),
              value: _hideRoute,
              onChanged: (value) => setState(() => _hideRoute = value),
            ),
          ],
        ),
      ),
    );
  }
}
