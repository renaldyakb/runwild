import 'package:lottie/lottie.dart';
import 'package:material_ui/material_ui.dart';

import '../../../design/tokens/rw_tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/weather_kind.dart';

/// Rasio ukuran ikon Material terhadap kotak piktogram Lottie agar keduanya
/// terlihat sebanding saat aset diganti ikon.
const _fallbackIconRatio = 0.62;

/// Ikon Material statis untuk satu kondisi cuaca.
IconData weatherIconFor(WeatherKind kind) => switch (kind) {
  WeatherKind.clear => Icons.wb_sunny_outlined,
  WeatherKind.partlyCloudy => Icons.wb_cloudy_outlined,
  WeatherKind.cloudy => Icons.cloud_outlined,
  WeatherKind.rain => Icons.umbrella_outlined,
  WeatherKind.snow => Icons.ac_unit_outlined,
  WeatherKind.thunderstorm => Icons.thunderstorm_outlined,
};

/// Nama kondisi cuaca yang dibaca manusia, bukan angka.
String weatherKindLabel(AppLocalizations s, WeatherKind kind) => switch (kind) {
  WeatherKind.clear => s.weatherKindClear,
  WeatherKind.partlyCloudy => s.weatherKindPartlyCloudy,
  WeatherKind.cloudy => s.weatherKindCloudy,
  WeatherKind.rain => s.weatherKindRain,
  WeatherKind.snow => s.weatherKindSnow,
  WeatherKind.thunderstorm => s.weatherKindThunderstorm,
};

/// Piktogram cuaca Meteocons (MIT) untuk beranda.
///
/// [animate] `false` menampilkan bingkai pertama sebagai piktogram diam; ini
/// yang dipakai untuk daftar 12 jam agar tidak ada belasan gerak abadi di satu
/// layar. [animate] `true` memutar satu kali lalu berhenti, bukan memutar tanpa
/// henti. Saat pengguna meminta "kurangi gerakan" atau aset gagal dimuat, tampil
/// ikon Material statis.
class WeatherAnimation extends StatelessWidget {
  const WeatherAnimation({
    required this.kind,
    this.size = RwSize.touch,
    this.animate = false,
    super.key,
  });

  final WeatherKind kind;
  final double size;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(
      weatherIconFor(kind),
      color: RwColors.lime500,
      size: size * _fallbackIconRatio,
    );
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Lottie.asset(
      weatherAnimationAsset(kind),
      width: size,
      height: size,
      animate: animate && !reducedMotion,
      controller: reducedMotion || !animate
          ? const AlwaysStoppedAnimation<double>(0.5)
          : null,
      repeat: false,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}
