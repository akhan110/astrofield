import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/field_models.dart';

class WeatherHour {
  const WeatherHour(this.time, this.cloud, this.temperature, this.humidity,
      this.wind, this.precipitation);
  final DateTime time;
  final double? cloud, temperature, humidity, wind, precipitation;
  Map<String, Object?> toJson() => {
        'time': time.toIso8601String(),
        'cloud': cloud,
        'temperature': temperature,
        'humidity': humidity,
        'wind': wind,
        'precipitation': precipitation
      };
  factory WeatherHour.fromJson(Map<String, dynamic> j) => WeatherHour(
      DateTime.parse(j['time'] as String),
      (j['cloud'] as num?)?.toDouble(),
      (j['temperature'] as num?)?.toDouble(),
      (j['humidity'] as num?)?.toDouble(),
      (j['wind'] as num?)?.toDouble(),
      (j['precipitation'] as num?)?.toDouble());
}

class WeatherCache {
  const WeatherCache(this.site, this.downloaded, this.hours);
  final Site site;
  final DateTime downloaded;
  final List<WeatherHour> hours;
  bool get stale =>
      DateTime.now().toUtc().difference(downloaded) > const Duration(hours: 6);
  bool matches(Site s) =>
      (s.latitude - site.latitude).abs() < .01 &&
      (s.longitude - site.longitude).abs() < .01;
  Map<String, Object?> toJson() => {
        'site': site.toJson(),
        'downloaded': downloaded.toIso8601String(),
        'hours': hours.map((h) => h.toJson()).toList(),
        'source': 'Open-Meteo',
        'sourceIssuedAt': null
      };
  factory WeatherCache.fromJson(Map<String, dynamic> j) => WeatherCache(
      Site.fromJson(j['site'] as Map<String, dynamic>),
      DateTime.parse(j['downloaded'] as String),
      (j['hours'] as List)
          .map((h) => WeatherHour.fromJson(h as Map<String, dynamic>))
          .toList());
}

class WeatherService {
  Future<WeatherCache> fetch(Site site) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '${site.latitude}',
      'longitude': '${site.longitude}',
      'hourly':
          'temperature_2m,relative_humidity_2m,cloud_cover,wind_speed_10m,precipitation_probability',
      'timezone': 'UTC',
      'forecast_days': '7'
    });
    final response = await http.get(uri).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw StateError('Weather service returned ${response.statusCode}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final hourly = json['hourly'] as Map<String, dynamic>;
    final times = hourly['time'] as List;
    double? number(String key, int i) =>
        ((hourly[key] as List)[i] as num?)?.toDouble();
    final hours = List.generate(
        times.length,
        (i) => WeatherHour(
            DateTime.parse('${times[i]}Z'),
            number('cloud_cover', i),
            number('temperature_2m', i),
            number('relative_humidity_2m', i),
            number('wind_speed_10m', i),
            number('precipitation_probability', i)));
    if (hours.isEmpty) throw StateError('Empty weather forecast');
    return WeatherCache(site, DateTime.now().toUtc(), hours);
  }
}
