import 'package:flutter/material.dart';
import 'package:superellipse_shape/superellipse_shape.dart';
import '../services/smart_notification_service.dart';
import '../theme/app_theme.dart';
import '../utils/l10n_extension.dart';

// ---------------------------------------------------------------------------
// NotificationPreferencesScreen
// ---------------------------------------------------------------------------
class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  Map<String, bool> _prefs = {};
  bool _loading = true;
  bool _saving  = false;

  // Metadata for each preference row
  static const List<_PrefMeta> _prefMeta = [
    _PrefMeta(
      key:      'weaknessPractice',
      icon:     Icons.fitness_center_rounded,
      gradient: [Color(0xFF1A3A08), Color(0xFF4E8A18)],
    ),
    _PrefMeta(
      key:      'incompleteRound',
      icon:     Icons.sports_golf_rounded,
      gradient: [Color(0xFF0D2B40), Color(0xFF1565C0)],
    ),
    _PrefMeta(
      key:      'performanceTrend',
      icon:     Icons.trending_up_rounded,
      gradient: [Color(0xFF2E1760), Color(0xFF6A35C8)],
    ),
    _PrefMeta(
      key:      'teeTimeReminder',
      icon:     Icons.schedule_rounded,
      gradient: [Color(0xFF3D1A08), Color(0xFFE65100)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SmartNotificationService.loadPreferences();
    if (mounted) setState(() { _prefs = prefs; _loading = false; });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await SmartNotificationService.savePreferences(_prefs);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.notifPrefsSaved),
          backgroundColor: AppColors.of(context).accent,
          behavior: SnackBarBehavior.floating,
          shape: SuperellipseShape(borderRadius: BorderRadius.circular(24)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _titleForKey(BuildContext context, String key) {
    switch (key) {
      case 'weaknessPractice':   return context.l10n.notifPrefsPracticeReminders;
      case 'incompleteRound':    return context.l10n.notifPrefsResumeRound;
      case 'performanceTrend':   return context.l10n.notifPrefsPerformance;
      case 'teeTimeReminder':    return context.l10n.notifPrefsTeeTime;
      default:                   return key;
    }
  }

  String _subtitleForKey(BuildContext context, String key) {
    switch (key) {
      case 'weaknessPractice':   return context.l10n.notifPrefsPracticeDesc;
      case 'incompleteRound':    return context.l10n.notifPrefsResumeDesc;
      case 'performanceTrend':   return context.l10n.notifPrefsPerformanceDesc;
      case 'teeTimeReminder':    return context.l10n.notifPrefsTeeTimeDesc;
      default:                   return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c  = AppColors.of(context);
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: c.scaffoldBg,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: c.bgGradient,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(c, sw, sh),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildContent(c, sw, sh),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(AppColors c, double sw, double sh) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          (sw * 0.055).clamp(18.0, 28.0), sh * 0.016,
          (sw * 0.055).clamp(18.0, 28.0), 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: (sw * 0.095).clamp(34.0, 44.0),
              height: (sw * 0.095).clamp(34.0, 44.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.iconContainerBg,
                border: Border.all(color: c.iconContainerBorder),
              ),
              child: Icon(Icons.arrow_back_rounded,
                  color: c.iconColor,
                  size: (sw * 0.048).clamp(16.0, 22.0)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.notifPrefsTitle,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      color: c.primaryText,
                      fontSize: (sw * 0.05).clamp(17.0, 22.0),
                      fontWeight: FontWeight.w800,
                    )),
                Text(context.l10n.notifPrefsSubtitle,
                    style: TextStyle(
                      color: c.secondaryText,
                      fontSize: (sw * 0.030).clamp(11.0, 13.0),
                    )),
              ],
            ),
          ),
          if (_saving)
            SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(c.accent),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(AppColors c, double sw, double sh) {
    final hPad = (sw * 0.055).clamp(18.0, 28.0);
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: sh * 0.024),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero banner
          _buildHeroBanner(c, sw, sh),
          SizedBox(height: sh * 0.028),

          // Section label
          Text(
            context.l10n.notifPrefsSectionTitle,
            style: TextStyle(
              color: c.tertiaryText,
              fontSize: (sw * 0.028).clamp(10.0, 12.0),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          SizedBox(height: sh * 0.014),

          // Preference rows
          Container(
            decoration: ShapeDecoration(
              color: c.cardBg,
              shape: SuperellipseShape(
                borderRadius: BorderRadius.circular(48),
                side: BorderSide(color: c.cardBorder),
              ),
              shadows: c.cardShadow,
            ),
            child: Column(
              children: _prefMeta.asMap().entries.map((entry) {
                final i    = entry.key;
                final meta = entry.value;
                final isLast = i == _prefMeta.length - 1;
                return _buildPrefRow(c, sw, sh, meta, isLast);
              }).toList(),
            ),
          ),
          SizedBox(height: sh * 0.028),

          // Save button
          _buildSaveButton(c, sw, sh),
          SizedBox(height: sh * 0.012),

          // Footer note
          Center(
            child: Text(
              context.l10n.notifPrefsPersonalised,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.tertiaryText,
                fontSize: (sw * 0.028).clamp(10.0, 12.0),
                height: 1.5,
              ),
            ),
          ),
          SizedBox(height: sh * 0.02),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(AppColors c, double sw, double sh) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all((sw * 0.055).clamp(18.0, 24.0)),
      decoration: ShapeDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A3A08), Color(0xFF3D6E14), Color(0xFF4E8A18)],
          stops: [0.0, 0.55, 1.0],
        ),
        shape: SuperellipseShape(borderRadius: BorderRadius.circular(40)),
        shadows: const [
          BoxShadow(
            color: Color(0x3C4E8A18),
            blurRadius: 24,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.notifPrefsAIDriven,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: (sw * 0.030).clamp(11.0, 13.0),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    )),
                const SizedBox(height: 4),
                Text(context.l10n.notifPrefsSmartDesc,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      color: Colors.white,
                      fontSize: (sw * 0.048).clamp(17.0, 22.0),
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    )),
                const SizedBox(height: 10),
                Text(
                  context.l10n.notifPrefsExplanation,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: (sw * 0.030).clamp(11.0, 13.0),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.notifications_active_rounded,
                color: Colors.white, size: 26),
          ),
        ],
      ),
    );
  }

  Widget _buildPrefRow(AppColors c, double sw, double sh, _PrefMeta meta,
      bool isLast) {
    final value = _prefs[meta.key] ?? true;
    return GestureDetector(
      onTap: () => setState(() => _prefs[meta.key] = !value),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: (sw * 0.045).clamp(14.0, 20.0),
          vertical: (sh * 0.018).clamp(12.0, 18.0),
        ),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: c.divider)),
        ),
        child: Row(
          children: [
            // Icon container with gradient
            Container(
              width: (sw * 0.11).clamp(38.0, 48.0),
              height: (sw * 0.11).clamp(38.0, 48.0),
              decoration: ShapeDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: value
                      ? meta.gradient
                      : [c.divider, c.divider],
                ),
                shape: SuperellipseShape(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Icon(meta.icon,
                  color: value
                      ? Colors.white
                      : c.tertiaryText,
                  size: (sw * 0.055).clamp(18.0, 24.0)),
            ),
            const SizedBox(width: 14),
            // Label
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_titleForKey(context, meta.key),
                      style: TextStyle(
                        color: c.primaryText,
                        fontSize: (sw * 0.038).clamp(13.0, 16.0),
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: 2),
                  Text(_subtitleForKey(context, meta.key),
                      style: TextStyle(
                        color: c.secondaryText,
                        fontSize: (sw * 0.030).clamp(11.0, 13.0),
                        height: 1.4,
                      )),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Toggle
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 28,
              decoration: ShapeDecoration(
                color: value ? c.accent : c.divider,
                shape: SuperellipseShape(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(AppColors c, double sw, double sh) {
    return SizedBox(
      width: double.infinity,
      height: (sh * 0.068).clamp(48.0, 60.0),
      child: ElevatedButton(
        onPressed: _saving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: c.accent.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: _saving
            ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Text(context.l10n.notifPrefsSave,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: (sw * 0.042).clamp(15.0, 18.0),
                  fontWeight: FontWeight.w700,
                )),
      ),
    );
  }

}

// ---------------------------------------------------------------------------
// _PrefMeta — immutable metadata for a preference row
// ---------------------------------------------------------------------------
class _PrefMeta {
  final String key;
  final IconData icon;
  final List<Color> gradient;

  const _PrefMeta({
    required this.key,
    required this.icon,
    required this.gradient,
  });
}
