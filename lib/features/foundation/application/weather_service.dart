import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Satu jam prakiraan: waktu lokal, kode cuaca WMO, dan peluang hujan.
///
/// Peluang hujan disimpan sebagai angka tetapi tidak ditampilkan mentah ke
/// pengguna; beranda memakai piktogram cuaca agar lebih mudah dipahami.
class HourlyWeather {
  const HourlyWeather(this.time, this.code, this.probability);

  final DateTime time;
  final int code;
  final int probability;
}

class WeatherForecast {
  const WeatherForecast(this.temperature, this.code, this.hourly, {this.city});

  final String? city;
  final double temperature;
  final int code;
  final List<HourlyWeather> hourly;
}

/// Jumlah jam prakiraan yang diminta dan ditampilkan.
const weatherForecastHours = 12;

final _cityCache = <String, String?>{};

final weatherProvider = FutureProvider.autoDispose<WeatherForecast?>((
  ref,
) async {
  final permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever ||
      !await Geolocator.isLocationServiceEnabled()) {
    return null;
  }
  final position = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.medium,
      timeLimit: Duration(seconds: 15),
    ),
  );
  final client = HttpClient();
  try {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': position.latitude.toString(),
      'longitude': position.longitude.toString(),
      'current': 'temperature_2m,weather_code',
      'hourly': 'weather_code,precipitation_probability',
      'forecast_hours': '$weatherForecastHours',
      'timezone': 'auto',
    });
    final request = await client
        .getUrl(uri)
        .timeout(const Duration(seconds: 15));
    final response = await request.close().timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw const FormatException('Weather unavailable');
    }
    final forecast = parseWeatherForecast(
      await response.transform(utf8.decoder).join(),
    );
    final cityKey =
        '${position.latitude.toStringAsFixed(3)},${position.longitude.toStringAsFixed(3)}';
    if (_cityCache.containsKey(cityKey)) {
      return WeatherForecast(
        forecast.temperature,
        forecast.code,
        forecast.hourly,
        city: _cityCache[cityKey],
      );
    }
    final city = await _resolveCityName(
      client,
      latitude: position.latitude,
      longitude: position.longitude,
    );
    if (city != null) {
      if (_cityCache.length >= 32) _cityCache.clear();
      _cityCache[cityKey] = city;
    }
    return WeatherForecast(
      forecast.temperature,
      forecast.code,
      forecast.hourly,
      city: city,
    );
  } finally {
    client.close();
  }
});

Future<String?> _resolveCityName(
  HttpClient client, {
  required double latitude,
  required double longitude,
}) async {
  final latStr = latitude.toStringAsFixed(3);
  final lonStr = longitude.toStringAsFixed(3);

  // 1. Primary: BigDataCloud Free Reverse Geocode API (akurat untuk kota &
  //    kabupaten Indonesia termasuk daerah seperti Lhokseumawe, tanpa API key).
  try {
    final request = await client
        .getUrl(
          Uri.https('api.bigdatacloud.net', '/data/reverse-geocode-client', {
            'latitude': latStr,
            'longitude': lonStr,
            'localityLanguage': 'id',
          }),
        )
        .timeout(const Duration(seconds: 8));
    final response = await request.close().timeout(const Duration(seconds: 8));
    if (response.statusCode == 200) {
      final resolved = cityFromBigDataCloudJson(
        await response.transform(utf8.decoder).join(),
      );
      if (resolved != null) return resolved;
    }
  } catch (_) {
    // Lanjut ke fallback Nominatim bila layanan pertama tidak merespons.
  }

  // 2. Fallback: OpenStreetMap Nominatim.
  try {
    final request = await client
        .getUrl(
          Uri.https('nominatim.openstreetmap.org', '/reverse', {
            'lat': latStr,
            'lon': lonStr,
            'format': 'jsonv2',
            'zoom': '10',
            'accept-language': 'id',
          }),
        )
        .timeout(const Duration(seconds: 8));
    request.headers.set(
      'User-Agent',
      'RUNWILD (https://github.com/renaldyakb/runwild)',
    );
    final response = await request.close().timeout(const Duration(seconds: 8));
    if (response.statusCode == 200) {
      return cityFromReverseJson(await response.transform(utf8.decoder).join());
    }
  } catch (_) {
    return null;
  }
  return null;
}

WeatherForecast parseWeatherForecast(String body) {
  final data = jsonDecode(body) as Map<String, dynamic>;
  final current = data['current'] as Map<String, dynamic>;
  final hourly = data['hourly'] as Map<String, dynamic>;
  final times = hourly['time'] as List<dynamic>;
  final codes = hourly['weather_code'] as List<dynamic>;
  final probabilities = hourly['precipitation_probability'] as List<dynamic>;
  if (times.length < weatherForecastHours ||
      codes.length != times.length ||
      probabilities.length != times.length) {
    throw const FormatException('Incomplete weather forecast');
  }
  return WeatherForecast(
    (current['temperature_2m'] as num).toDouble(),
    (current['weather_code'] as num).toInt(),
    [
      for (var i = 0; i < weatherForecastHours; i++)
        HourlyWeather(
          DateTime.parse(times[i] as String),
          (codes[i] as num).toInt(),
          (probabilities[i] as num).toInt(),
        ),
    ],
  );
}

String? cityFromBigDataCloudJson(String body) {
  final data = jsonDecode(body) as Map<String, dynamic>;
  final city = data['city'];
  if (city is String && city.trim().isNotEmpty) return city.trim();

  final localityInfo = data['localityInfo'] as Map<String, dynamic>?;
  final admin = localityInfo?['administrative'] as List<dynamic>?;
  if (admin != null) {
    for (final level in [5, 6]) {
      for (final entry in admin) {
        if (entry is Map<String, dynamic> && entry['adminLevel'] == level) {
          final name = entry['name'];
          if (name is String && name.trim().isNotEmpty) return name.trim();
        }
      }
    }
  }

  for (final key in ['locality', 'principalSubdivision']) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return null;
}

String? cityFromReverseJson(String body) {
  final data = jsonDecode(body) as Map<String, dynamic>;
  final address = data['address'] as Map<String, dynamic>?;
  for (final key in [
    'city',
    'town',
    'municipality',
    'county',
    'regency',
    'state_district',
    'city_district',
    'borough',
    'district',
    'village',
    'suburb',
    'hamlet',
    'state',
  ]) {
    final value = address?[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return null;
}
