import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/round_service.dart';
import '../services/stats_service.dart';
import '../services/achievement_service.dart';
import '../services/user_profile_service.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';
import 'package:superellipse_shape/superellipse_shape.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final hPad = (sw * 0.055).clamp(18.0, 28.0);
    final body = (sw * 0.036).clamp(13.0, 16.0);
    final label = (sw * 0.030).clamp(11.0, 13.0);

    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? user?.email ?? 'Golfer';
    final email = user?.email ?? '';
    final initials = _initials(name);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: c.bgGradient,
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(hPad, sh * 0.022, hPad, sh * 0.14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile',
                style: TextStyle(fontFamily: 'Nunito',
                  color: c.primaryText,
                  fontSize: (sw * 0.068).clamp(24.0, 30.0),
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: sh * 0.028),

              // Avatar + name card
              _buildProfileCard(c, sw, sh, body, label, initials, name, email),

              SizedBox(height: sh * 0.022),

              // Stats summary + Achievements
              StreamBuilder(
                stream: RoundService.allCompletedRoundsStream(),
                builder: (context, snap) {
                  final rounds = snap.data ?? [];
                  final stats = StatsService.calculate(rounds);
                  final unlocked = AchievementService.evaluate(stats, rounds);
                  return Column(
                    children: [
                      _buildStatsRow(c, sw, sh, body, label, stats),
                      SizedBox(height: sh * 0.022),
                      _buildAchievementsSection(context, c, sw, sh, body, label, unlocked),
                    ],
                  );
                },
              ),

              SizedBox(height: sh * 0.022),

              // Settings section
              _buildSection(c, sw, sh, body, label, 'Account', [
                _MenuItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Edit Profile',
                  color: const Color(0xFF8FD44E),
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.notifications_none_rounded,
                  label: 'Notifications',
                  color: const Color(0xFF64B5F6),
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.lock_outline_rounded,
                  label: 'Change Password',
                  color: const Color(0xFFFFB74D),
                  onTap: () {},
                ),
              ]),
              SizedBox(height: sh * 0.010),
              _buildHandicapGoalRow(context, c, sw, sh, body, label),

              SizedBox(height: sh * 0.016),

              _buildSection(c, sw, sh, body, label, 'App', [
                _MenuItem(
                  icon: Icons.info_outline_rounded,
                  label: 'About StatTee',
                  color: const Color(0xFF6DBD35),
                  onTap: () {},
                ),
              ]),

              SizedBox(height: sh * 0.016),

              // Notifications
              _buildNotificationsSection(context, c, sw, sh, body, label),

              SizedBox(height: sh * 0.016),

              // Sign out
              _buildSignOutButton(context, c, sw, sh, body),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(AppColors c, double sw, double sh, double body,
      double label, String initials, String name, String email) {
    return Container(
      decoration: ShapeDecoration(
        color: c.cardBg,
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(48),
          side: BorderSide(color: c.cardBorder),
        ),
        shadows: c.cardShadow,
      ),
      padding: EdgeInsets.all((sw * 0.055).clamp(18.0, 24.0)),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipSuperellipse(
              cornerRadius: 40,
              child: CustomPaint(
                painter: _ProfileWavePainter(waveColor: c.accent),
              ),
            ),
          ),
          Row(
            children: [
              // Avatar
              Container(
                width: (sw * 0.18).clamp(62.0, 76.0),
                height: (sw * 0.18).clamp(62.0, 76.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A3A08), Color(0xFF7BC344)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: const Color(0xFF8FD44E).withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(fontFamily: 'Nunito',
                      color: Colors.white,
                      fontSize: (sw * 0.065).clamp(20.0, 28.0),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SizedBox(width: (sw * 0.04).clamp(12.0, 18.0)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.split(' ').first,
                      style: TextStyle(fontFamily: 'Nunito',
                        color: c.primaryText,
                        fontSize: (sw * 0.052).clamp(18.0, 22.0),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: TextStyle(color: c.secondaryText, fontSize: label),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: c.accentBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: c.accentBorder),
                      ),
                      child: Text(
                        'Golfer',
                        style: TextStyle(
                          color: c.accent,
                          fontSize: label * 0.9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(BuildContext context, AppColors c, double sw, double sh,
      double body, double label, List<Achievement> unlocked) {
    final unlockedIds = unlocked.map((a) => a.id).toSet();
    final all = AchievementService.all;
    final frac = all.isEmpty ? 0.0 : (unlockedIds.length / all.length).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Text(
                'ACHIEVEMENTS',
                style: TextStyle(
                  color: c.tertiaryText,
                  fontSize: label * 0.88,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF8FD44E).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${unlockedIds.length}/${all.length}',
                  style: TextStyle(
                    color: const Color(0xFF8FD44E),
                    fontSize: label * 0.82,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              // Overall progress bar inline
              SizedBox(
                width: sw * 0.28,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(children: [
                    Container(height: 5, color: c.cardBorder),
                    FractionallySizedBox(
                      widthFactor: frac,
                      child: Container(
                        height: 5,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF7BC344), Color(0xFF8FD44E)],
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),

        // ── 2-column card grid ─────────────────────────────────────────────
        GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: (sh * 0.155).clamp(120.0, 145.0),
          ),
          itemCount: all.length,
          itemBuilder: (context, i) {
            final a = all[i];
            final isUnlocked = unlockedIds.contains(a.id);

            return GestureDetector(
              onTap: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: c.sheetBg,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  title: Text(
                    '${a.emoji} ${a.name}',
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        color: c.primaryText,
                        fontWeight: FontWeight.w700),
                  ),
                  content: Text(
                    isUnlocked ? a.description : '🔒 ${a.description}',
                    style: TextStyle(color: c.secondaryText),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('OK', style: TextStyle(color: c.accent)),
                    ),
                  ],
                ),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: isUnlocked
                    ? ShapeDecoration(
                        color: c.cardBg,
                        shape: SuperellipseShape(
                          borderRadius: BorderRadius.circular(48),
                          side: BorderSide(color: const Color(0xFF5A9E1F).withValues(alpha: 0.25), width: 1.5),
                        ),
                        shadows: c.cardShadow,
                      )
                    : ShapeDecoration(
                        color: c.cardBg,
                        shape: SuperellipseShape(
                          borderRadius: BorderRadius.circular(48),
                          side: BorderSide(color: c.cardBorder),
                        ),
                        shadows: c.cardShadow,
                      ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Emoji / lock badge
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isUnlocked
                                  ? const Color(0xFF5A9E1F).withValues(alpha: 0.10)
                                  : c.cardBorder.withValues(alpha: 0.25),
                            ),
                          ),
                          Opacity(
                            opacity: isUnlocked ? 1.0 : 0.45,
                            child: Text(
                              isUnlocked ? a.emoji : '🔒',
                              style: TextStyle(
                                  fontSize: (sw * 0.072).clamp(24.0, 30.0)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Name
                      Text(
                        a.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          color: isUnlocked ? c.primaryText : c.tertiaryText,
                          fontSize: label,
                          fontWeight: isUnlocked ? FontWeight.w700 : FontWeight.w400,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatsRow(AppColors c, double sw, double sh, double body,
      double label, AppStats stats) {
    final tiles = [
      (value: '${stats.totalRounds}',  lbl: 'Rounds',   color: c.accent,                    icon: Icons.sports_golf_rounded),
      (value: stats.handicapLabel,     lbl: 'Handicap',  color: const Color(0xFF3B82F6),      icon: Icons.track_changes_rounded),
      (value: '${stats.totalBirdies}', lbl: 'Birdies',   color: const Color(0xFFF59E0B),      icon: Icons.emoji_events_rounded),
    ];

    return Row(
      children: tiles.asMap().entries.map((e) {
        final t = e.value;
        final isLast = e.key == tiles.length - 1;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: (sh * 0.022).clamp(16.0, 22.0),
                    horizontal: 8,
                  ),
                  decoration: ShapeDecoration(
                    color: c.cardBg,
                    shape: SuperellipseShape(
                      borderRadius: BorderRadius.circular(48),
                      side: BorderSide(color: t.color.withValues(alpha: 0.25)),
                    ),
                    shadows: c.cardShadow,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: (sw * 0.088).clamp(30.0, 38.0),
                        height: (sw * 0.088).clamp(30.0, 38.0),
                        decoration: BoxDecoration(
                          color: t.color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(t.icon, color: t.color,
                            size: (sw * 0.044).clamp(15.0, 20.0)),
                      ),
                      SizedBox(height: sh * 0.008),
                      Text(
                        t.value,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          color: t.color,
                          fontSize: (sw * 0.058).clamp(20.0, 26.0),
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        t.lbl,
                        style: TextStyle(
                            color: c.tertiaryText, fontSize: label * 0.88),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isLast) const SizedBox(width: 10),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Handicap Goal ─────────────────────────────────────────────────────────
  Widget _buildHandicapGoalRow(BuildContext context, AppColors c, double sw, double sh, double body, double label) {
    final iconSize = (sw * 0.088).clamp(30.0, 38.0);
    return StreamBuilder<double?>(
      stream: UserProfileService.handicapGoalStream(),
      builder: (ctx, snap) {
        final goal = snap.data;
        return GestureDetector(
          onTap: () => _showHandicapGoalSheet(context, c, sw, sh, body, label, goal),
          behavior: HitTestBehavior.opaque,
          child: Container(
            decoration: ShapeDecoration(
              color: c.cardBg,
              shape: SuperellipseShape(
                borderRadius: BorderRadius.circular(48),
                side: BorderSide(color: c.cardBorder),
              ),
              shadows: c.cardShadow,
            ),
            padding: EdgeInsets.symmetric(
                horizontal: (sw * 0.045).clamp(14.0, 20.0),
                vertical: (sh * 0.016).clamp(12.0, 18.0)),
            child: Row(
              children: [
                Container(
                  width: iconSize, height: iconSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6DBD35).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.track_changes_rounded,
                      color: const Color(0xFF6DBD35),
                      size: (sw * 0.044).clamp(15.0, 20.0)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Handicap Goal',
                          style: TextStyle(color: c.primaryText, fontSize: body)),
                      Text(
                        goal != null
                            ? 'Target: ${goal.toStringAsFixed(1)}'
                            : 'Not set — tap to set',
                        style: TextStyle(
                            color: goal != null ? const Color(0xFF6DBD35) : c.tertiaryText,
                            fontSize: label * 0.9),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    color: c.tertiaryText, size: 14),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showHandicapGoalSheet(BuildContext context, AppColors c, double sw, double sh, double body, double label, double? current) {
    double sliderVal = current ?? 18.0;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: BoxDecoration(
            color: c.sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: c.cardBorder)),
          ),
          padding: EdgeInsets.fromLTRB(
              (sw * 0.065).clamp(22.0, 32.0),
              24,
              (sw * 0.065).clamp(22.0, 32.0),
              (sh * 0.05).clamp(24.0, 36.0)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: c.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Handicap Goal',
                  style: TextStyle(fontFamily: 'Nunito',
                      color: c.primaryText,
                      fontSize: (sw * 0.052).clamp(18.0, 22.0),
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Set a target handicap index to track on your trend chart.',
                  style: TextStyle(color: c.secondaryText, fontSize: label)),
              SizedBox(height: sh * 0.032),
              Center(
                child: Text(
                  sliderVal.toStringAsFixed(1),
                  style: TextStyle(fontFamily: 'Nunito',
                      color: const Color(0xFF6DBD35),
                      fontSize: (sw * 0.14).clamp(48.0, 60.0),
                      fontWeight: FontWeight.w800),
                ),
              ),
              Slider(
                value: sliderVal,
                min: 0.0,
                max: 36.0,
                divisions: 360,
                activeColor: const Color(0xFF6DBD35),
                inactiveColor: c.divider,
                onChanged: (v) => setModalState(() => sliderVal = v),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0.0', style: TextStyle(color: c.tertiaryText, fontSize: label)),
                  Text('36.0', style: TextStyle(color: c.tertiaryText, fontSize: label)),
                ],
              ),
              SizedBox(height: sh * 0.028),
              Row(
                children: [
                  if (current != null) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          await UserProfileService.clearHandicapGoal();
                          if (context.mounted) Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: c.fieldBorder),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text('Clear',
                            style: TextStyle(color: c.secondaryText, fontSize: body)),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () async {
                        await UserProfileService.setHandicapGoal(
                            double.parse(sliderVal.toStringAsFixed(1)));
                        if (context.mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6DBD35),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: Text('Save Goal',
                          style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: body,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(AppColors c, double sw, double sh, double body,
      double label, String title, List<_MenuItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: c.tertiaryText,
              fontSize: label * 0.88,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ClipSuperellipse(
          cornerRadius: 40,
          child: Container(
          decoration: ShapeDecoration(
            color: c.cardBg,
            shape: SuperellipseShape(
              borderRadius: BorderRadius.circular(48),
              side: BorderSide(color: c.cardBorder),
            ),
            shadows: c.cardShadow,
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final idx = e.key;
              final item = e.value;
              return GestureDetector(
                onTap: item.onTap,
                behavior: HitTestBehavior.opaque,
                child: Stack(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: (sw * 0.045).clamp(14.0, 20.0),
                        vertical: (sh * 0.016).clamp(12.0, 18.0),
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          top: idx == 0
                              ? BorderSide.none
                              : BorderSide(color: c.divider, width: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: (sw * 0.088).clamp(30.0, 38.0),
                            height: (sw * 0.088).clamp(30.0, 38.0),
                            decoration: BoxDecoration(
                              color: item.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(item.icon, color: item.color,
                                size: (sw * 0.044).clamp(15.0, 20.0)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.label,
                              style: TextStyle(
                                  color: c.primaryText, fontSize: body),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded,
                              color: c.tertiaryText, size: 14),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 0, top: 0, bottom: 0,
                      child: Container(width: 3, color: item.color),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        ),
      ],
    );
  }

  Widget _buildNotificationsSection(BuildContext context, AppColors c,
      double sw, double sh, double body, double label) {
    return _NotificationsSection(c: c, sw: sw, sh: sh, body: body, label: label);
  }

  Widget _buildSignOutButton(BuildContext context, AppColors c, double sw,
      double sh, double body) {
    const red = Color(0xFFFF6B6B);

    Future<void> doSignOut() async {
      final confirm = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (sheetCtx) => Container(
          decoration: BoxDecoration(
            color: c.sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: c.cardBorder)),
          ),
          padding: EdgeInsets.fromLTRB(
            (sw * 0.065).clamp(22.0, 32.0),
            20,
            (sw * 0.065).clamp(22.0, 32.0),
            (sh * 0.05).clamp(24.0, 40.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: c.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: sh * 0.032),
              // Icon
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: c.accentBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: c.accentBorder),
                ),
                child: Icon(Icons.logout_rounded, color: c.accent, size: 26),
              ),
              SizedBox(height: sh * 0.020),
              Text('Sign Out?',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      color: c.primaryText,
                      fontSize: (sw * 0.052).clamp(18.0, 22.0),
                      fontWeight: FontWeight.w700)),
              SizedBox(height: sh * 0.008),
              Text('You will be returned to the login screen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.secondaryText, fontSize: body * 0.9)),
              SizedBox(height: sh * 0.036),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: (sh * 0.065).clamp(48.0, 58.0),
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetCtx, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: c.primaryText,
                          side: BorderSide(color: c.cardBorder),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text('Cancel',
                            style: TextStyle(
                                fontSize: body, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: (sh * 0.065).clamp(48.0, 58.0),
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(sheetCtx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: c.accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text('Sign Out',
                            style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: body,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      if (confirm == true) {
        await AuthService().signOut();
      }
    }

    return GestureDetector(
      onTap: doSignOut,
      behavior: HitTestBehavior.opaque,
      child: ClipSuperellipse(
        cornerRadius: 40,
        child: Container(
          decoration: ShapeDecoration(
            color: c.cardBg,
            shape: SuperellipseShape(
              borderRadius: BorderRadius.circular(48),
              side: BorderSide(color: c.cardBorder),
            ),
            shadows: c.cardShadow,
          ),
          child: Stack(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: (sw * 0.045).clamp(14.0, 20.0),
                  vertical: (sh * 0.016).clamp(12.0, 18.0),
                ),
                child: Row(
                  children: [
                    Container(
                      width: (sw * 0.088).clamp(30.0, 38.0),
                      height: (sw * 0.088).clamp(30.0, 38.0),
                      decoration: BoxDecoration(
                        color: red.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.logout_rounded, color: red,
                          size: (sw * 0.044).clamp(15.0, 20.0)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Sign Out',
                        style: TextStyle(color: red, fontSize: body, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0, top: 0, bottom: 0,
                child: Container(width: 3, color: red),
              ),
            ],
          ),
        ),
      ),
    );
  }


  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _MenuItem(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});
}

class _ProfileWavePainter extends CustomPainter {
  final Color waveColor;
  const _ProfileWavePainter({required this.waveColor});

  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()..color = waveColor.withValues(alpha: 0.04)..style = PaintingStyle.fill;
    final path1 = Path();
    path1.moveTo(0, size.height * 0.6);
    for (double x = 0; x <= size.width; x++) {
      path1.lineTo(x, size.height * 0.6 + math.sin((x / size.width) * 2 * math.pi) * size.height * 0.06);
    }
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, p1);

    final p2 = Paint()..color = waveColor.withValues(alpha: 0.025)..style = PaintingStyle.fill;
    final path2 = Path();
    path2.moveTo(0, size.height * 0.45);
    for (double x = 0; x <= size.width; x++) {
      path2.lineTo(x, size.height * 0.45 + math.sin((x / size.width) * 2 * math.pi + 1.0) * size.height * 0.07);
    }
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, p2);
  }

  @override
  bool shouldRepaint(covariant _ProfileWavePainter old) => old.waveColor != waveColor;
}

class _AchievementGlowPainter extends CustomPainter {
  final Color glowColor;
  const _AchievementGlowPainter({required this.glowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (final (radius, alpha) in [
      (size.width * 0.48, 0.08),
      (size.width * 0.42, 0.13),
      (size.width * 0.36, 0.20),
    ]) {
      canvas.drawCircle(center, radius, Paint()..color = glowColor.withValues(alpha: alpha));
    }
  }

  @override
  bool shouldRepaint(covariant _AchievementGlowPainter old) => old.glowColor != glowColor;
}

// ── Notifications Section ─────────────────────────────────────────────────────

class _NotificationsSection extends StatefulWidget {
  final AppColors c;
  final double sw, sh, body, label;
  const _NotificationsSection({
    required this.c,
    required this.sw,
    required this.sh,
    required this.body,
    required this.label,
  });

  @override
  State<_NotificationsSection> createState() => _NotificationsSectionState();
}

class _NotificationsSectionState extends State<_NotificationsSection> {
  Map<String, bool> _settings = {
    'tips': true,
    'streak': true,
    'roundReminder': true,
    'personalBest': true,
  };
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await NotificationService.getSettings();
    if (mounted) setState(() { _settings = s; _loading = false; });
  }

  Future<void> _toggle(String key, bool value) async {
    setState(() => _settings = {..._settings, key: value});
    await NotificationService.saveSettings(_settings);
  }

  static const _items = [
    (key: 'tips',         icon: Icons.lightbulb_outline_rounded,  label: 'Daily Golf Tips',     color: Color(0xFF6DBD35)),
    (key: 'streak',       icon: Icons.local_fire_department_rounded, label: 'Streak Reminder',  color: Color(0xFFFF9800)),
    (key: 'roundReminder',icon: Icons.alarm_rounded,              label: 'Round Reminder',      color: Color(0xFF42A5F5)),
    (key: 'personalBest', icon: Icons.emoji_events_rounded,       label: 'Personal Best Alert', color: Color(0xFFFFB74D)),
  ];

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final sw = widget.sw;
    final sh = widget.sh;
    final body = widget.body;
    final label = widget.label;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'NOTIFICATIONS',
            style: TextStyle(
              color: c.tertiaryText,
              fontSize: label * 0.88,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ClipSuperellipse(
          cornerRadius: 40,
          child: Container(
            decoration: ShapeDecoration(
              color: c.cardBg,
              shape: SuperellipseShape(
                borderRadius: BorderRadius.circular(48),
                side: BorderSide(color: c.cardBorder),
              ),
              shadows: c.cardShadow,
            ),
            child: _loading
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: c.accent),
                      ),
                    ),
                  )
                : Column(
                    children: _items.asMap().entries.map((e) {
                      final idx = e.key;
                      final item = e.value;
                      final isOn = _settings[item.key] ?? true;
                      return Stack(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: (sw * 0.045).clamp(14.0, 20.0),
                              vertical: (sh * 0.014).clamp(10.0, 16.0),
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                top: idx == 0
                                    ? BorderSide.none
                                    : BorderSide(color: c.divider, width: 0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: (sw * 0.088).clamp(30.0, 38.0),
                                  height: (sw * 0.088).clamp(30.0, 38.0),
                                  decoration: BoxDecoration(
                                    color: item.color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(item.icon, color: item.color,
                                      size: (sw * 0.044).clamp(15.0, 20.0)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item.label,
                                    style: TextStyle(color: c.primaryText, fontSize: body),
                                  ),
                                ),
                                Switch(
                                  value: isOn,
                                  onChanged: (v) => _toggle(item.key, v),
                                  activeThumbColor: c.accent,
                                  activeTrackColor: c.accentBg,
                                  inactiveThumbColor: c.tertiaryText,
                                  inactiveTrackColor: c.cardBorder,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            left: 0, top: 0, bottom: 0,
                            child: Container(width: 3, color: item.color),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ),
      ],
    );
  }
}
