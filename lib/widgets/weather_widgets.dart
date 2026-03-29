import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:superellipse_shape/superellipse_shape.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Icon helpers
// ---------------------------------------------------------------------------

/// Maps a weather condition string to a Material icon.
IconData _conditionIcon(String condition) {
  final lower = condition.toLowerCase();
  if (lower.contains('thunder')) return Icons.thunderstorm_rounded;
  if (lower.contains('rain') || lower.contains('shower') || lower.contains('drizzle')) {
    return Icons.grain_rounded;
  }
  if (lower.contains('snow') || lower.contains('sleet') || lower.contains('flurr')) {
    return Icons.ac_unit_rounded;
  }
  if (lower.contains('fog') || lower.contains('mist') || lower.contains('haze')) {
    return Icons.blur_on_rounded;
  }
  if (lower.contains('partly') || lower.contains('mostly')) {
    return Icons.cloud_queue_rounded;
  }
  if (lower.contains('overcast') || lower.contains('cloud')) {
    return Icons.cloud_rounded;
  }
  return Icons.wb_sunny_rounded; // clear / sunny
}

Color _conditionColor(String condition) {
  final lower = condition.toLowerCase();
  if (lower.contains('thunder')) return const Color(0xFFFFB74D);
  if (lower.contains('rain') || lower.contains('shower') || lower.contains('drizzle')) {
    return const Color(0xFF64B5F6);
  }
  if (lower.contains('snow') || lower.contains('sleet')) {
    return const Color(0xFF90CAF9);
  }
  if (lower.contains('fog') || lower.contains('mist')) return const Color(0xFFB0BEC5);
  if (lower.contains('partly') || lower.contains('cloud')) {
    return const Color(0xFF80DEEA);
  }
  return const Color(0xFFFFD54F); // sunny / clear
}

// ---------------------------------------------------------------------------
// SmallWeatherCard — home screen weather block
// ---------------------------------------------------------------------------

class SmallWeatherCard extends StatefulWidget {
  final double? lat;
  final double? lng;

  const SmallWeatherCard({super.key, this.lat, this.lng});

  @override
  State<SmallWeatherCard> createState() => _SmallWeatherCardState();
}

class _SmallWeatherCardState extends State<SmallWeatherCard> {
  WeatherNow? _weather;
  bool _loading = true;
  bool _error = false;

  // Coords used for the last completed fetch
  double? _lastFetchedLat;
  double? _lastFetchedLng;

  @override
  void initState() {
    super.initState();
    _fetch(); // Always fetch on init; null coords → WeatherService uses IP fallback
  }

  @override
  void didUpdateWidget(SmallWeatherCard old) {
    super.didUpdateWidget(old);
    final newLat = widget.lat;
    final newLng = widget.lng;
    if (newLat == null && newLng == null) return;

    final prevLat = _lastFetchedLat;
    final prevLng = _lastFetchedLng;

    if (prevLat == null || prevLng == null) {
      // Previous fetch used IP-based (null) coords — now we have real coords
      setState(() { _loading = true; _error = false; });
      _fetch();
      return;
    }

    // Re-fetch when user explicitly picks a new location (>0.05° ≈ ~5 km).
    // Ignores GPS precision drift which is typically < 0.001°.
    if (newLat == null || newLng == null) return;
    final latDiff = (newLat - prevLat).abs();
    final lngDiff = (newLng - prevLng).abs();
    if (latDiff > 0.05 || lngDiff > 0.05) {
      setState(() { _loading = true; _error = false; });
      _fetch();
    }
  }

