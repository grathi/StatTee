import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/smart_notification.dart';
import '../models/smart_notification_context.dart';
import 'notification_service.dart';

// ---------------------------------------------------------------------------
// Notification IDs reserved for smart notifications
// ---------------------------------------------------------------------------
const int kSmartNotifWeakness    = 4000;
const int kSmartNotifIncomplete  = 4001;
const int kSmartNotifTrend       = 4002;
const int kSmartNotifTeeTime     = 4003;

// ---------------------------------------------------------------------------
// SmartNotificationService
//
// Responsibilities:
//  1. Evaluate the current SmartNotificationContext against a rule engine
//  2. Decide which notification(s) to surface (one at a time, highest priority)
//  3. Generate human-friendly copy via _AITextGenerator (mock — swap for
//     real Gemini / OpenAI call in production)
//  4. Persist generated notifications to Firestore (for in-app history)
//  5. Fire the local notification via NotificationService
// ---------------------------------------------------------------------------
class SmartNotificationService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth      = FirebaseAuth.instance;

  // ── Cooldown tracking (in-memory, resets on cold start) ──────────────────

  /// Minimum gap between any two evaluate() calls (regardless of type).
  static const _resumeCooldown = Duration(minutes: 30);

  /// Per-type minimum gap — prevents the same notification firing twice
  /// in a short session even if the user backgrounds/foregrounds frequently.
  static const Map<SmartNotificationType, Duration> _typeCooldowns = {
    SmartNotificationType.performanceTrend: Duration(hours: 24),
    SmartNotificationType.weaknessPractice: Duration(hours: 12),
    SmartNotificationType.incompleteRound:  Duration(hours: 2),
    SmartNotificationType.teeTimeReminder:  Duration(minutes: 30),
  };

  static DateTime? _lastEvaluatedAt;
  static final Map<SmartNotificationType, DateTime> _lastFiredAt = {};

  // ── Public entry point ───────────────────────────────────────────────────

  /// Evaluate context, generate the highest-priority smart notification, fire
  /// it locally, persist to Firestore, and return it.
  ///
  /// Returns null if no notification should be triggered at this time.
  static Future<SmartNotification?> evaluate(
      SmartNotificationContext ctx) async {
    // Global cooldown — don't evaluate at all if called too recently.
    final now = DateTime.now();
    if (_lastEvaluatedAt != null &&
        now.difference(_lastEvaluatedAt!) < _resumeCooldown) {
      return null;
    }
    _lastEvaluatedAt = now;

    final candidates = _buildCandidates(ctx);
    if (candidates.isEmpty) return null;

    // Sort by priority (urgent > high > normal > low) then generate copy
    candidates.sort((a, b) => b.priority.index.compareTo(a.priority.index));

    // Pick the highest-priority candidate that is not in its cooldown window.
    SmartNotification? best;
    for (final c in candidates) {
      final lastFired = _lastFiredAt[c.type];
      final cooldown  = _typeCooldowns[c.type] ?? const Duration(hours: 6);
      if (lastFired == null || now.difference(lastFired) >= cooldown) {
        best = c;
        break;
      }
    }
    if (best == null) return null;

    // Enrich wording through AI text generator
    final enriched = await _AITextGenerator.enrich(best, ctx);

    _lastFiredAt[enriched.type] = now;
    await _persist(enriched);
    await _fireLocal(enriched);
    return enriched;
  }

  /// Evaluate context and return ALL candidate notifications without firing
  /// them — useful for the in-app preview screen.
  static Future<List<SmartNotification>> preview(
      SmartNotificationContext ctx) async {
    final candidates = _buildCandidates(ctx);
    candidates.sort((a, b) => b.priority.index.compareTo(a.priority.index));

    final enriched = <SmartNotification>[];
    for (final c in candidates) {
      enriched.add(await _AITextGenerator.enrich(c, ctx));
    }
    return enriched;
  }

  /// Fetch the last N smart notifications persisted for the current user.
  static Future<List<SmartNotification>> history({int limit = 20}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    final snap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('smartNotifications')
        .orderBy('generatedAt', descending: true)
        .limit(limit)
        .get();

    return snap.docs
        .map((d) => SmartNotification.fromJson(d.data()))
        .toList();
  }

  /// Load user's smart notification preferences from Firestore.
  static Future<Map<String, bool>> loadPreferences() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return _defaultPrefs;

    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data()?['smartNotifPrefs'] as Map<String, dynamic>?;
    if (data == null) return _defaultPrefs;

    return _defaultPrefs.map(
      (k, v) => MapEntry(k, data[k] as bool? ?? v),
    );
  }

  /// Persist user's smart notification preferences to Firestore.
  static Future<void> savePreferences(Map<String, bool> prefs) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore
        .collection('users')
        .doc(uid)
        .set({'smartNotifPrefs': prefs}, SetOptions(merge: true));
  }

  /// Build context from Firestore — convenience factory for callers that
  /// don't want to assemble SmartNotificationContext manually.
  static Future<SmartNotificationContext> buildContext() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return SmartNotificationContext(
        activity: const UserActivityData(),
        performance: const PerformanceTrendData(
          roundsAnalysed: 0,
          avgScoreDiff: 0,
          avgPuttsPerHole: 2.0,
          avgGirPct: 40,
          avgFairwaysPct: 50,
        ),
        upcomingTeeTimes: [],
      );
    }

    final prefs = await loadPreferences();
    final activity = await _buildActivityData(uid);
    final performance = await _buildPerformanceData(uid);
    final teeTimes = await _fetchUpcomingTeeTimes(uid);

    return SmartNotificationContext(
      activity: activity,
      performance: performance,
      upcomingTeeTimes: teeTimes,
      userPreferences: prefs,
    );
  }

  // ── Rule engine ──────────────────────────────────────────────────────────

  static List<SmartNotification> _buildCandidates(
      SmartNotificationContext ctx) {
    final now = DateTime.now();
    final results = <SmartNotification>[];

    // ── Rule 1: Incomplete round ─────────────────────────────────────────
    if (ctx.preferenceFor(SmartNotificationType.incompleteRound.key) &&
        ctx.activity.hasIncompleteRound) {
      final lastUpdated = ctx.activity.activeRoundLastUpdated;
      final hoursAgo = lastUpdated != null
          ? now.difference(lastUpdated).inHours
          : 0;

      // Only remind if round was left > 30 min but < 24 h ago
      if (hoursAgo >= 0 && hoursAgo < 24) {
        results.add(SmartNotification(
          type: SmartNotificationType.incompleteRound,
          title: 'Resume your round',
          body:
              'You left ${ctx.activity.activeRoundCourse ?? "your round"} '
              'on hole ${ctx.activity.activeRoundHolesPlayed + 1}. '
              'Finish what you started!',
          priority: hoursAgo < 2
              ? NotificationPriority.high
              : NotificationPriority.normal,
          generatedAt: now,
          metadata: {
            'roundId': ctx.activity.activeRoundId,
            'holesPlayed': ctx.activity.activeRoundHolesPlayed,
          },
        ));
      }
    }

    // ── Rule 2: Upcoming tee time ────────────────────────────────────────
    if (ctx.preferenceFor(SmartNotificationType.teeTimeReminder.key)) {
      for (final tt in ctx.upcomingTeeTimes) {
        if (!tt.isWithinReminderWindow) continue;
        final mins = tt.timeUntil.inMinutes;
        final priority = mins <= 60
            ? NotificationPriority.urgent
            : mins <= 180
                ? NotificationPriority.high
                : NotificationPriority.normal;

        results.add(SmartNotification(
          type: SmartNotificationType.teeTimeReminder,
          title: '⛳ Tee time coming up',
          body: 'Your round at ${tt.courseName} starts in '
              '${_formatDuration(tt.timeUntil)}. Time to warm up!',
          priority: priority,
          generatedAt: now,
          metadata: {
            'teeTimeId':  tt.id,
            'courseName': tt.courseName,
            'scheduledAt': tt.scheduledAt.toIso8601String(),
          },
        ));
        break; // only fire for the next upcoming tee time
      }
    }

    // ── Rule 3: Performance trend ────────────────────────────────────────
    // Fires when improving AND has data, OR has enough data to show a summary.
    if (ctx.preferenceFor(SmartNotificationType.performanceTrend.key) &&
        ctx.performance.hasEnoughData) {
      if (ctx.performance.isImproving) {
        final strokes =
            ctx.performance.improvementStrokes?.abs().toStringAsFixed(1) ?? '?';
        results.add(SmartNotification(
          type: SmartNotificationType.performanceTrend,
          title: 'You\'re on a roll 🔥',
          body: 'You\'ve improved by $strokes strokes over your last '
              '${ctx.performance.roundsAnalysed} rounds. Keep the momentum!',
          priority: NotificationPriority.normal,
          generatedAt: now,
          metadata: {
            'improvementStrokes': ctx.performance.improvementStrokes,
            'roundsAnalysed': ctx.performance.roundsAnalysed,
          },
        ));
      } else {
        // Enough data but not yet trending up — show a consistency nudge
        results.add(SmartNotification(
          type: SmartNotificationType.performanceTrend,
          title: 'Your game by the numbers 📊',
          body: 'Avg ${ctx.performance.avgScoreDiff.toStringAsFixed(1)} over par '
              'across ${ctx.performance.roundsAnalysed} rounds. '
              '${ctx.performance.avgGirPct.toStringAsFixed(0)}% GIR, '
              '${ctx.performance.avgPuttsPerHole.toStringAsFixed(1)} putts/hole.',
          priority: NotificationPriority.low,
          generatedAt: now,
          metadata: {'roundsAnalysed': ctx.performance.roundsAnalysed},
        ));
      }
    }

    // ── Rule 4: Weakness-based practice reminder ─────────────────────────
    // Always fires when the preference is on — works even with 0 rounds
    // (falls back to generic weakness area from default stats).
    if (ctx.preferenceFor(SmartNotificationType.weaknessPractice.key)) {
      final daysSince = ctx.activity.daysSinceLastRound ?? 0;
      final weakness = ctx.performance.effectiveWeakness;
      results.add(SmartNotification(
        type: SmartNotificationType.weaknessPractice,
        title: 'Practice focus: ${weakness.label}',
        body: weakness.drillHint,
        priority: daysSince >= 7
            ? NotificationPriority.high
            : daysSince >= 2
                ? NotificationPriority.normal
                : NotificationPriority.low,
        generatedAt: now,
        metadata: {
          'weakness': weakness.name,
          'daysSinceRound': daysSince,
          'avgScoreDiff': ctx.performance.avgScoreDiff,
        },
      ));
    }

    return results;
  }

  // ── Firestore helpers ────────────────────────────────────────────────────

  static Future<UserActivityData> _buildActivityData(String uid) async {
    // Active round
    final activeSnap = await _firestore
        .collection('rounds')
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();

    String? activeId;
    String? activeCourse;
    int holesPlayed = 0;
    int totalHoles = 18;
    DateTime? lastUpdated;

    if (activeSnap.docs.isNotEmpty) {
      final doc  = activeSnap.docs.first;
      final data = doc.data();
      activeId     = doc.id;
      activeCourse = data['courseName'] as String?;
      totalHoles   = (data['totalHoles'] as num?)?.toInt() ?? 18;
      final scores = (data['scores'] as List<dynamic>?) ?? [];
      holesPlayed  = scores.length;
      lastUpdated  = (data['updatedAt'] as Timestamp?)?.toDate() ??
          (data['startedAt'] as Timestamp?)?.toDate();
    }

    // Last completed round — no orderBy to avoid composite index requirement;
    // sort the small result set client-side instead.
    final completedSnap = await _firestore
        .collection('rounds')
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: 'completed')
        .get();

    DateTime? lastCompleted;
    int daysSince = 0;
    if (completedSnap.docs.isNotEmpty) {
      final sorted = completedSnap.docs
        ..sort((a, b) {
          final ta = (a.data()['completedAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          final tb = (b.data()['completedAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          return tb.compareTo(ta);
        });
      lastCompleted =
          (sorted.first.data()['completedAt'] as Timestamp?)?.toDate();
      if (lastCompleted != null) {
        daysSince = DateTime.now().difference(lastCompleted).inDays;
      }
    }

    // Total rounds
    final countSnap = await _firestore
        .collection('rounds')
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: 'completed')
        .count()
        .get();

    return UserActivityData(
      activeRoundId:          activeId,
      activeRoundCourse:      activeCourse,
      activeRoundHolesPlayed: holesPlayed,
      activeRoundTotalHoles:  totalHoles,
      activeRoundLastUpdated: lastUpdated,
      lastCompletedRoundDate: lastCompleted,
      totalRoundsCompleted:   countSnap.count ?? 0,
      daysSinceLastRound:     lastCompleted != null ? daysSince : null,
    );
  }

  static Future<PerformanceTrendData> _buildPerformanceData(
      String uid) async {
    // No orderBy — avoids composite index requirement. Fetch completed rounds
    // and sort + limit client-side.
    final snap = await _firestore
        .collection('rounds')
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: 'completed')
        .get();

    if (snap.docs.isEmpty) {
      return const PerformanceTrendData(
        roundsAnalysed: 0,
        avgScoreDiff: 0,
        avgPuttsPerHole: 2.0,
        avgGirPct: 40,
        avgFairwaysPct: 50,
      );
    }

    // Sort by completedAt descending, take last 10
    final sorted = snap.docs
      ..sort((a, b) {
        final ta = (a.data()['completedAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        final tb = (b.data()['completedAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        return tb.compareTo(ta);
      });
    final recent = sorted.take(10).toList();

    double totalDiff = 0;
    double totalPutts = 0;
    int totalHoles = 0;
    int girCount = 0;
    int fairwayCount = 0;
    int fairwayEligible = 0;
    final diffs = <double>[];

    for (final doc in recent) {
      final data   = doc.data();
      final scores = (data['scores'] as List<dynamic>?) ?? [];

      int roundScore = 0;
      int roundPar   = 0;

      for (final s in scores) {
        final m       = s as Map<String, dynamic>;
        final sc      = (m['score'] as num?)?.toInt() ?? 0;
        final par     = (m['par'] as num?)?.toInt() ?? 4;
        final putts   = (m['putts'] as num?)?.toInt() ?? 0;
        final gir     = m['gir'] as bool? ?? false;
        final fairway = m['fairwayHit'] as bool? ?? false;

        roundScore += sc;
        roundPar   += par;
        totalHoles++;
        totalPutts += putts;
        if (gir) girCount++;
        if (par >= 4) {
          fairwayEligible++;
          if (fairway) fairwayCount++;
        }
      }

      final diff = (roundScore - roundPar).toDouble();
      totalDiff += diff;
      diffs.add(diff);
    }

    final count = recent.length;
    final avgDiff = count > 0 ? totalDiff / count : 0.0;
    final avgPutts = totalHoles > 0 ? totalPutts / totalHoles : 2.0;
    final avgGir = totalHoles > 0 ? girCount / totalHoles * 100 : 40.0;
    final avgFw = fairwayEligible > 0 ? fairwayCount / fairwayEligible * 100 : 50.0;

    // Trend: compare first half vs second half of the window
    double? trendDelta;
    double? improvementStrokes;
    bool improving = false;
    if (diffs.length >= 4) {
      final mid = diffs.length ~/ 2;
      final recent = diffs.take(mid).fold(0.0, (a, b) => a + b) / mid;
      final older  = diffs.skip(mid).fold(0.0, (a, b) => a + b) / (diffs.length - mid);
      trendDelta = recent - older;
      improving  = trendDelta < -0.5; // at least half a stroke improvement
      if (improving) improvementStrokes = trendDelta;
    }

    return PerformanceTrendData(
      roundsAnalysed:     count,
      avgScoreDiff:       avgDiff,
      trendDelta:         trendDelta,
      avgPuttsPerHole:    avgPutts,
      avgGirPct:          avgGir,
      avgFairwaysPct:     avgFw,
      isImproving:        improving,
      improvementStrokes: improvementStrokes,
    );
  }

  static Future<List<TeeTimeData>> _fetchUpcomingTeeTimes(String uid) async {
    final now = Timestamp.fromDate(DateTime.now());
    final snap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('teeTimes')
        .where('scheduledAt', isGreaterThan: now)
        .orderBy('scheduledAt')
        .limit(3)
        .get();

    return snap.docs.map((d) {
      final data = d.data();
      return TeeTimeData(
        id:              d.id,
        courseName:      data['courseName'] as String? ?? 'Unknown Course',
        courseLocation:  data['courseLocation'] as String?,
        scheduledAt:     (data['scheduledAt'] as Timestamp).toDate(),
        numberOfPlayers: data['numberOfPlayers'] as int?,
        notes:           data['notes'] as String?,
      );
    }).toList();
  }

  static Future<void> _persist(SmartNotification notif) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('smartNotifications')
        .add(notif.toJson());
  }

  static Future<void> _fireLocal(SmartNotification notif) async {
    final idMap = {
      SmartNotificationType.weaknessPractice: kSmartNotifWeakness,
      SmartNotificationType.incompleteRound:  kSmartNotifIncomplete,
      SmartNotificationType.performanceTrend: kSmartNotifTrend,
      SmartNotificationType.teeTimeReminder:  kSmartNotifTeeTime,
    };
    final id = idMap[notif.type] ?? kSmartNotifTrend;
    // Delegate to the existing NotificationService infrastructure
    await NotificationService.showSmartNotification(
      id: id,
      title: notif.title,
      body: notif.body,
      payload: notif.type.key,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _formatDuration(Duration d) {
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    if (d.inHours == 1) return '1 hour';
    return '${d.inHours} hours';
  }

  // ── Default preferences ───────────────────────────────────────────────────

  static const Map<String, bool> _defaultPrefs = {
    'weaknessPractice': true,
    'incompleteRound':  true,
    'performanceTrend': true,
    'teeTimeReminder':  true,
  };
}

// ---------------------------------------------------------------------------
// _AITextGenerator — mock AI text enrichment
//
// In production: replace _mockGenerate with a real Gemini / OpenAI call using
// the same prompt-builder pattern as AIRoundSummaryService.
// ---------------------------------------------------------------------------
class _AITextGenerator {
  static Future<SmartNotification> enrich(
    SmartNotification notif,
    SmartNotificationContext ctx,
  ) async {
    // Simulate a brief async delay (mirrors real API latency)
    await Future.delayed(const Duration(milliseconds: 80));

    final generated = _mockGenerate(notif, ctx);
    return SmartNotification(
      type:        notif.type,
      title:       generated['title']!,
      body:        generated['body']!,
      priority:    notif.priority,
      generatedAt: notif.generatedAt,
      metadata:    notif.metadata,
    );
  }

  /// Builds a Gemini-style prompt ready to send to the real API.
  /// Call this from a production AI service to replace _mockGenerate.
  // ignore: unused_element
  static String buildPrompt(
      SmartNotification notif, SmartNotificationContext ctx) {
    final perf = ctx.performance;
    final act  = ctx.activity;
    return '''You are a personal golf coach assistant for the TeeStats app.
Generate a short, engaging push notification for the following scenario.

Type: ${notif.type.label}
User stats: avg ${perf.avgScoreDiff.toStringAsFixed(1)} over par,
  ${perf.avgPuttsPerHole.toStringAsFixed(1)} putts/hole,
  ${perf.avgGirPct.toStringAsFixed(0)}% GIR
Days since last round: ${act.daysSinceLastRound ?? 'unknown'}
Primary weakness: ${perf.effectiveWeakness.label}
${notif.type == SmartNotificationType.incompleteRound ? 'Course: ${act.activeRoundCourse}, hole: ${act.activeRoundHolesPlayed + 1}' : ''}

Return ONLY valid JSON:
{"title":"...","body":"..."}

Rules:
- title: max 6 words, punchy
- body: max 20 words, specific and motivating
- Coach tone, no generic phrases''';
  }

  // ── Mock responses (mirrors what the real API would return) ──────────────

  static Map<String, String> _mockGenerate(
      SmartNotification notif, SmartNotificationContext ctx) {
    switch (notif.type) {
      case SmartNotificationType.weaknessPractice:
        return _weaknessCopy(ctx.performance.effectiveWeakness,
            ctx.activity.daysSinceLastRound ?? 0);

      case SmartNotificationType.incompleteRound:
        return _incompleteCopy(
          ctx.activity.activeRoundCourse ?? 'your round',
          ctx.activity.activeRoundHolesPlayed,
          ctx.activity.activeRoundTotalHoles,
        );

      case SmartNotificationType.performanceTrend:
        return _trendCopy(ctx.performance);

      case SmartNotificationType.teeTimeReminder:
        final tt = ctx.upcomingTeeTimes.firstOrNull;
        if (tt == null) return {'title': notif.title, 'body': notif.body};
        return _teeTimeCopy(tt);
    }
  }

  static Map<String, String> _weaknessCopy(
      WeaknessArea weakness, int daysSince) {
    final Map<WeaknessArea, List<Map<String, String>>> bank = {
      WeaknessArea.putting: [
        {
          'title': 'Your putter needs reps 🎯',
          'body':  '${daysSince}d off the course — 15 min on lag putts today will pay dividends on Sunday.',
        },
        {
          'title': 'Putting is costing you strokes',
          'body':  'Practice 10-footers until you sink 5 in a row. Distance control wins rounds.',
        },
      ],
      WeaknessArea.approach: [
        {
          'title': 'GIR is your scoring key 📐',
          'body':  'Aim for the fat part of greens. More GIRs = fewer bogeys, guaranteed.',
        },
        {
          'title': 'Sharpen those irons 🏌️',
          'body':  'Hit 20 approach shots from 100–150 yards. Pick a target, commit every time.',
        },
      ],
      WeaknessArea.driving: [
        {
          'title': 'Fairways first, distance second',
          'body':  'Swing at 80% today. More fairways = easier approach shots = lower scores.',
        },
        {
          'title': 'Tee shot consistency drill',
          'body':  'Work on your pre-shot routine. Alignment and tempo beat power every round.',
        },
      ],
      WeaknessArea.shortGame: [
        {
          'title': 'Short game = scoring game 🎯',
          'body':  '60% of shots are inside 100 yards. 30 min chipping practice is worth 3 strokes.',
        },
        {
          'title': 'Up-and-down practice session',
          'body':  'Chip from 5 different lies. Up-and-down skill is the fastest handicap reducer.',
        },
      ],
      WeaknessArea.courseManagement: [
        {
          'title': 'Play smart, score lower 🧠',
          'body':  'Before each shot, pick a conservative target and commit fully. Bogeys beat doubles.',
        },
        {
          'title': 'Strategy beats power today',
          'body':  'Visualise your round: where is the safe miss on each hole? Plan before you play.',
        },
      ],
    };

      final options = bank[weakness] ?? [
        {'title': 'Practice time', 'body': 'Hit the range to sharpen your game.'}
      ];
      // Rotate by day of week for variety
      final pick = options[DateTime.now().weekday % options.length];
      return pick;
  }

  static Map<String, String> _incompleteCopy(
      String course, int holesPlayed, int total) {
    final remaining = total - holesPlayed;
    return {
      'title': 'Unfinished business at $course',
      'body':  'You\'re $holesPlayed holes in with $remaining to go. '
               'Resume and finish strong — every hole counts.',
    };
  }

  static Map<String, String> _trendCopy(PerformanceTrendData perf) {
    final strokes = perf.improvementStrokes?.abs().toStringAsFixed(1) ?? '?';
    if (perf.isImproving) {
      return {
        'title': 'You\'re getting better! 📈',
        'body':  'Down $strokes strokes in your last ${perf.roundsAnalysed} rounds. '
                 'You\'re in the best form of your season.',
      };
    }
    return {
      'title': 'Consistency is building 💪',
      'body':  'Your avg is ${perf.avgScoreDiff.toStringAsFixed(1)} over par across '
               '${perf.roundsAnalysed} rounds. Keep showing up — the curve is coming.',
    };
  }

  static Map<String, String> _teeTimeCopy(TeeTimeData tt) {
    final mins = tt.timeUntil.inMinutes;
    if (mins <= 60) {
      return {
        'title': 'Tee off in $mins min ⛳',
        'body':  'Head to ${tt.courseName} now. Arrive 10 min early to loosen up.',
      };
    }
    return {
      'title': 'Tomorrow\'s round awaits 🌅',
      'body':  '${tt.courseName} is on the schedule. Prep your bag tonight for a smooth morning.',
    };
  }
}

// Removed stray top-level constants
