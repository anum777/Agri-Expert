import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  final String apiKey;
  WeatherService([this.apiKey = '']);

  Future<Map<String, dynamic>?> fetchWeather(double lat, double lon) async {
    if (apiKey.trim().isNotEmpty) {
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      print(
          'OpenWeather fetch failed (${response.statusCode}): ${response.body}');
    }

    // Fallback provider that does not require an API key.
    final fallbackUrl = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,wind_speed_10m,surface_pressure,cloud_cover&hourly=visibility&timezone=auto',
    );
    final fallbackResponse = await http.get(fallbackUrl);
    if (fallbackResponse.statusCode != 200) {
      print(
        'Open-Meteo fetch failed (${fallbackResponse.statusCode}): ${fallbackResponse.body}',
      );
      return null;
    }

    final data = json.decode(fallbackResponse.body) as Map<String, dynamic>;
    final current =
        (data['current'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final hourly =
        (data['hourly'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final humidity =
        (current['relative_humidity_2m'] as num?)?.toDouble() ?? 0.0;
    final temp = (current['temperature_2m'] as num?)?.toDouble() ?? 0.0;
    final windSpeed = (current['wind_speed_10m'] as num?)?.toDouble() ?? 0.0;
    final pressure = (current['surface_pressure'] as num?)?.toDouble() ?? 0.0;
    final cloudCover = (current['cloud_cover'] as num?)?.toDouble() ?? 0.0;
    final visibilitySeries = (hourly['visibility'] as List?) ?? const [];
    final visibility = visibilitySeries.isNotEmpty
        ? ((visibilitySeries.first as num?)?.toDouble() ?? 10000.0)
        : 10000.0;

    return {
      'main': {
        'temp': temp,
        'humidity': humidity,
        'pressure': pressure,
      },
      'rain': {'1h': 0.0},
      'wind': {'speed': windSpeed},
      'clouds': {'all': cloudCover},
      'visibility': visibility,
      'source': 'open-meteo',
    };
  }
}