  Future<void> _fetch() async {
    _lastFetchedLat = widget.lat;
    _lastFetchedLng = widget.lng;
    try {
      final w = await WeatherService.getCurrentWeather(widget.lat, widget.lng);
      if (!mounted) return;
      setState(() { _weather = w; _loading = false; _error = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; _error = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c   = AppColors.of(context);
    final sw  = MediaQuery.of(context).size.width;
    final hPad = (sw * 0.055).clamp(18.0, 28.0);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Container(
        decoration: ShapeDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F3460), Color(0xFF16213E), Color(0xFF1A2A4A)],
            stops: [0.0, 0.5, 1.0],
          ),
          shape: SuperellipseShape(borderRadius: BorderRadius.circular(32)),
          shadows: [
            BoxShadow(
              color: const Color(0xFF0F3460).withValues(alpha: 0.30),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(
          horizontal: (sw * 0.052).clamp(14.0, 20.0),
          vertical: (sw * 0.038).clamp(12.0, 16.0),
        ),
        child: _loading
            ? _buildSkeleton(c)
            : _error || _weather == null
                ? _buildError(c, sw)
                : _buildContent(c, sw, _weather!),
      ),
    );
  }

  Widget _buildContent(AppColors c, double sw, WeatherNow w) {
    final label    = (sw * 0.030).clamp(11.0, 13.0);
    final iconSize = (sw * 0.122).clamp(42.0, 52.0);
    final icon     = _conditionIcon(w.condition);
    final color    = _conditionColor(w.condition);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ── Background decorative icon ─────────────────────────────────────
        Positioned(
          right: -8,
          top: -14,
          child: Icon(
            icon,
            size: (sw * 0.38).clamp(120.0, 150.0),
            color: color.withValues(alpha: 0.07),
          ),
        ),

        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Left: weather icon ────────────────────────────────────────
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.30)),
              ),
              child: Icon(icon, color: color, size: iconSize * 0.50),
            ),
            SizedBox(width: (sw * 0.030).clamp(8.0, 14.0)),

            // ── Centre: temp + condition + summary ────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    w.tempLabel,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      color: Colors.white,
                      fontSize: (sw * 0.060).clamp(20.0, 26.0),
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    w.condition,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: label,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    w.conditionSummary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color.withValues(alpha: 0.90),
                      fontSize: label,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: (sw * 0.020).clamp(6.0, 10.0)),

            // ── Right: wind ───────────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: (sw * 0.022).clamp(7.0, 10.0),
                    vertical: 4,
                  ),
                  decoration: ShapeDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: SuperellipseShape(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.air_rounded,
                          color: const Color(0xFF80DEEA), size: label),
                      const SizedBox(width: 4),
                      Text(
                        w.windLabel,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: label,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Today',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.40),
                    fontSize: label * 0.88,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSkeleton(AppColors c) {
    // Mirrors _buildContent layout exactly:
    // [circle icon] [temp block + condition line] [wind pill + "Today"]
    return LayoutBuilder(
      builder: (context, constraints) {
        final sw       = MediaQuery.of(context).size.width;
        final iconSize = (sw * 0.122).clamp(42.0, 52.0);
        final tempH    = (sw * 0.060).clamp(20.0, 26.0) * 1.1; // matches font size × height
        final labelH   = (sw * 0.030).clamp(11.0, 13.0);

        return Shimmer.fromColors(
          baseColor:      Colors.white.withValues(alpha: 0.08),
          highlightColor: Colors.white.withValues(alpha: 0.20),
          period: const Duration(milliseconds: 1400),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: circular weather icon placeholder
              _sBox(iconSize, iconSize, circular: true),
              SizedBox(width: (sw * 0.030).clamp(8.0, 14.0)),

              // Centre: temp + condition + summary
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Temp label (large) + condition text (inline)
                    Row(
                      children: [
                        _sBox((sw * 0.18).clamp(60.0, 80.0), tempH),
                        const SizedBox(width: 8),
                        _sBox((sw * 0.22).clamp(70.0, 100.0), labelH),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Summary line
                    _sBox((sw * 0.32).clamp(100.0, 140.0), labelH),
                  ],
                ),
              ),

              SizedBox(width: (sw * 0.020).clamp(6.0, 10.0)),

              // Right: wind pill + "Today" label
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Wind pill
                  _sBox((sw * 0.20).clamp(64.0, 84.0), labelH + 8,
                      radius: 20),
                  const SizedBox(height: 6),
                  // "Today" label
                  _sBox((sw * 0.10).clamp(32.0, 44.0), labelH * 0.88),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Solid shimmer placeholder block — colour applied by Shimmer.fromColors above.
  Widget _sBox(double w, double h,
      {bool circular = false, double radius = 6}) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: circular ? null : BorderRadius.circular(radius),
        shape: circular ? BoxShape.circle : BoxShape.rectangle,
      ),
    );
  }

  Widget _buildError(AppColors c, double sw) {
    final label = (sw * 0.030).clamp(11.0, 13.0);
    return Row(
      children: [
        Icon(Icons.cloud_off_rounded,
            color: Colors.white.withValues(alpha: 0.40), size: 24),
        const SizedBox(width: 10),
        Text(
          'Weather unavailable',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.50),
            fontSize: label,
          ),
        ),
      ],
    );
  }


}

// ---------------------------------------------------------------------------
// RoundWeatherTopBar — compact strip for start_round_screen
// ---------------------------------------------------------------------------

class RoundWeatherTopBar extends StatefulWidget {
  final double? lat;
  final double? lng;

