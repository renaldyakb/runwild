import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../design/components/rw_button.dart';
import '../../design/tokens/rw_tokens.dart';
import '../../domain/tracking/live_route.dart';
import '../../l10n/generated/app_localizations.dart';
import '../constants/map_limits.dart';

abstract interface class MapService {
  Widget buildLiveMap({
    required LiveRouteSnapshot route,
    required bool locked,
    bool historical = false,
  });
}

final mapServiceProvider = Provider<MapService>(
  (ref) => const OpenStreetMapService(),
);

class OpenStreetMapService implements MapService {
  const OpenStreetMapService({this.tileProviderFactory});
  final TileProvider Function()? tileProviderFactory;

  @override
  Widget buildLiveMap({
    required LiveRouteSnapshot route,
    required bool locked,
    bool historical = false,
  }) => _LiveMap(
    route: route,
    locked: locked,
    historical: historical,
    tileProviderFactory: tileProviderFactory,
  );
}

class _LiveMap extends StatefulWidget {
  const _LiveMap({
    required this.route,
    required this.locked,
    this.historical = false,
    this.tileProviderFactory,
  });
  final LiveRouteSnapshot route;
  final bool locked;
  final bool historical;
  final TileProvider Function()? tileProviderFactory;
  @override
  State<_LiveMap> createState() => _LiveMapState();
}

class _LiveMapState extends State<_LiveMap> {
  final _controller = MapController();
  TileProvider? _tiles;
  bool _ready = false;
  bool _follow = true;
  bool _tileError = false;
  bool _loaded = false;
  bool _notifiedOffline = false;

  LatLng? get _position {
    final point = widget.route.position;
    return point == null ? null : LatLng(point.latitude, point.longitude);
  }

  TileProvider _provider() =>
      widget.tileProviderFactory?.call() ??
      NetworkTileProvider(
        headers: <String, String>{'User-Agent': MapLimits.userAgent},
        silenceExceptions: true,
        cachingProvider: BuiltInMapCachingProvider.getOrCreateInstance(
          maxCacheSize: MapLimits.tileCacheBytes,
        ),
      );

