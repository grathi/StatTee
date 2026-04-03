import 'package:cloud_firestore/cloud_firestore.dart';

// ── Async job tracking (Cloud Run pipeline) ───────────────────────────────────

enum SwingJobState { queued, processing, completed, failed }

class SwingJobStatus {
  final String jobId;
  final SwingJobState state;
  final int progress;
  final String? outputVideoUrl;
  final List<BallPoint> ballPath;
  final ShotData? shotData;
  final String? errorMessage;

  const SwingJobStatus({
    required this.jobId,
    required this.state,
    required this.progress,
    this.outputVideoUrl,
    required this.ballPath,
    this.shotData,
    this.errorMessage,
  });

  factory SwingJobStatus.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final statusStr = d['status'] as String? ?? 'queued';
    final state = switch (statusStr) {
      'processing' => SwingJobState.processing,
      'completed'  => SwingJobState.completed,
      'failed'     => SwingJobState.failed,
      _            => SwingJobState.queued,
    };

    final rawPath = d['ballPath'] as List? ?? [];
    final ballPath = rawPath
        .map((p) => BallPoint.fromJson(p as Map<String, dynamic>))
        .toList();

    final rawShot = d['shotData'] as Map<String, dynamic>?;

    return SwingJobStatus(
      jobId: doc.id,
      state: state,
      progress: (d['progress'] as num?)?.toInt() ?? 0,
      outputVideoUrl: d['outputVideoUrl'] as String?,
      ballPath: ballPath,
      shotData: rawShot != null ? ShotData.fromJson(rawShot) : null,
      errorMessage: d['errorMessage'] as String?,
    );
  }
}

// ── Ball point ────────────────────────────────────────────────────────────────

class BallPoint {
  final int t;       // milliseconds from video start
  final double x;    // 0.0–1.0 normalized (left→right)
  final double y;    // 0.0–1.0 normalized (top→bottom)

  const BallPoint({required this.t, required this.x, required this.y});

  factory BallPoint.fromJson(Map<String, dynamic> j) => BallPoint(
        t: (j['t'] as num).toInt(),
        x: (j['x'] as num).toDouble() / 1000.0,
        y: (j['y'] as num).toDouble() / 1000.0,
      );

  Map<String, dynamic> toJson() => {
        't': t,
        'x': (x * 1000).round(),
        'y': (y * 1000).round(),
      };
}

class ShotData {
  final double carryYards;
  final double maxHeightYards;
  final double launchAngle;

  const ShotData({
    required this.carryYards,
    required this.maxHeightYards,
    required this.launchAngle,
  });

  factory ShotData.fromJson(Map<String, dynamic> j) => ShotData(
        carryYards: (j['carry_yards'] as num?)?.toDouble() ?? 0,
        maxHeightYards: (j['max_height_yards'] as num?)?.toDouble() ?? 0,
        launchAngle: (j['launch_angle'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'carry_yards': carryYards,
        'max_height_yards': maxHeightYards,
        'launch_angle': launchAngle,
      };
}

class SwingAnalysis {
  final String? id;
  final String userId;
  final DateTime createdAt;
  final String? videoLocalPath;
  final String? outputVideoUrl;
  final List<BallPoint> ballPath;
  final ShotData shotData;

  const SwingAnalysis({
    this.id,
    required this.userId,
    required this.createdAt,
    this.videoLocalPath,
    this.outputVideoUrl,
    required this.ballPath,
    required this.shotData,
  });

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'createdAt': Timestamp.fromDate(createdAt),
        'ballPath': ballPath.map((p) => p.toJson()).toList(),
        'shotData': shotData.toJson(),
        if (outputVideoUrl != null) 'outputVideoUrl': outputVideoUrl,
        // videoLocalPath intentionally not stored — device-local only
      };

  factory SwingAnalysis.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SwingAnalysis(
      id: doc.id,
      userId: d['userId'] as String,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      outputVideoUrl: d['outputVideoUrl'] as String?,
      ballPath: (d['ballPath'] as List)
          .map((p) => BallPoint.fromJson(p as Map<String, dynamic>))
          .toList(),
      shotData: ShotData.fromJson(d['shotData'] as Map<String, dynamic>),
    );
  }
}
