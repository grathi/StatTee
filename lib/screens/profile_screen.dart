import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/round_service.dart';
import '../services/stats_service.dart';
import '../services/achievement_service.dart';
import '../theme/app_theme.dart';

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
                      _buildAchievementsSection(c, sw, sh, body, label, unlocked),
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
                  color: const Color(0xFF818CF8),
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

              SizedBox(height: sh * 0.016),

              _buildSection(c, sw, sh, body, label, 'App', [
                _MenuItem(
                  icon: Icons.info_outline_rounded,
                  label: 'About StatTee',
                  color: const Color(0xFF34D399),
                  onTap: () {},
                ),
              ]),

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
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.cardBorder),
        boxShadow: c.cardShadow,
      ),
      padding: EdgeInsets.all((sw * 0.055).clamp(18.0, 24.0)),
      child: Row(
        children: [
          // Avatar
          Container(
            width: (sw * 0.18).clamp(62.0, 76.0),
            height: (sw * 0.18).clamp(62.0, 76.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1B4B), Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: const Color(0xFF818CF8).withValues(alpha: 0.4),
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
    );
  }

  Widget _buildAchievementsSection(AppColors c, double sw, double sh,
      double body, double label, List<Achievement> unlocked) {
    final unlockedIds = unlocked.map((a) => a.id).toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
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
                  color: const Color(0xFF818CF8).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${unlocked.length}/${AchievementService.all.length}',
                  style: TextStyle(
                    color: const Color(0xFF818CF8),
                    fontSize: label * 0.82,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: c.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.cardBorder),
            boxShadow: c.cardShadow,
          ),
          padding: EdgeInsets.all((sw * 0.045).clamp(14.0, 20.0)),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 8,
              childAspectRatio: 0.75,
            ),
            itemCount: AchievementService.all.length,
            itemBuilder: (context, i) {
              final a = AchievementService.all[i];
              final isUnlocked = unlockedIds.contains(a.id);
              return GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: c.sheetBg,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      title: Text(
                        '${a.emoji} ${a.name}',
                        style: TextStyle(fontFamily: 'Nunito',
                            color: c.primaryText,
                            fontWeight: FontWeight.w700),
                      ),
                      content: Text(
                        isUnlocked
                            ? a.description
                            : '🔒 ${a.description}',
                        style: TextStyle(color: c.secondaryText),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('OK',
                              style: TextStyle(color: c.accent)),
                        ),
                      ],
                    ),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: (sw * 0.13).clamp(44.0, 56.0),
                      height: (sw * 0.13).clamp(44.0, 56.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isUnlocked
                            ? const Color(0xFF818CF8).withValues(alpha: 0.18)
                            : c.cardBorder.withValues(alpha: 0.3),
                        border: Border.all(
                          color: isUnlocked
                              ? const Color(0xFF818CF8).withValues(alpha: 0.5)
                              : c.divider,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          isUnlocked ? a.emoji : '🔒',
                          style: TextStyle(
                            fontSize: (sw * 0.06).clamp(20.0, 26.0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      a.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isUnlocked ? c.primaryText : c.tertiaryText,
                        fontSize: label * 0.78,
                        fontWeight: isUnlocked
                            ? FontWeight.w600
                            : FontWeight.w400,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(AppColors c, double sw, double sh, double body,
      double label, AppStats stats) {
    final tiles = [
      ('${stats.totalRounds}', 'Rounds'),
      (stats.handicapLabel, 'Handicap'),
      ('${stats.totalBirdies}', 'Birdies'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.cardBorder),
        boxShadow: c.cardShadow,
      ),
      padding: EdgeInsets.symmetric(
        vertical: (sh * 0.018).clamp(12.0, 20.0),
        horizontal: (sw * 0.04).clamp(12.0, 18.0),
      ),
      child: Row(
        children: tiles.asMap().entries.map((e) {
          final (value, lbl) = e.value;
          final isLast = e.key == tiles.length - 1;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        value,
                        style: TextStyle(fontFamily: 'Nunito',
                          color: c.primaryText,
                          fontSize: (sw * 0.058).clamp(20.0, 26.0),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(lbl,
                          style: TextStyle(
                              color: c.tertiaryText, fontSize: label)),
                    ],
                  ),
                ),
                if (!isLast)
                  Container(
                      width: 1,
                      height: 36,
                      color: c.divider),
              ],
            ),
          );
        }).toList(),
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
        Container(
          decoration: BoxDecoration(
            color: c.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.cardBorder),
            boxShadow: c.cardShadow,
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final isLast = e.key == items.length - 1;
              final item = e.value;
              return GestureDetector(
                onTap: item.onTap,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: (sw * 0.045).clamp(14.0, 20.0),
                    vertical: (sh * 0.016).clamp(12.0, 18.0),
                  ),
                  decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : Border(
                            bottom: BorderSide(color: c.divider)),
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
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSignOutButton(BuildContext context, AppColors c, double sw,
      double sh, double body) {
    return SizedBox(
      width: double.infinity,
      height: (sh * 0.068).clamp(50.0, 62.0),
      child: OutlinedButton.icon(
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: c.sheetBg,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text('Sign Out?',
                  style: TextStyle(fontFamily: 'Nunito',
                      color: c.primaryText, fontWeight: FontWeight.w700)),
              content: Text('You will be returned to the login screen.',
                  style: TextStyle(color: c.secondaryText)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Cancel',
                      style: TextStyle(color: c.secondaryText)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Sign Out',
                      style: TextStyle(color: Color(0xFFFF6B6B))),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await AuthService().signOut();
          }
        },
        icon: const Icon(Icons.logout_rounded,
            color: Color(0xFFFF6B6B), size: 20),
        label: Text(
          'Sign Out',
          style: TextStyle(
            color: const Color(0xFFFF6B6B),
            fontSize: body,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFFF6B6B), width: 1),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
