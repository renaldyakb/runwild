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
        '${position.latitude.toStringAsFixed(2)},${position.longitude.toStringAsFixed(2)}';
    if (_cityCache.containsKey(cityKey)) {
      return WeatherForecast(
        forecast.temperature,
        forecast.code,
        forecast.hourly,
        city: _cityCache[cityKey],
      );
    }
    String? city;
    try {
      final request = await client
          .getUrl(
            Uri.https('nominatim.openstreetmap.org', '/reverse', {
              'lat': position.latitude.toStringAsFixed(2),
              'lon': position.longitude.toStringAsFixed(2),
              'format': 'jsonv2',
              'zoom': '12',
              'accept-language': 'id',
            }),
          )
          .timeout(const Duration(seconds: 8));
      request.headers.set(
        'User-Agent',
        'RUNWILD (https://github.com/renaldyakb/runwild)',
      );
      final response = await request.close().timeout(
        const Duration(seconds: 8),
      );
      if (response.statusCode == 200) {
        city = cityFromReverseJson(
          await response.transform(utf8.decoder).join(),
        );
      }
    } catch (error) {
      city = null;
    }
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

String? cityFromReverseJson(String body) {
  final data = jsonDecode(body) as Map<String, dynamic>;
  final address = data['address'] as Map<String, dynamic>?;
  for (final key in [
    'city',
    'town',
    'municipality',
    'county',
    'state_district',
    'city_district',
    'borough',
    'village',
    'suburb',
  ]) {
    final value = address?[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return null;
}
