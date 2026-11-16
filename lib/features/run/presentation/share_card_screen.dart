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
            _routePoints = [
              for (final p in pts)
                (latitude: p.latitude, longitude: p.longitude),
            ];
          });
        }
      } catch (_) {}
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
        setState(() => _customImage = bytes);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat memuat gambar.')),
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
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final pngBytes = byteData.buffer.asUint8List();

      final service = ref.read(shareCardServiceProvider);
      await service.shareImage(
        pngBytes,
        title: 'Sesi Lari RUNWILD',
        text: 'Lari bersama RUNWILD · RUN FREE, GO WILD.',
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Belum bisa membagikan kartu. Coba lagi.'),
          ),
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

    final isStory = _format == ShareCardFormat.story;

    return Scaffold(
      backgroundColor: RwColors.paper50,
      appBar: AppBar(
        title: const Text(
          'Kartu Bagikan',
          style: TextStyle(
            fontFamily: RwType.family,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SafeArea(
        child: RwPage(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            // ── Section 1: Format & Rasio ─────────────────────────────
            Container(
              padding: const EdgeInsets.all(RwSpace.sm + 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(RwRadius.md),
                border: Border.all(color: const Color(0xFFE2E6DC), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'FORMAT RASIO',
                    style: TextStyle(
                      fontFamily: RwType.family,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                      color: RwColors.mutedTextOnLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RwSegmentedControl<ShareCardFormat>(
                    items: const [
                      RwSegmentItem(
                        value: ShareCardFormat.story,
                        label: 'Story (9:16)',
                        icon: Icons.stay_current_portrait_rounded,
                      ),
                      RwSegmentItem(
                        value: ShareCardFormat.square,
                        label: 'Persegi (1:1)',
                        icon: Icons.crop_square_rounded,
                      ),
                    ],
                    selectedValue: _format,
                    onChanged: (fmt) => setState(() => _format = fmt),
                  ),
                ],
              ),
            ),
            const SizedBox(height: RwSpace.sm),

            // ── Section 2: Tema Visual ────────────────────────────────
            Container(
              padding: const EdgeInsets.all(RwSpace.sm + 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(RwRadius.md),
                border: Border.all(color: const Color(0xFFE2E6DC), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'TEMA VISUAL',
                    style: TextStyle(
                      fontFamily: RwType.family,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                      color: RwColors.mutedTextOnLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RwSegmentedControl<ShareCardTheme>(
                    items: const [
                      RwSegmentItem(
                        value: ShareCardTheme.primeLime,
                        label: '⚡ Prime Lime',
                      ),
                      RwSegmentItem(
                        value: ShareCardTheme.cleanPaper,
                        label: '📄 Kertas Bersih',
                      ),
                      RwSegmentItem(
                        value: ShareCardTheme.boldCharcoal,
                        label: '⬛ Bold Charcoal',
                      ),
                    ],
                    selectedValue: _theme,
                    onChanged: (thm) => setState(() => _theme = thm),
                  ),
                ],
              ),
            ),
            const SizedBox(height: RwSpace.sm),

            // ── Section 3: Foto Latar Medsos ──────────────────────────
            Container(
              padding: const EdgeInsets.all(RwSpace.sm + 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(RwRadius.md),
                border: Border.all(color: const Color(0xFFE2E6DC), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.photo_camera_rounded,
                        size: 18,
                        color: RwColors.ink950,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Foto Latar Medsos',
                          style: TextStyle(
                            fontFamily: RwType.family,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (_customImage != null)
                        TextButton.icon(
                          onPressed: () => setState(() => _customImage = null),
                          icon: const Icon(Icons.close_rounded, size: 15),
                          label: const Text(
                            'Hapus Foto',
                            style: TextStyle(
                              fontFamily: RwType.family,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: RwColors.danger500,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_outlined, size: 17),
                          label: const Text(
                            'Kamera',
                            style: TextStyle(
                              fontFamily: RwType.family,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: RwColors.ink950,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Color(0xFFE2E6DC)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                RwRadius.pill,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(
                            Icons.photo_library_outlined,
                            size: 17,
                          ),
                          label: const Text(
                            'Galeri',
                            style: TextStyle(
                              fontFamily: RwType.family,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: RwColors.ink950,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Color(0xFFE2E6DC)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                RwRadius.pill,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: RwSpace.sm),

            // ── Section 4: Privasi Rute ───────────────────────────────
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(RwRadius.md),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: RwSpace.sm + 2,
                  vertical: RwSpace.xs,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(RwRadius.md),
                  border: Border.all(color: const Color(0xFFE2E6DC), width: 1),
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(
                    Icons.shield_outlined,
                    size: 20,
                    color: RwColors.ink950,
                  ),
                  title: const Text(
                    'Sembunyikan privasi rute',
                    style: TextStyle(
                      fontFamily: RwType.family,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: const Text(
                    'Sembunyikan alur GPS demi keamanan tempat tinggal Anda',
                    style: TextStyle(
                      fontFamily: RwType.family,
                      fontSize: 11,
                      color: RwColors.mutedTextOnLight,
                    ),
                  ),
                  value: _hideRoute,
                  onChanged: (val) => setState(() => _hideRoute = val),
                ),
              ),
            ),
            const SizedBox(height: RwSpace.md),

            // ── Section 5: Live Interactive Card Preview ──────────────
            Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: isStory ? 260 : 280),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(RwRadius.lg + 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: RepaintBoundary(
                  key: _boundaryKey,
                  child: Builder(
                    builder: (context) {
                      final records = ref.watch(personalRecordsProvider).value;
                      final pbs = records != null
                          ? StatsEngine.detectPersonalBestsForSession(
                              startedAt: widget.summary.startedAt,
                              records: records,
                            )
                          : const <String>[];
                      return ShareCardWidget(
                        summary: widget.summary,
                        theme: _theme,
                        format: _format,
                        hideRoute: _hideRoute,
                        routePoints: _routePoints,
                        backgroundImageBytes: _customImage,
                        personalBests: pbs,
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: RwSpace.xs),
            Center(
              child: Text(
                'Pratinjau kartu lari resolusi tinggi siap dibagikan',
                style: TextStyle(
                  fontFamily: RwType.family,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: RwColors.mutedTextOnLight.withValues(alpha: 0.8),
                ),
              ),
            ),
            const SizedBox(height: RwSpace.md),

            // ── Action Buttons ────────────────────────────────────────
            RwButton.primary(
              label: 'Bagikan Gambar',
              icon: Icons.share_rounded,
              loading: _sharing,
              onPressed: _share,
            ),
            const SizedBox(height: RwSpace.xs),
            RwButton.secondary(
              label: 'Tutup',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