  const RoundWeatherTopBar({super.key, this.lat, this.lng});

  @override
  State<RoundWeatherTopBar> createState() => _RoundWeatherTopBarState();
}

class _RoundWeatherTopBarState extends State<RoundWeatherTopBar> {
  WeatherNow? _weather;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final w = await WeatherService.getCurrentWeather(widget.lat, widget.lng);
      if (!mounted) return;
      setState(() { _weather = w; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c   = AppColors.of(context);
    final sw  = MediaQuery.of(context).size.width;
    final label = (sw * 0.030).clamp(11.0, 13.0);

    if (_loading) {
      return Container(
        height: 32,
        width: 120,
        decoration: ShapeDecoration(
          color: c.accentBg,
          shape: SuperellipseShape(borderRadius: BorderRadius.circular(20)),
        ),
      );
    }

    final w = _weather;
    if (w == null) return const SizedBox.shrink();

    final icon  = _conditionIcon(w.condition);
    final color = _conditionColor(w.condition);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (sw * 0.03).clamp(10.0, 12.0),
        vertical: (sw * 0.015).clamp(5.0, 6.0),
      ),
      decoration: ShapeDecoration(
        color: c.cardBg,
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: c.cardBorder),
        ),
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: label * 1.15),
          SizedBox(width: (sw * 0.012).clamp(4.0, 5.0)),
          Text(
            w.tempLabel,
            style: TextStyle(
              fontFamily: 'Nunito',
              color: c.primaryText,
              fontSize: label,
              fontWeight: FontWeight.w700,
            ),
          ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: (sw * 0.017).clamp(5.0, 7.0),
              ),
              child: Text(
                '|',
                style: TextStyle(
                  color: c.divider,
                  fontSize: label,
                ),
              ),
            ),
            Icon(Icons.air_rounded,
                color: const Color(0xFF64B5F6), size: label * 1.1),
            SizedBox(width: (sw * 0.01).clamp(3.0, 4.0)),
            Text(
              w.windLabel,
              style: TextStyle(
                color: c.secondaryText,
                fontSize: label,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
    );
  }
}

// ---------------------------------------------------------------------------
// RoundConditionsCard — round detail screen weather summary
// ---------------------------------------------------------------------------

class RoundConditionsCard extends StatefulWidget {
  /// Pass existing WeatherData from the round so no network call is needed.
  final WeatherData? existingWeather;

  const RoundConditionsCard({super.key, this.existingWeather});

  @override
  State<RoundConditionsCard> createState() => _RoundConditionsCardState();
}

