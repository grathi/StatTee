import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class WeatherNow {
  final double temperature;
  final double windSpeed;
  final String windDirection;
  final String condition;
  final String iconCode;

  const WeatherNow({
    required this.temperature,
    required this.windSpeed,
    required this.windDirection,
    required this.condition,
    required this.iconCode,
  });

  /// Human-readable wind string, e.g. "10 mph NW"
  String get windLabel => '${windSpeed.round()} mph $windDirection';

  /// Rounded temperature, e.g. "68°F"
  String get tempLabel => '${temperature.round()}°F';

  /// Golf-context summary line
  String get conditionSummary {
    if (windSpeed < 5) {
      return condition.contains('Clear') || condition.contains('Sunny')
          ? 'Ideal conditions today'
          : 'Calm winds today';
    }
    if (windSpeed < 12) return 'Light breeze — great round ahead';
    if (windSpeed < 20) return 'Moderate wind — factor in club selection';
    return 'Windy — play more conservatively';
  }

  Map<String, dynamic> toMap() => {
        'temperature': temperature,
        'windSpeed': windSpeed,
        'windDirection': windDirection,
        'condition': condition,
        'iconCode': iconCode,
      };

  factory WeatherNow.fromMap(Map<String, dynamic> m) => WeatherNow(
        temperature: (m['temperature'] as num).toDouble(),
        windSpeed: (m['windSpeed'] as num).toDouble(),
        windDirection: m['windDirection'] as String,
        condition: m['condition'] as String,
        iconCode: m['iconCode'] as String,
      );

  // Legacy interop — used by Round model which stores WeatherData
  static WeatherNow fromLegacy(WeatherData d) => WeatherNow(
        temperature: d.tempF,
        windSpeed: d.windMph,
        windDirection: d.windDir,
        condition: d.condition,
        iconCode: d.icon,
      );
}

class WeatherForecast {
  final DateTime time;
  final double temperature;
  final double windSpeed;
  final String windDirection;
  final String condition;
  final String iconCode;

  const WeatherForecast({
    required this.time,
    required this.temperature,
    required this.windSpeed,
    required this.windDirection,
    required this.condition,
    required this.iconCode,
  });

  String get tempLabel => '${temperature.round()}°F';
  String get windLabel => '${windSpeed.round()} mph $windDirection';
}

class RoundWeatherSummary {
  final double averageTemperature;
  final double averageWindSpeed;
  final String dominantCondition;
  final String summaryText;

  const RoundWeatherSummary({
    required this.averageTemperature,
    required this.averageWindSpeed,
    required this.dominantCondition,
    required this.summaryText,
  });

  String get tempLabel => '${averageTemperature.round()}°F';
  String get windLabel => '${averageWindSpeed.round()} mph';

  static RoundWeatherSummary fromWeatherData(WeatherData d) {
    final ws = d.windMph;
    final windDesc = ws < 5
        ? 'calm'
        : ws < 12
            ? 'light ${ws.round()} mph'
            : ws < 20
                ? 'moderate ${ws.round()} mph'
                : 'strong ${ws.round()} mph';
    return RoundWeatherSummary(
      averageTemperature: d.tempF,
      averageWindSpeed: d.windMph,
      dominantCondition: d.condition,
      summaryText:
          'Played in ${d.tempF.round()}°F, $windDesc wind, ${d.condition.toLowerCase()}',
    );
  }
}

// ---------------------------------------------------------------------------
// Legacy model — kept for Round/Firestore compatibility
// ---------------------------------------------------------------------------

class WeatherData {
  final double tempF;
  final String condition;
  final double windMph;
  final String windDir;
  final String icon;

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

// ---------------------------------------------------------------------------
// WeatherService
// ---------------------------------------------------------------------------

// Free tier: 1000 calls/day — https://openweathermap.org/api
// Replace with your API key to enable live data.
const _owmKey = 'c04d38a81b386da779acf2f012625abb';

class WeatherService {
  // ── Mock data set ─────────────────────────────────────────────────────────

  static const _mockConditions = [
    ('Clear', '01d'),
    ('Partly Cloudy', '02d'),
    ('Mostly Cloudy', '03d'),
    ('Overcast', '04d'),
    ('Light Rain', '10d'),
    ('Sunny', '01d'),
  ];

