import 'dart:convert';
import 'package:http/http.dart' as http;

// Free tier: 1000 calls/day — https://openweathermap.org/api
// Sign up at openweathermap.org and replace with your API key.
const _owmKey = 'YOUR_OPENWEATHERMAP_API_KEY';

class WeatherData {
  final double tempF;
  final String condition; // e.g. "Partly Cloudy"
  final double windMph;
  final String windDir;   // e.g. "NW"
  final String icon;      // OWM icon code e.g. "02d"

  const WeatherData({
    required this.tempF,
    required this.condition,
    required this.windMph,
    required this.windDir,
    required this.icon,
  });

  String get iconUrl => 'https://openweathermap.org/img/wn/$icon@2x.png';

  Map<String, dynamic> toMap() => {
    'tempF': tempF,
    'condition': condition,
    'windMph': windMph,
    'windDir': windDir,
    'icon': icon,
  };

  factory WeatherData.fromMap(Map<String, dynamic> m) => WeatherData(
    tempF: (m['tempF'] as num).toDouble(),
    condition: m['condition'] as String,
    windMph: (m['windMph'] as num).toDouble(),
    windDir: m['windDir'] as String,
    icon: m['icon'] as String,
  );
}

class WeatherService {
  static Future<WeatherData?> fetchWeather(double lat, double lng) async {
    if (_owmKey == 'YOUR_OPENWEATHERMAP_API_KEY') return null;
    try {
      final uri = Uri.https('api.openweathermap.org', '/data/2.5/weather', {
        'lat': '$lat',
        'lon': '$lng',
        'units': 'imperial',
        'appid': _owmKey,
      });
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return null;
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      final wind = j['wind'] as Map<String, dynamic>;
      final main = j['main'] as Map<String, dynamic>;
      final weather = (j['weather'] as List).first as Map<String, dynamic>;
      return WeatherData(
        tempF: (main['temp'] as num).toDouble(),
        condition: weather['description'].toString().split(' ').map((w) =>
            w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w).join(' '),
        windMph: (wind['speed'] as num).toDouble(),
        windDir: _degToDir((wind['deg'] as num?)?.toInt() ?? 0),
        icon: weather['icon'] as String,
      );
    } catch (_) {
      return null;
    }
  }

  static String _degToDir(int deg) {
    const dirs = ['N','NE','E','SE','S','SW','W','NW'];
    return dirs[((deg + 22.5) / 45).floor() % 8];
  }
}
