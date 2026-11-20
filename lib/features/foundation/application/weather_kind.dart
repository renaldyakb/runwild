/// Tampilan cuaca ringkas untuk memilih animasi di beranda.
///
/// Kode masukan mengikuti kode cuaca WMO yang dipakai Open-Meteo.
enum WeatherKind { clear, partlyCloudy, cloudy, rain, snow, thunderstorm }

/// Kode WMO salju: hujan salju, butiran salju, dan hujan salju lokal.
const snowWeatherCodes = {71, 73, 75, 77, 85, 86};

/// Kode WMO hujan: gerimis, hujan, hujan beku, dan hujan lokal.
const rainWeatherCodes = {51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82};

/// Kode WMO badai guntur, termasuk varian yang disertai hujan es.
const thunderstormWeatherCodes = {95, 96, 99};

/// Kode WMO langit tertutup dan kabut.
const cloudWeatherCodes = {3, 45, 48};

/// Mengelompokkan kode cuaca WMO menjadi salah satu tampilan cuaca.
///
/// `0` cerah dan `1`–`2` berawan sebagian. Kode yang tidak dikenal menjadi
/// mendung supaya tampilan tidak pernah kosong.
WeatherKind weatherKindFor(int code) {
  if (code == 0) return WeatherKind.clear;
  if (code == 1 || code == 2) return WeatherKind.partlyCloudy;
  if (snowWeatherCodes.contains(code)) return WeatherKind.snow;
  if (thunderstormWeatherCodes.contains(code)) return WeatherKind.thunderstorm;
  if (rainWeatherCodes.contains(code)) return WeatherKind.rain;
  if (cloudWeatherCodes.contains(code)) return WeatherKind.cloudy;
  return WeatherKind.cloudy;
}

/// Peluang hujan (persen) yang dianggap cukup untuk menandai satu jam sebagai
/// jam basah walau kode cuacanya belum menyebut hujan.
const rainLikelyThreshold = 50;

/// Jam basah: kode cuacanya hujan/salju/badai guntur, atau peluang hujannya
/// tinggi. Dipakai untuk menyimpulkan "hujan diperkirakan pukul ..." tanpa
/// menampilkan angka mentah ke pengguna.
bool isWetHour(int code, int probability) {
  final kind = weatherKindFor(code);
  if (kind == WeatherKind.rain ||
      kind == WeatherKind.snow ||
      kind == WeatherKind.thunderstorm) {
    return true;
  }
  return probability >= rainLikelyThreshold;
}

/// Berkas animasi Lottie untuk tiap tampilan cuaca.
///
/// Sumber aset: Meteocons oleh Bas Milius (lisensi MIT),
/// https://github.com/basmilius/meteocons — diambil dari paket npm
/// `@meteocons/lottie` versi 0.1.0 gaya `fill`. Salinan lisensi ada di
/// `assets/lottie/meteocons/LICENSE.txt`.
String weatherAnimationAsset(WeatherKind kind) => switch (kind) {
  WeatherKind.clear => 'assets/lottie/meteocons/clear-day.json',
  WeatherKind.partlyCloudy => 'assets/lottie/meteocons/partly-cloudy-day.json',
  WeatherKind.cloudy => 'assets/lottie/meteocons/cloudy.json',
  WeatherKind.rain => 'assets/lottie/meteocons/rain.json',
  WeatherKind.snow => 'assets/lottie/meteocons/snow.json',
  WeatherKind.thunderstorm => 'assets/lottie/meteocons/thunderstorms.json',
};