  static const _mockDirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];

  // Returns deterministic-looking mock data seeded by hour so it doesn't
  // flicker on each rebuild, but updates naturally as the day progresses.
  static WeatherData _mockWeatherData() {
    final seed = DateTime.now().hour;
    final rng = math.Random(seed);
    final cond = _mockConditions[rng.nextInt(_mockConditions.length)];
    final temp = 58.0 + rng.nextInt(28).toDouble(); // 58–85 °F
    final wind = 3.0 + rng.nextInt(20).toDouble();  // 3–22 mph
    final dir  = _mockDirs[rng.nextInt(_mockDirs.length)];
    return WeatherData(
      tempF:     temp,
      condition: cond.$1,
      windMph:   wind,
      windDir:   dir,
      icon:      cond.$2,
    );
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Current conditions. Falls back to mock if no API key is set.
  static Future<WeatherNow?> getCurrentWeather([
    double? lat,
    double? lng,
  ]) async {
    final data = await fetchWeather(lat ?? 37.3346, lng ?? -122.0090);
    return data != null ? WeatherNow.fromLegacy(data) : null;
  }

  /// Hourly forecast for today (mock: 6 slots, 2 h apart).
  static Future<List<WeatherForecast>> getTodayForecast([
    double? lat,
    double? lng,
  ]) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final now  = DateTime.now();
    final seed = now.hour;
    final rng  = math.Random(seed);
    return List.generate(6, (i) {
      final dt   = now.add(Duration(hours: i * 2));
      final cond = _mockConditions[rng.nextInt(_mockConditions.length)];
      return WeatherForecast(
        time:          dt,
        temperature:   60.0 + rng.nextInt(22).toDouble(),
        windSpeed:     4.0  + rng.nextInt(18).toDouble(),
        windDirection: _mockDirs[rng.nextInt(_mockDirs.length)],
        condition:     cond.$1,
        iconCode:      cond.$2,
      );
    });
  }

  /// Best forecast slot near the given tee time.
  static Future<WeatherForecast?> getTeeTimeForecast(DateTime teeTime) async {
    final slots = await getTodayForecast();
    if (slots.isEmpty) return null;
    return slots.reduce((a, b) =>
        (a.time.difference(teeTime).abs() < b.time.difference(teeTime).abs())
            ? a
            : b);
  }

  /// Summary suitable for the round-detail screen.
  static Future<RoundWeatherSummary?> getRoundWeatherSummary([
    WeatherData? existingData,
  ]) async {
    final data = existingData ?? _mockWeatherData();
    return RoundWeatherSummary.fromWeatherData(data);
  }

  // ── Live OWM fetch (used when API key is present) ─────────────────────────

  static Future<WeatherData?> fetchWeather(double lat, double lng) async {
    if (_owmKey == 'YOUR_OWM_API_KEY') {
      // Return mock data so all UI shows something useful during development
      await Future.delayed(const Duration(milliseconds: 180));
      return _mockWeatherData();
    }
    try {
      final uri = Uri.https('api.openweathermap.org', '/data/2.5/weather', {
        'lat':   '$lat',
        'lon':   '$lng',
        'units': 'imperial',
        'appid': _owmKey,
      });
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return null;
      final j       = jsonDecode(res.body) as Map<String, dynamic>;
      final wind    = j['wind']    as Map<String, dynamic>;
      final main    = j['main']    as Map<String, dynamic>;
      final weather = (j['weather'] as List).first as Map<String, dynamic>;
      return WeatherData(
        tempF:     (main['temp'] as num).toDouble(),
        condition: weather['description']
            .toString()
            .split(' ')
            .map((w) => w.isNotEmpty
                ? '${w[0].toUpperCase()}${w.substring(1)}'
                : w)
            .join(' '),
        windMph: (wind['speed'] as num).toDouble(),
        windDir: _degToDir((wind['deg'] as num?)?.toInt() ?? 0),
        icon:    weather['icon'] as String,
      );
    } catch (_) {
      return null;
    }
  }

  static String _degToDir(int deg) {
    const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    return dirs[((deg + 22.5) / 45).floor() % 8];
  }
}
