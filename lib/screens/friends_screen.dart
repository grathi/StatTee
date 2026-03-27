import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:superellipse_shape/superellipse_shape.dart';
import '../models/friend_profile.dart';
import '../services/friends_service.dart';
import '../services/stats_service.dart';
import '../theme/app_theme.dart';
import 'friend_detail_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  int _tab = 0;

  // Search
  final _emailCtrl = TextEditingController();
  bool _searching = false;
  FriendProfile? _searchResult;
  String? _searchError;
  bool _requestSent = false;

  // Leaderboard
  int _lbSort = 0; // 0=Handicap 1=AvgScore 2=Birdies

  @override
  void initState() {
    super.initState();
    FriendsService.ensureProfileSynced();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _emailCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _searching = true;
      _searchResult = null;
      _searchError = null;
      _requestSent = false;
    });
    try {
      final result = await FriendsService.searchByEmail(q);
      if (!mounted) return;
      setState(() {
        _searching = false;
        if (result == null) {
          _searchError = 'No account found with that email.';
        } else {
          _searchResult = result;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _searchError = 'Something went wrong. Try again.';
      });
    }
  }

  void _clearSearch() {
    _emailCtrl.clear();
    setState(() {
      _searchResult = null;
      _searchError = null;
      _requestSent = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c     = AppColors.of(context);
    final sw    = MediaQuery.of(context).size.width;
    final sh    = MediaQuery.of(context).size.height;
    final hPad  = (sw * 0.055).clamp(18.0, 28.0);
    final body  = (sw * 0.036).clamp(13.0, 16.0);
    final label = (sw * 0.030).clamp(11.0, 13.0);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: c.bgGradient,
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(hPad, sh * 0.022, hPad, sh * 0.014),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          color: c.primaryText, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Friends',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        color: c.primaryText,
                        fontSize: (sw * 0.068).clamp(24.0, 30.0),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Tab bar ──────────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(hPad, 0, hPad, sh * 0.016),
                child: Container(
                  decoration: ShapeDecoration(
                    color: c.fieldBg,
                    shape: SuperellipseShape(
                      borderRadius: BorderRadius.circular(28),
                      side: BorderSide(color: c.fieldBorder),
                    ),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Row(
                    children: [
                      _tabBtn(c, body, 'Friends', Icons.people_rounded, 0),
                      _tabBtn(c, body, 'Leaderboard', Icons.leaderboard_rounded, 1),
                    ],
                  ),
                ),
              ),

              // ── Tab body ─────────────────────────────────────────────────
              Expanded(
                child: _tab == 0
                    ? _FriendsTab(
                        c: c,
                        sw: sw,
                        sh: sh,
                        hPad: hPad,
                        body: body,
                        label: label,
                        emailCtrl: _emailCtrl,
                        searching: _searching,
                        searchResult: _searchResult,
                        searchError: _searchError,
                        requestSent: _requestSent,
                        onSearch: _search,
                        onClear: _clearSearch,
                        onSendRequest: (profile) async {
                          await FriendsService.sendRequest(profile);
                          if (mounted) setState(() => _requestSent = true);
                        },
                        onAccept: (uid) => FriendsService.acceptRequest(uid),
                        onDecline: (uid) => FriendsService.declineOrRemove(uid),
                        onTapFriend: (f) => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => FriendDetailScreen(friend: f)),
                        ),
                      )
                    : _LeaderboardTab(
                        c: c,
                        sw: sw,
                        sh: sh,
                        hPad: hPad,
                        body: body,
                        label: label,
                        sortIdx: _lbSort,
                        onSortChanged: (i) => setState(() => _lbSort = i),
                        onTapFriend: (f) => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => FriendDetailScreen(friend: f)),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabBtn(AppColors c, double body, String title, IconData icon, int idx) {
    final sel = _tab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = idx),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: ShapeDecoration(
            gradient: sel
                ? const LinearGradient(
                    colors: [Color(0xFF5A9E1F), Color(0xFF8FD44E)],
                  )
                : null,
            shape: SuperellipseShape(borderRadius: BorderRadius.circular(48)),
            shadows: sel ? c.cardShadow : null,
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: body * 0.88,
                    color: sel ? c.primaryText : c.tertiaryText),
                const SizedBox(width: 5),
                Text(
                  title,
                  style: TextStyle(
                    color: sel ? c.primaryText : c.tertiaryText,
                    fontSize: body * 0.88,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Friends tab ───────────────────────────────────────────────────────────────

class _FriendsTab extends StatelessWidget {
  const _FriendsTab({
    required this.c,
    required this.sw,
    required this.sh,
    required this.hPad,
    required this.body,
    required this.label,
    required this.emailCtrl,
    required this.searching,
    required this.searchResult,
    required this.searchError,
    required this.requestSent,
    required this.onSearch,
    required this.onClear,
    required this.onSendRequest,
    required this.onAccept,
    required this.onDecline,
    required this.onTapFriend,
  });

  final AppColors c;
  final double sw, sh, hPad, body, label;
  final TextEditingController emailCtrl;
  final bool searching;
  final FriendProfile? searchResult;
  final String? searchError;
  final bool requestSent;
  final VoidCallback onSearch;
  final VoidCallback onClear;
  final ValueChanged<FriendProfile> onSendRequest;
  final ValueChanged<String> onAccept;
  final ValueChanged<String> onDecline;
  final ValueChanged<FriendProfile> onTapFriend;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FriendProfile>>(
      stream: FriendsService.friendsStream(),
      builder: (context, snap) {
        final all      = snap.data ?? [];
        final accepted = all.where((f) => f.status == 'accepted').toList();
        final pending  = all.where((f) => f.status == 'pending_received').toList();
        final hasSearch = emailCtrl.text.trim().isNotEmpty;

        return Column(
          children: [
            // Search bar
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 0),
              child: _SearchBar(
                c: c,
                body: body,
                ctrl: emailCtrl,
                searching: searching,
                onSearch: onSearch,
                onClear: onClear,
              ),
            ),

            // Search result card
            if (hasSearch) ...[
              SizedBox(height: sh * 0.012),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: _SearchResultCard(
                  c: c,
                  body: body,
                  label: label,
                  result: searchResult,
                  error: searchError,
                  requestSent: requestSent,
                  onSend: onSendRequest,
                ),
              ),
            ],

            // List or empty state
            Expanded(
              child: (accepted.isEmpty && pending.isEmpty && !hasSearch)
                  ? _emptyState(c, body, label)
                  : ListView(
                      padding: EdgeInsets.fromLTRB(hPad, sh * 0.016, hPad, sh * 0.12),
                      children: [
                        if (pending.isNotEmpty) ...[
                          _sectionLabel(c, label, 'Pending Requests'),
                          SizedBox(height: sh * 0.008),
                          ...pending.map((f) => _PendingCard(
                                c: c,
                                body: body,
                                label: label,
                                profile: f,
                                onAccept: () => onAccept(f.uid),
                                onDecline: () => onDecline(f.uid),
                              )),
                          SizedBox(height: sh * 0.016),
                        ],
                        if (accepted.isNotEmpty) ...[
                          _sectionLabel(c, label, 'Friends'),
                          SizedBox(height: sh * 0.008),
                          ...accepted.map((f) => _FriendCard(
                                c: c,
                                body: body,
                                label: label,
                                profile: f,
                                onTap: () => onTapFriend(f),
                              )),
                        ],
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _emptyState(AppColors c, double body, double label) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 52, color: c.tertiaryText),
          const SizedBox(height: 12),
          Text('No friends yet',
              style: TextStyle(
                  color: c.secondaryText,
                  fontSize: body,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Enter a friend\'s email above to add them',
              style: TextStyle(color: c.tertiaryText, fontSize: label)),
        ],
      ),
    );
  }

  Widget _sectionLabel(AppColors c, double label, String text) {
    return Text(text,
        style: TextStyle(
            color: c.tertiaryText,
            fontSize: label,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5));
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.c,
    required this.body,
    required this.ctrl,
    required this.searching,
    required this.onSearch,
    required this.onClear,
  });

  final AppColors c;
  final double body;
  final TextEditingController ctrl;
  final bool searching;
  final VoidCallback onSearch;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        color: c.fieldBg,
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: c.fieldBorder),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Row(
        children: [
          Icon(Icons.email_outlined, color: c.tertiaryText, size: body),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: ctrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onSearch(),
              style: TextStyle(color: c.primaryText, fontSize: body),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Search by email address…',
                hintStyle:
                    TextStyle(color: c.tertiaryText, fontSize: body * 0.9),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (ctrl.text.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: Icon(Icons.close_rounded,
                  color: c.tertiaryText, size: body * 1.1),
            ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: searching ? null : onSearch,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: ShapeDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF5A9E1F), Color(0xFF8FD44E)]),
                shape: SuperellipseShape(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: searching
                  ? SizedBox(
                      width: body,
                      height: body,
                      child: const CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text('Search',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: body * 0.85,
                          fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Search result card ────────────────────────────────────────────────────────

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({
    required this.c,
    required this.body,
    required this.label,
    required this.result,
    required this.error,
    required this.requestSent,
    required this.onSend,
  });

  final AppColors c;
  final double body, label;
  final FriendProfile? result;
  final String? error;
  final bool requestSent;
  final ValueChanged<FriendProfile> onSend;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: ShapeDecoration(
          color: c.fieldBg,
          shape: SuperellipseShape(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: c.fieldBorder),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: c.tertiaryText, size: body),
            const SizedBox(width: 10),
            Text(error!,
                style: TextStyle(color: c.secondaryText, fontSize: body * 0.9)),
          ],
        ),
      );
    }
    if (result == null) return const SizedBox.shrink();

    final alreadyFriend = result!.status == 'accepted';
    final pendingSent   = result!.status == 'pending_sent';
    final pendingReceived = result!.status == 'pending_received';

    String btnLabel;
    Color  btnColor;
    if (requestSent || pendingSent) {
      btnLabel = 'Request Sent';
      btnColor = c.tertiaryText;
    } else if (pendingReceived) {
      btnLabel = 'Accept Request';
      btnColor = const Color(0xFF5A9E1F);
    } else if (alreadyFriend) {
      btnLabel = 'Already Friends';
      btnColor = c.tertiaryText;
    } else {
      btnLabel = 'Add Friend';
      btnColor = const Color(0xFF5A9E1F);
    }

    final canAct = !alreadyFriend && !pendingSent && !requestSent;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: ShapeDecoration(
        color: c.fieldBg,
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: c.fieldBorder),
        ),
      ),
      child: Row(
        children: [
          _Avatar(url: result!.avatarUrl, name: result!.displayName, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result!.displayName,
                    style: TextStyle(
                        color: c.primaryText,
                        fontSize: body,
                        fontWeight: FontWeight.w700)),
                Text(result!.email,
                    style:
                        TextStyle(color: c.tertiaryText, fontSize: label)),
              ],
            ),
          ),
          GestureDetector(
            onTap: canAct ? () => onSend(result!) : null,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: ShapeDecoration(
                gradient: canAct
                    ? LinearGradient(colors: [btnColor, btnColor])
                    : null,
                color: canAct ? null : c.fieldBorder,
                shape: SuperellipseShape(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(btnLabel,
                  style: TextStyle(
                      color: canAct ? Colors.white : c.tertiaryText,
                      fontSize: label,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pending request card ──────────────────────────────────────────────────────

class _PendingCard extends StatelessWidget {
  const _PendingCard({
    required this.c,
    required this.body,
    required this.label,
    required this.profile,
    required this.onAccept,
    required this.onDecline,
  });

  final AppColors c;
  final double body, label;
  final FriendProfile profile;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: ShapeDecoration(
        color: c.cardBg,
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: c.cardBorder),
        ),
        shadows: c.cardShadow,
      ),
      child: Row(
        children: [
          _Avatar(url: profile.avatarUrl, name: profile.displayName, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.displayName,
                    style: TextStyle(
                        color: c.primaryText,
                        fontSize: body,
                        fontWeight: FontWeight.w700)),
                Text('Wants to be friends',
                    style:
                        TextStyle(color: c.tertiaryText, fontSize: label)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDecline,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: ShapeDecoration(
                color: c.fieldBg,
                shape: SuperellipseShape(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: c.fieldBorder),
                ),
              ),
              child: Text('Decline',
                  style: TextStyle(
                      color: c.tertiaryText,
                      fontSize: label,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onAccept,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: ShapeDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF5A9E1F), Color(0xFF8FD44E)]),
                shape: SuperellipseShape(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Accept',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: label,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Accepted friend card ──────────────────────────────────────────────────────

class _FriendCard extends StatelessWidget {
  const _FriendCard({
    required this.c,
    required this.body,
    required this.label,
    required this.profile,
    required this.onTap,
  });

  final AppColors c;
  final double body, label;
  final FriendProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: ShapeDecoration(
          color: c.cardBg,
          shape: SuperellipseShape(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: c.cardBorder),
          ),
          shadows: c.cardShadow,
        ),
        child: Row(
          children: [
            _Avatar(url: profile.avatarUrl, name: profile.displayName, size: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Text(profile.displayName,
                  style: TextStyle(
                      color: c.primaryText,
                      fontSize: body,
                      fontWeight: FontWeight.w700)),
            ),
            Icon(Icons.chevron_right_rounded, color: c.tertiaryText, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Leaderboard tab ───────────────────────────────────────────────────────────

class _LeaderboardTab extends StatefulWidget {
  const _LeaderboardTab({
    required this.c,
    required this.sw,
    required this.sh,
    required this.hPad,
    required this.body,
    required this.label,
    required this.sortIdx,
    required this.onSortChanged,
    required this.onTapFriend,
  });

  final AppColors c;
  final double sw, sh, hPad, body, label;
  final int sortIdx;
  final ValueChanged<int> onSortChanged;
  final ValueChanged<FriendProfile> onTapFriend;

  @override
  State<_LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends State<_LeaderboardTab> {
  late Future<List<FriendProfile>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadLeaderboard();
  }

  Future<List<FriendProfile>> _loadLeaderboard() async {
    final meUid = FirebaseAuth.instance.currentUser!.uid;
    final snap  = await FriendsService.friendsStream().first;
    final accepted = snap.where((f) => f.status == 'accepted').toList();

    // Load stats for all accepted friends + self
    final uids = [meUid, ...accepted.map((f) => f.uid)];
    final meUser = FirebaseAuth.instance.currentUser!;
    final profiles = <FriendProfile>[];

    for (final uid in uids) {
      final stats = await FriendsService.loadStatsForUser(uid);
      if (uid == meUid) {
        final myAvatar = await FriendsService.fetchAvatarUrl(meUid);
        profiles.add(FriendProfile(
          uid: meUid,
          displayName: meUser.displayName ?? 'You',
          email: meUser.email ?? '',
          avatarUrl: myAvatar,
          status: 'accepted',
          addedAt: DateTime.now(),
          stats: stats,
          totalRounds: stats.totalRounds,
        ));
      } else {
        final f = accepted.firstWhere((f) => f.uid == uid);
        f.stats = stats;
        f.totalRounds = stats.totalRounds;
        profiles.add(f);
      }
    }
    return profiles;
  }

  List<FriendProfile> _sorted(List<FriendProfile> list) {
    final copy = List<FriendProfile>.from(list);
    switch (widget.sortIdx) {
      case 0: // Handicap — lower is better
        copy.sort((a, b) =>
            (a.stats?.handicapIndex ?? 999).compareTo(b.stats?.handicapIndex ?? 999));
      case 1: // Avg Score diff — lower is better
        copy.sort((a, b) =>
            (a.stats?.avgScore ?? 999).compareTo(b.stats?.avgScore ?? 999));
      case 2: // Birdies — higher is better
        copy.sort((a, b) =>
            (b.stats?.totalBirdies ?? 0).compareTo(a.stats?.totalBirdies ?? 0));
    }
    return copy;
  }

  @override
  Widget build(BuildContext context) {
    final c     = widget.c;
    final body  = widget.body;
    final label = widget.label;
    final hPad  = widget.hPad;
    final sh    = widget.sh;
    final meUid = FirebaseAuth.instance.currentUser!.uid;

    return Column(
      children: [
        // Sort chips
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, 0, hPad, sh * 0.012),
          child: Row(
            children: [
              _sortChip(c, label, 'Handicap', 0),
              const SizedBox(width: 8),
              _sortChip(c, label, 'Avg Score', 1),
              const SizedBox(width: 8),
              _sortChip(c, label, 'Birdies', 2),
            ],
          ),
        ),

        Expanded(
          child: FutureBuilder<List<FriendProfile>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return Center(
                    child: CircularProgressIndicator(
                        color: c.accent, strokeWidth: 2));
              }
              final list = _sorted(snap.data ?? []);
              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.leaderboard_outlined,
                          size: 52, color: c.tertiaryText),
                      const SizedBox(height: 12),
                      Text('No leaderboard yet',
                          style: TextStyle(
                              color: c.secondaryText,
                              fontSize: body,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text('Add friends to compare scores',
                          style: TextStyle(
                              color: c.tertiaryText, fontSize: label)),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: EdgeInsets.fromLTRB(hPad, 0, hPad, sh * 0.12),
                itemCount: list.length,
                itemBuilder: (_, i) => _LeaderboardRow(
                  c: c,
                  body: body,
                  label: label,
                  rank: i + 1,
                  profile: list[i],
                  sortIdx: widget.sortIdx,
                  isMe: list[i].uid == meUid,
                  onTap: list[i].uid == meUid
                      ? null
                      : () => widget.onTapFriend(list[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _sortChip(AppColors c, double label, String text, int idx) {
    final sel = widget.sortIdx == idx;
    return GestureDetector(
      onTap: () => widget.onSortChanged(idx),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: ShapeDecoration(
          gradient: sel
              ? const LinearGradient(
                  colors: [Color(0xFF5A9E1F), Color(0xFF8FD44E)])
              : null,
          color: sel ? null : c.fieldBg,
          shape: SuperellipseShape(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: sel ? Colors.transparent : c.fieldBorder),
          ),
        ),
        child: Text(text,
            style: TextStyle(
                color: sel ? Colors.white : c.tertiaryText,
                fontSize: label,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
      ),
    );
  }
}

// ── Leaderboard row ───────────────────────────────────────────────────────────

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.c,
    required this.body,
    required this.label,
    required this.rank,
    required this.profile,
    required this.sortIdx,
    required this.isMe,
    required this.onTap,
  });

  final AppColors c;
  final double body, label;
  final int rank;
  final FriendProfile profile;
  final int sortIdx;
  final bool isMe;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final medalEmoji = rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : null;

    String statValue;
    final stats = profile.stats;
    switch (sortIdx) {
      case 0:
        statValue = stats != null ? stats.handicapLabel : '--';
      case 1:
        statValue = stats != null ? stats.avgScoreLabel : '--';
      case 2:
        statValue = stats != null ? '${stats.totalBirdies}' : '--';
      default:
        statValue = '--';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: ShapeDecoration(
          color: isMe ? c.accentBg : c.cardBg,
          shape: SuperellipseShape(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
                color: isMe ? c.accentBorder : c.cardBorder),
          ),
          shadows: c.cardShadow,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: medalEmoji != null
                  ? Text(medalEmoji,
                      style: const TextStyle(fontSize: 22),
                      textAlign: TextAlign.center)
                  : Text('#$rank',
                      style: TextStyle(
                          color: c.tertiaryText,
                          fontSize: label,
                          fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center),
            ),
            const SizedBox(width: 8),
            _Avatar(url: profile.avatarUrl, name: profile.displayName, size: 38),
            const SizedBox(width: 10),
            Expanded(
              child: Text(isMe ? 'You' : profile.displayName,
                  style: TextStyle(
                      color: c.primaryText,
                      fontSize: body,
                      fontWeight: FontWeight.w700)),
            ),
            Text(statValue,
                style: TextStyle(
                    color: c.accent,
                    fontSize: body,
                    fontWeight: FontWeight.w800)),
            if (!isMe) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  color: c.tertiaryText, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Avatar widget ─────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.url, required this.size});

  final String? url;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    if (url != null && url!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.network(url!,
            width: size, height: size, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _initials(c)),
      );
    }
    return _initials(c);
  }

  Widget _initials(AppColors c) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.accentBg,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(initial,
            style: TextStyle(
                color: c.accent,
                fontSize: size * 0.4,
                fontWeight: FontWeight.w800)),
      ),
    );
  }
}
