abstract final class MapLimits {
  static const initialZoom = 17.0;
  static const minZoom = 3.0;
  static const maxZoom = 19.0;
  static const staleAfter = Duration(seconds: 10);
  static const tileCacheBytes = 128 * 1024 * 1024;
  static const tiles = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const userAgent = 'RUNWILD/0.1 (id.runwild.app)';
}