class _RoundConditionsCardState extends State<RoundConditionsCard> {
  RoundWeatherSummary? _summary;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final s = await WeatherService.getRoundWeatherSummary(widget.existingWeather);
    if (!mounted) return;
    setState(() { _summary = s; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final c   = AppColors.of(context);
    final sw  = MediaQuery.of(context).size.width;
    final sh  = MediaQuery.of(context).size.height;
    final body  = (sw * 0.036).clamp(13.0, 16.0);
    final label = (sw * 0.030).clamp(11.0, 13.0);

    if (_loading) return _buildSkeleton(c, sw, sh);
    if (_summary == null) return const SizedBox.shrink();

    final s     = _summary!;
    final icon  = _conditionIcon(s.dominantCondition);
    final color = _conditionColor(s.dominantCondition);

    return Container(
      decoration: ShapeDecoration(
        color: c.cardBg,
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(32),
          side: BorderSide(color: c.cardBorder),
        ),
        shadows: c.cardShadow,
      ),
      padding: EdgeInsets.all((sw * 0.048).clamp(14.0, 20.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section label ─────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                'Round Conditions',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  color: c.primaryText,
                  fontSize: body,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          SizedBox(height: sh * 0.014),

          // ── Stat chips row ────────────────────────────────────────────────
          Row(
            children: [
              _chip(
                c: c,
                icon: Icons.thermostat_rounded,
                iconColor: const Color(0xFFFF8A65),
                label: s.tempLabel,
                sub: 'Avg Temp',
                body: body,
                lbl: label,
              ),
              SizedBox(width: (sw * 0.030).clamp(8.0, 14.0)),
              _chip(
                c: c,
                icon: Icons.air_rounded,
                iconColor: const Color(0xFF64B5F6),
                label: s.windLabel,
                sub: 'Avg Wind',
                body: body,
                lbl: label,
              ),
              SizedBox(width: (sw * 0.030).clamp(8.0, 14.0)),
              Expanded(
                flex: 2,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: (sw * 0.032).clamp(10.0, 14.0),
                    vertical: (sw * 0.028).clamp(9.0, 13.0),
                  ),
                  decoration: ShapeDecoration(
                    color: c.accentBg,
                    shape: SuperellipseShape(
                      borderRadius: BorderRadius.circular(28),
                      side: BorderSide(color: c.accentBorder),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, color: color, size: body),
                      const SizedBox(height: 4),
                      Text(
                        s.dominantCondition,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          color: c.primaryText,
                          fontSize: label,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Conditions',
                        style: TextStyle(
                          color: c.tertiaryText,
                          fontSize: label * 0.88,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: sh * 0.012),

          // ── Summary sentence ──────────────────────────────────────────────
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: (sw * 0.036).clamp(11.0, 16.0),
              vertical: 10,
            ),
            decoration: ShapeDecoration(
              color: c.iconContainerBg,
              shape: SuperellipseShape(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: c.iconContainerBorder),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: c.accent, size: label * 1.1),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.summaryText,
                    style: TextStyle(
                      color: c.secondaryText,
                      fontSize: label,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required AppColors c,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String sub,
    required double body,
    required double lbl,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 10,
          vertical: (lbl * 0.7).clamp(8.0, 12.0),
        ),
        decoration: ShapeDecoration(
          color: c.iconContainerBg,
          shape: SuperellipseShape(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: c.iconContainerBorder),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: body * 0.92),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                color: c.primaryText,
                fontSize: lbl,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              sub,
              style: TextStyle(
                color: c.tertiaryText,
                fontSize: lbl * 0.88,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton(AppColors c, double sw, double sh) {
    return Container(
      decoration: ShapeDecoration(
        color: c.cardBg,
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(32),
          side: BorderSide(color: c.cardBorder),
        ),
        shadows: c.cardShadow,
      ),
      padding: EdgeInsets.all((sw * 0.048).clamp(14.0, 20.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _shimmer(30, 30, circular: true),
              const SizedBox(width: 10),
              _shimmer(120, 16),
            ],
          ),
          SizedBox(height: sh * 0.014),
          Row(
            children: [
              Expanded(child: _shimmer(double.infinity, 60)),
              const SizedBox(width: 10),
              Expanded(child: _shimmer(double.infinity, 60)),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: _shimmer(double.infinity, 60)),
            ],
          ),
          SizedBox(height: sh * 0.012),
          _shimmer(double.infinity, 40),
        ],
      ),
    );
  }

  Widget _shimmer(double w, double h, {bool circular = false}) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: const Color(0xFF7BC344).withValues(alpha: 0.06),
          borderRadius: circular ? null : BorderRadius.circular(8),
          shape: circular ? BoxShape.circle : BoxShape.rectangle,
        ),
      );
}

// ---------------------------------------------------------------------------
// TeeTimeWeatherPreview — forecast slot widget (reusable standalone)
// ---------------------------------------------------------------------------

class TeeTimeWeatherPreview extends StatelessWidget {
  final WeatherForecast forecast;

  const TeeTimeWeatherPreview({super.key, required this.forecast});

  @override
  Widget build(BuildContext context) {
    final c     = AppColors.of(context);
    final sw    = MediaQuery.of(context).size.width;
    final body  = (sw * 0.036).clamp(13.0, 16.0);
    final label = (sw * 0.030).clamp(11.0, 13.0);
    final icon  = _conditionIcon(forecast.condition);
    final color = _conditionColor(forecast.condition);

    final hour = forecast.time.hour;
    final ampm = hour < 12 ? 'AM' : 'PM';
    final h12  = hour % 12 == 0 ? 12 : hour % 12;
    final timeLabel = '$h12:00 $ampm';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (sw * 0.040).clamp(12.0, 18.0),
        vertical: (sw * 0.032).clamp(10.0, 14.0),
      ),
      decoration: ShapeDecoration(
        color: c.cardBg,
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(36),
          side: BorderSide(color: c.cardBorder),
        ),
        shadows: c.cardShadow,
      ),
      child: Column(
        children: [
          Text(
            timeLabel,
            style: TextStyle(
              color: c.tertiaryText,
              fontSize: label * 0.9,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Icon(icon, color: color, size: body * 1.4),
          const SizedBox(height: 6),
          Text(
            forecast.tempLabel,
            style: TextStyle(
              fontFamily: 'Nunito',
              color: c.primaryText,
              fontSize: body,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            forecast.windLabel,
            style: TextStyle(
              color: c.secondaryText,
              fontSize: label * 0.88,
            ),
          ),
        ],
      ),
    );
  }
}
