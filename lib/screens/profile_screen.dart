import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../services/auth_service.dart';
import '../services/round_service.dart';
import '../services/stats_service.dart';
import '../services/achievement_service.dart';
import '../services/user_profile_service.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';
import '../screens/notification_preferences_screen.dart';
import '../widgets/shimmer_widgets.dart';
import '../widgets/tip_banner.dart';
import '../services/onboarding_service.dart';
import '../widgets/golf_dna_widgets.dart';
import '../services/golf_dna_service.dart';
import '../widgets/play_style_widgets.dart';
import '../services/play_style_service.dart';
import 'package:superellipse_shape/superellipse_shape.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../screens/friends_screen.dart';

const List<String> _kAvatarUrls = [
  'https://cdn.jsdelivr.net/gh/grathi/stattee_profile_pic@v1/avt/1.jpg',
  'https://cdn.jsdelivr.net/gh/grathi/stattee_profile_pic@v1/avt/2.jpg',
  'https://cdn.jsdelivr.net/gh/grathi/stattee_profile_pic@v1/avt/3.jpg',
  'https://cdn.jsdelivr.net/gh/grathi/stattee_profile_pic@v1/avt/4.jpg',
  'https://cdn.jsdelivr.net/gh/grathi/stattee_profile_pic@v1/avt/5.jpg',
  'https://cdn.jsdelivr.net/gh/grathi/stattee_profile_pic@v1/avt/6.jpg',
  'https://cdn.jsdelivr.net/gh/grathi/stattee_profile_pic@v1/avt/7.jpg',
  'https://cdn.jsdelivr.net/gh/grathi/stattee_profile_pic@v1/avt/8.jpg',
  'https://cdn.jsdelivr.net/gh/grathi/stattee_profile_pic@v1/avt/9.jpg',
];

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
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTitleDelegate(
                title: 'Profile',
                topPad: sh * 0.022,
                hPad: hPad,
                fontSize: (sw * 0.068).clamp(24.0, 30.0),
                c: c,
              ),
            ),
            SliverToBoxAdapter(
              child: TipBanner(
                title: 'Make It Yours',
                body: 'Set your handicap goal, pick an avatar, and explore your Golf DNA and Play Style.',
                hasSeenFn: OnboardingService.hasSeenProfileTip,
                markSeenFn: OnboardingService.markProfileTipSeen,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(hPad, sh * 0.028, hPad, sh * 0.14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar + name card
                    _buildProfileCard(context, c, sw, sh, body, label, initials, name, email),

                    SizedBox(height: sh * 0.022),

                    // Stats summary + Achievements
                    StreamBuilder(
                      stream: RoundService.allCompletedRoundsStream(),
                      builder: (context, snap) {
                        final loading = snap.connectionState == ConnectionState.waiting;
                        final rounds = snap.data ?? [];
                        final stats = loading ? AppStats.empty : StatsService.calculate(rounds);
                        final unlocked = loading ? <Achievement>[] : AchievementService.evaluate(stats, rounds);
                        final dna = loading ? GolfDNAService.compute([]) : GolfDNAService.compute(rounds);
                        final playStyle = loading ? PlayStyleService.compute([]) : PlayStyleService.compute(rounds);
                        return Skeletonizer(
                          enabled: loading,
                          child: Column(
                            children: [
                              PlayStyleSection(identity: playStyle),
                              SizedBox(height: sh * 0.022),
                              _buildStatsRow(c, sw, sh, body, label, stats),
                              SizedBox(height: sh * 0.022),
                              _buildAchievementsSection(context, c, sw, sh, body, label, unlocked),
                              SizedBox(height: sh * 0.022),
                              GolfDNASection(dna: dna),
                            ],
                          ),
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
                        onTap: () => _showEditProfileSheet(context, c, sw, sh, body, label),
                      ),
                      _MenuItem(
                        icon: Icons.people_rounded,
                        label: 'Friends & Leaderboard',
                        color: const Color(0xFF4A90D9),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const FriendsScreen())),
                      ),
                      _MenuItem(
                        icon: Icons.notifications_active_rounded,
                        label: 'Smart Notifications',
                        color: const Color(0xFF7BC344),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationPreferencesScreen(),
                          ),
                        ),
                      ),
                    ]),
                    SizedBox(height: sh * 0.016),

                    // Sign out
                    _buildSignOutButton(context, c, sw, sh, body),

                    SizedBox(height: sh * 0.012),

                    // Delete account
                    _buildDeleteAccountButton(context, c, sw, sh, body),

                    SizedBox(height: sh * 0.028),

                    // Version + copyright
                    Center(
                      child: FutureBuilder<PackageInfo>(
                        future: PackageInfo.fromPlatform(),
                        builder: (context, snap) {
                          final version = snap.data?.version ?? '1.3.0';
                          return Column(
                            children: [
                              Text('TeeStats v$version',
                                style: TextStyle(
                                  color: c.tertiaryText,
                                  fontSize: label * 0.95,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('© ${DateTime.now().year} TeeStats. All rights reserved.',
                                style: TextStyle(
                                  color: c.tertiaryText.withValues(alpha: 0.6),
                                  fontSize: label * 0.85,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, AppColors c, double sw, double sh, double body,
      double label, String initials, String name, String email) {
    final avatarSize = (sw * 0.18).clamp(62.0, 76.0);
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
      child: Row(
            children: [
              // Tappable avatar with edit badge
              GestureDetector(
                onTap: () => _showAvatarPickerSheet(context, c, sw, sh, body, label),
                child: Stack(
                  children: [
                    _AvatarWidget(initials: initials, avatarSize: avatarSize),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: c.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: c.cardBg, width: 2),
                        ),
                        child: const Icon(Icons.edit_rounded,
                            color: Colors.white, size: 12),
                      ),
                    ),
                  ],
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
                      decoration: ShapeDecoration(
                        color: c.accentBg,
                        shape: SuperellipseShape(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: c.accentBorder),
                        ),
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
    );
  }

  void _showAvatarPickerSheet(BuildContext context, AppColors c, double sw,
      double sh, double body, double label) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AvatarPickerSheet(c: c, sw: sw, sh: sh, body: body, label: label),
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
                decoration: ShapeDecoration(
                  color: const Color(0xFF8FD44E).withValues(alpha: 0.15),
                  shape: SuperellipseShape(
                    borderRadius: BorderRadius.circular(20),
                  ),
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

        // ── 3-column card grid ─────────────────────────────────────────────
        GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            mainAxisExtent: (sh * 0.130).clamp(100.0, 120.0),
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
                  shape: SuperellipseShape(
                      borderRadius: BorderRadius.circular(40)),
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
                          borderRadius: BorderRadius.circular(40),
                          side: BorderSide(color: const Color(0xFF5A9E1F).withValues(alpha: 0.25), width: 1.5),
                        ),
                        shadows: c.cardShadow,
                      )
                    : ShapeDecoration(
                        color: c.cardBg,
                        shape: SuperellipseShape(
                          borderRadius: BorderRadius.circular(40),
                          side: BorderSide(color: c.cardBorder),
                        ),
                        shadows: c.cardShadow,
                      ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Emoji / lock badge
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isUnlocked
                              ? const Color(0xFF5A9E1F).withValues(alpha: 0.10)
                              : c.cardBorder.withValues(alpha: 0.25),
                        ),
                        alignment: Alignment.center,
                        child: Opacity(
                          opacity: isUnlocked ? 1.0 : 0.45,
                          child: Text(
                            isUnlocked ? a.emoji : '🔒',
                            style: TextStyle(fontSize: (sw * 0.052).clamp(18.0, 22.0)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        a.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          color: isUnlocked ? c.primaryText : c.tertiaryText,
                          fontSize: label * 0.88,
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
                  decoration: ShapeDecoration(
                    color: const Color(0xFF6DBD35).withValues(alpha: 0.12),
                    shape: SuperellipseShape(
                      borderRadius: BorderRadius.circular(20),
                    ),
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
                          foregroundColor: c.secondaryText,
                          side: BorderSide(color: c.fieldBorder),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text('Clear', style: TextStyle(fontSize: body)),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                            decoration: ShapeDecoration(
                              color: item.color.withValues(alpha: 0.12),
                              shape: SuperellipseShape(
                                borderRadius: BorderRadius.circular(20),
                              ),
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

  void _showEditProfileSheet(BuildContext context, AppColors c, double sw,
      double sh, double body, double label) {
    final user = FirebaseAuth.instance.currentUser;
    final nameCtrl = TextEditingController(text: user?.displayName ?? '');
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: c.sheetBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(top: BorderSide(color: c.cardBorder)),
            ),
            padding: EdgeInsets.fromLTRB(
                (sw * 0.055).clamp(18.0, 28.0), 12,
                (sw * 0.055).clamp(18.0, 28.0), 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                SizedBox(height: sh * 0.022),
                // Icon + title
                Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: ShapeDecoration(
                      color: c.accentBg,
                      shape: SuperellipseShape(
                        borderRadius: BorderRadius.circular(28),
                        side: BorderSide(color: c.accentBorder),
                      ),
                    ),
                    child: Icon(Icons.person_rounded, color: c.accent, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Text('Edit Profile',
                    style: TextStyle(fontFamily: 'Nunito',
                      color: c.primaryText,
                      fontSize: (sw * 0.052).clamp(18.0, 22.0),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ]),
                SizedBox(height: sh * 0.024),
                Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Display name
                      TextFormField(
                        controller: nameCtrl,
                        style: TextStyle(color: c.fieldText, fontSize: body),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                        decoration: InputDecoration(
                          labelText: 'Display Name',
                          labelStyle: TextStyle(color: c.fieldLabel, fontSize: body * 0.9),
                          prefixIcon: Icon(Icons.badge_outlined, color: c.fieldIcon, size: body * 1.3),
                          filled: true,
                          fillColor: c.fieldBg,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: c.fieldBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: c.accent, width: 1.5),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE53935)),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      SizedBox(height: sh * 0.012),
                      // Email (read-only)
                      TextFormField(
                        initialValue: user?.email ?? '',
                        readOnly: true,
                        style: TextStyle(color: c.tertiaryText, fontSize: body),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(color: c.fieldLabel, fontSize: body * 0.9),
                          prefixIcon: Icon(Icons.email_outlined, color: c.fieldIcon, size: body * 1.3),
                          filled: true,
                          fillColor: c.fieldBg.withValues(alpha: 0.5),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: c.fieldBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: c.fieldBorder),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          suffixIcon: Icon(Icons.lock_outline_rounded, color: c.tertiaryText, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: sh * 0.028),
                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setState(() => saving = true);
                            try {
                              await user?.updateDisplayName(nameCtrl.text.trim());
                              if (ctx.mounted) Navigator.pop(ctx);
                            } catch (_) {
                              setState(() => saving = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: saving
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text('Save Changes',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Nunito',
                              fontSize: body,
                              fontWeight: FontWeight.w700,
                            )),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
                decoration: ShapeDecoration(
                  color: c.accentBg,
                  shape: SuperellipseShape(
                    borderRadius: BorderRadius.circular(36),
                    side: BorderSide(color: c.accentBorder),
                  ),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text('Cancel',
                            style: TextStyle(fontSize: body, fontWeight: FontWeight.w600)),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                      decoration: ShapeDecoration(
                        color: red.withValues(alpha: 0.10),
                        shape: SuperellipseShape(
                          borderRadius: BorderRadius.circular(20),
                        ),
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


  Widget _buildDeleteAccountButton(BuildContext context, AppColors c, double sw,
      double sh, double body) {
    const red = Color(0xFFFF3B30);

    Future<void> doDelete() async {
      // Step 1 — first confirmation sheet
      final confirm1 = await showModalBottomSheet<bool>(
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
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: c.divider, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              SizedBox(height: sh * 0.032),
              Container(
                width: 64, height: 64,
                decoration: ShapeDecoration(
                  color: red.withValues(alpha: 0.10),
                  shape: SuperellipseShape(
                    borderRadius: BorderRadius.circular(40),
                    side: BorderSide(color: red.withValues(alpha: 0.25)),
                  ),
                ),
                child: const Icon(Icons.delete_forever_rounded, color: red, size: 30),
              ),
              SizedBox(height: sh * 0.020),
              Text('Delete Account?',
                style: TextStyle(fontFamily: 'Nunito', color: c.primaryText,
                  fontSize: (sw * 0.052).clamp(18.0, 22.0), fontWeight: FontWeight.w700),
              ),
              SizedBox(height: sh * 0.010),
              Text(
                'This will permanently delete your account and all your golf data including rounds, stats, and achievements.',
                textAlign: TextAlign.center,
                style: TextStyle(color: c.secondaryText, fontSize: body * 0.9, height: 1.5),
              ),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text('Cancel', style: TextStyle(fontSize: body, fontWeight: FontWeight.w600)),
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
                          backgroundColor: red,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text('Continue', style: TextStyle(color: Colors.white, fontFamily: 'Nunito', fontSize: body, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      if (confirm1 != true || !context.mounted) return;

      // Step 2 — second confirmation (irreversible warning)
      final confirm2 = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (sheetCtx) => Container(
          decoration: BoxDecoration(
            color: c.sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: red.withValues(alpha: 0.4))),
          ),
          padding: EdgeInsets.fromLTRB(
            (sw * 0.065).clamp(22.0, 32.0),
            20,
            (sw * 0.065).clamp(22.0, 32.0),
            (sh * 0.05).clamp(24.0, 40.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: c.divider, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              SizedBox(height: sh * 0.028),
              Text('Are you absolutely sure?',
                style: TextStyle(fontFamily: 'Nunito', color: red,
                  fontSize: (sw * 0.048).clamp(16.0, 20.0), fontWeight: FontWeight.w800),
              ),
              SizedBox(height: sh * 0.012),
              _deleteBullet(c, body, 'All your rounds and scorecards'),
              _deleteBullet(c, body, 'Stats, handicap history and achievements'),
              _deleteBullet(c, body, 'Your profile and preferences'),
              _deleteBullet(c, body, 'Smart notifications and tee times'),
              SizedBox(height: sh * 0.010),
              Text('This action cannot be undone.',
                style: TextStyle(color: red, fontSize: body * 0.9, fontWeight: FontWeight.w600)),
              SizedBox(height: sh * 0.032),
              SizedBox(
                width: double.infinity,
                height: (sh * 0.065).clamp(48.0, 58.0),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(sheetCtx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: red,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Delete My Account', style: TextStyle(fontFamily: 'Nunito', fontSize: body, fontWeight: FontWeight.w800)),
                ),
              ),
              SizedBox(height: sh * 0.010),
              SizedBox(
                width: double.infinity,
                height: (sh * 0.055).clamp(42.0, 50.0),
                child: TextButton(
                  onPressed: () => Navigator.pop(sheetCtx, false),
                  child: Text('Keep My Account', style: TextStyle(color: c.secondaryText, fontSize: body * 0.9)),
                ),
              ),
            ],
          ),
        ),
      );
      if (confirm2 != true || !context.mounted) return;

      // Show loading indicator and delete
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Center(
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: ShapeDecoration(
              color: c.sheetBg,
              shape: SuperellipseShape(borderRadius: BorderRadius.circular(40)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: c.accent, strokeWidth: 3),
                const SizedBox(height: 16),
                Text('Deleting account…', style: TextStyle(color: c.primaryText, fontSize: body)),
              ],
            ),
          ),
        ),
      );

      try {
        await AuthService().deleteAccount();
      } on FirebaseAuthException catch (e) {
        if (!context.mounted) return;
        Navigator.pop(context); // close loading dialog
        if (e.code == 'requires-recent-login') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please sign out and sign back in before deleting your account.'),
              backgroundColor: red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.message}'),
              backgroundColor: red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (!context.mounted) return;
        Navigator.pop(context); // close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Something went wrong. Please try again.'),
            backgroundColor: red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      // Auth state listener in main.dart will redirect to login automatically
    }

    return GestureDetector(
      onTap: doDelete,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: (sw * 0.045).clamp(14.0, 20.0),
          vertical: (sh * 0.014).clamp(10.0, 14.0),
        ),
        child: Center(
          child: Text(
            'Delete Account',
            style: TextStyle(
              color: red.withValues(alpha: 0.7),
              fontSize: body * 0.88,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
              decorationColor: red.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _deleteBullet(AppColors c, double body, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Color(0xFFFF3B30), fontWeight: FontWeight.w700)),
          Expanded(child: Text(text, style: TextStyle(color: c.secondaryText, fontSize: body * 0.9))),
        ],
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

class _AvatarPickerSheet extends StatefulWidget {
  final AppColors c;
  final double sw, sh, body, label;
  const _AvatarPickerSheet({
    required this.c,
    required this.sw,
    required this.sh,
    required this.body,
    required this.label,
  });

  @override
  State<_AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

class _AvatarPickerSheetState extends State<_AvatarPickerSheet> {
  String? _selectedUrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    UserProfileService.avatarUrlStream().first.then((url) {
      if (mounted) setState(() => _selectedUrl = url);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final sw = widget.sw;
    final sh = widget.sh;
    final body = widget.body;
    final label = widget.label;

    return Container(
      decoration: BoxDecoration(
        color: c.sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: c.cardBorder)),
      ),
      padding: EdgeInsets.fromLTRB(
        (sw * 0.055).clamp(18.0, 28.0),
        12,
        (sw * 0.055).clamp(18.0, 28.0),
        (sh * 0.05).clamp(24.0, 40.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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
          SizedBox(height: sh * 0.022),
          // Header
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: ShapeDecoration(
                  color: c.accentBg,
                  shape: SuperellipseShape(
                    borderRadius: BorderRadius.circular(28),
                    side: BorderSide(color: c.accentBorder),
                  ),
                ),
                child: Icon(Icons.face_rounded, color: c.accent, size: 22),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Choose Avatar',
                    style: TextStyle(fontFamily: 'Nunito',
                      color: c.primaryText,
                      fontSize: (sw * 0.052).clamp(18.0, 22.0),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text('Select a preset avatar',
                    style: TextStyle(color: c.secondaryText, fontSize: label),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: sh * 0.024),
          // Avatar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: _kAvatarUrls.length,
            itemBuilder: (_, i) {
              final url = _kAvatarUrls[i];
              final isSelected = _selectedUrl == url;
              return GestureDetector(
                onTap: () => setState(() => _selectedUrl = url),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? c.accent : c.cardBorder,
                          width: isSelected ? 3 : 1.5,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, progress) => progress == null
                              ? child
                              : Container(
                                  color: c.cardBg,
                                  child: Center(
                                    child: SizedBox(
                                      width: 20, height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: c.accent),
                                    ),
                                  ),
                                ),
                          errorBuilder: (_, __, ___) => Container(
                            color: c.cardBg,
                            child: Icon(Icons.person_rounded,
                                color: c.tertiaryText, size: 32),
                          ),
                        ),
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        bottom: 2, right: 2,
                        child: Container(
                          width: 22, height: 22,
                          decoration: BoxDecoration(
                            color: c.accent,
                            shape: BoxShape.circle,
                            border: Border.all(color: c.sheetBg, width: 2),
                          ),
                          child: const Icon(Icons.check_rounded,
                              color: Colors.white, size: 12),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          // Remove button
          if (_selectedUrl != null)
            Center(
              child: TextButton(
                onPressed: () => setState(() => _selectedUrl = null),
                child: Text('Remove Avatar',
                  style: TextStyle(
                    color: c.tertiaryText,
                    fontSize: label,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          SizedBox(height: sh * 0.016),
          // Save button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _saving
                  ? null
                  : () async {
                      setState(() => _saving = true);
                      try {
                        if (_selectedUrl != null) {
                          await UserProfileService.setAvatarUrl(_selectedUrl!);
                        } else {
                          await UserProfileService.clearAvatarUrl();
                        }
                        if (mounted) Navigator.pop(context);
                      } catch (_) {
                        if (mounted) setState(() => _saving = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: c.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text('Save Avatar',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Nunito',
                        fontSize: body,
                        fontWeight: FontWeight.w700,
                      )),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarWidget extends StatelessWidget {
  final String initials;
  final double avatarSize;

  const _AvatarWidget({required this.initials, required this.avatarSize});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: UserProfileService.avatarUrlStream(),
      builder: (context, snap) {
        final url = snap.data;
        return Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: url == null
                ? const LinearGradient(
                    colors: [Color(0xFF1A3A08), Color(0xFF7BC344)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            border: Border.all(
              color: const Color(0xFF8FD44E).withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: url != null
              ? ClipOval(
                  child: Image.network(
                    url,
                    width: avatarSize,
                    height: avatarSize,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : _initialsCircle(),
                    errorBuilder: (_, __, ___) => _initialsCircle(),
                  ),
                )
              : _initialsCircle(),
        );
      },
    );
  }

  Widget _initialsCircle() {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF1A3A08), Color(0xFF7BC344)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontFamily: 'Nunito',
            color: Colors.white,
            fontSize: (avatarSize * 0.36).clamp(20.0, 28.0),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
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
                                  decoration: ShapeDecoration(
                                    color: item.color.withValues(alpha: 0.12),
                                    shape: SuperellipseShape(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
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

// ── Sticky title delegate ─────────────────────────────────────────────────────

class _StickyTitleDelegate extends SliverPersistentHeaderDelegate {
  const _StickyTitleDelegate({
    required this.title,
    required this.topPad,
    required this.hPad,
    required this.fontSize,
    required this.c,
  });

  final String title;
  final double topPad;
  final double hPad;
  final double fontSize;
  final AppColors c;

  double get _extent => topPad + fontSize * 1.6 + 14;

  @override
  double get minExtent => _extent;

  @override
  double get maxExtent => _extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: c.bgGradient[0],
      alignment: Alignment.bottomLeft,
      padding: EdgeInsets.fromLTRB(hPad, topPad, hPad, 14),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Nunito',
          color: c.primaryText,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_StickyTitleDelegate old) =>
      old.title != title || old.c != c;
}