  @override
  void didUpdateWidget(covariant _LiveMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_ready &&
        _follow &&
        oldWidget.route.position != widget.route.position) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final position = _position;
        if (mounted && _ready && _follow && position != null) {
          _controller.move(position, _controller.camera.zoom);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _loadedTile(bool error) {
    if (error ? _tileError : _loaded) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        if (error) {
          _tileError = true;
          if (!_notifiedOffline) {
            _notifiedOffline = true;
            final s = AppLocalizations.of(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  s.mapOffline,
                  style: const TextStyle(
                    fontFamily: RwType.family,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        } else {
          _loaded = true;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final position = _position;
    final segments = widget.route.segments;
    final last = segments.isNotEmpty && segments.last.isNotEmpty
        ? segments.last.last
        : null;
    final center =
        position ??
        (last == null ? null : LatLng(last.latitude, last.longitude));
    final stale =
        (widget.route.age ?? MapLimits.staleAfter) >= MapLimits.staleAfter;

    if (center == null) {
      return Container(
        constraints: const BoxConstraints(minHeight: RwSize.liveMapHeight),
        padding: const EdgeInsets.all(RwSpace.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(RwRadius.lg),
          border: Border.all(color: const Color(0xFFE2E6DC), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: RwColors.paper100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.gps_not_fixed_rounded,
                size: 28,
                color: RwColors.mutedTextOnLight,
              ),
            ),
            const SizedBox(height: RwSpace.md),
            Text(
              s.mapWaiting,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: RwType.family,
                fontWeight: FontWeight.w600,
                color: RwColors.mutedTextOnLight,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.historical)
          Container(
            margin: const EdgeInsets.only(bottom: RwSpace.xs),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: stale ? const Color(0xFFFEF3C7) : Colors.white,
              borderRadius: BorderRadius.circular(RwRadius.sm),
              border: Border.all(
                color: stale
                    ? const Color(0xFFFDE68A)
                    : const Color(0xFFE2E6DC),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  stale ? Icons.gps_not_fixed_rounded : Icons.gps_fixed_rounded,
                  size: 14,
                  color: stale ? const Color(0xFFD97706) : RwColors.lime700,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (position == null || stale)
                        Text(
                          s.mapStale,
                          style: const TextStyle(
                            fontFamily: RwType.family,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      if (widget.route.position case final fix?)
                        Text(
                          s.mapAccuracy(fix.accuracyMeters.ceil()),
                          style: const TextStyle(
                            fontFamily: RwType.family,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: RwColors.ink950,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: RwSpace.xs),

        // Live Map View Frame
        Container(
          height: RwSize.liveMapHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(RwRadius.lg),
            border: Border.all(color: const Color(0xFFE2E6DC), width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(RwRadius.lg),
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _controller,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: MapLimits.initialZoom,
                    initialCameraFit: widget.historical
                        ? CameraFit.coordinates(
                            coordinates: [
                              for (final segment in segments)
                                for (final point in segment)
                                  LatLng(point.latitude, point.longitude),
                            ],
                            padding: const EdgeInsets.all(RwSpace.xxl),
                            maxZoom: MapLimits.initialZoom,
                          )
                        : null,
                    minZoom: MapLimits.minZoom,
                    maxZoom: MapLimits.maxZoom,
                    backgroundColor: RwColors.paper200,
                    interactionOptions: InteractionOptions(
                      flags: widget.locked
                          ? InteractiveFlag.none
                          : InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                    onMapReady: () => _ready = true,
                    onPositionChanged: (_, hasGesture) {
                      if (hasGesture && _follow) {
                        setState(() => _follow = false);
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: MapLimits.tiles,
                      tileProvider: _tiles ??= _provider(),
                      userAgentPackageName: 'id.runwild.app',
                      maxNativeZoom: MapLimits.maxZoom.toInt(),
                      panBuffer: 0,
                      errorTileCallback: (_, _, _) => _loadedTile(true),
                      tileBuilder: (_, tile, image) {
                        if (image.loadFinishedAt != null) {
                          _loadedTile(image.loadError);
                        }
                        return tile;
                      },
                    ),
                    PolylineLayer(
                      polylines: [
                        for (final segment in segments)
                          if (segment.length >= 2)
                            Polyline(
                              points: [
                                for (final point in segment)
                                  LatLng(point.latitude, point.longitude),
                              ],
                              color: RwColors.lime700,
                              strokeWidth: RwSize.focus + RwSize.hairline,
                              borderColor: RwColors.lime500,
                              borderStrokeWidth: RwSize.outline,
                            ),
                      ],
                    ),
                    if (position != null)
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: position,
                            radius: widget.route.position?.accuracyMeters ?? 0,
                            useRadiusInMeter: true,
                            color: RwColors.lime700.withValues(alpha: 0.15),
                            borderColor: RwColors.lime700,
                            borderStrokeWidth: RwSize.hairline,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        if (segments.isNotEmpty && segments.first.isNotEmpty)
                          Marker(
                            point: LatLng(
                              segments.first.first.latitude,
                              segments.first.first.longitude,
                            ),
                            width: RwSize.icon,
                            height: RwSize.icon,
                            child: const Icon(
                              Icons.trip_origin,
                              color: RwColors.ink950,
                            ),
                          ),
                        if (position != null)
                          Marker(
                            point: position,
                            width: RwSize.touch,
                            height: RwSize.touch,
                            child: Semantics(
                              label: stale ? s.mapStale : s.mapCurrent,
                              child: Icon(
                                Icons.my_location,
                                size: RwSize.icon,
                                color: stale
                                    ? RwColors.ink500
                                    : RwColors.lime700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                // Attribution remains visible over map tiles.
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Opacity(
                    opacity: 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: GestureDetector(
                        onTap: widget.locked
                            ? null
                            : () async {
                                final opened = await launchUrl(
                                  Uri.parse(
                                    'https://www.openstreetmap.org/copyright',
                                  ),
                                  mode: LaunchMode.externalApplication,
                                );
                                if (!opened && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(s.mapLinkError)),
                                  );
                                }
                              },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.public,
                              size: 11,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              s.mapAttribution,
                              style: const TextStyle(
                                fontFamily: RwType.family,
                                fontSize: RwType.label,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: RwSpace.sm),

        // Recenter & Follow Button
        if (!widget.historical)
          RwButton.secondary(
            label: _follow ? s.mapFollowing : s.mapRecenter,
            icon: Icons.my_location,
            fullWidth: true,
            onPressed: widget.locked || position == null
                ? null
                : () {
                    setState(() => _follow = true);
                    if (_ready) {
                      _controller.move(position, _controller.camera.zoom);
                    }
                  },
          ),
      ],
    );
  }
}
