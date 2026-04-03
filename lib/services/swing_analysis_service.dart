import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/painting.dart' show Offset;
import '../models/swing_analysis.dart';

class SwingAnalysisService {
  static final _db = FirebaseFirestore.instance;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Upload video to Firebase Storage, create a swingJobs doc, and return a
  /// live stream of job status updates. The stream completes when the job
  /// reaches 'completed' or 'failed'.
  static Future<Stream<SwingJobStatus>> analyzeVideo(
    File videoFile, {
    Offset? ballHint,
    void Function(double progress)? onProgress,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final jobId = _db.collection('swingJobs').doc().id;

    // 1. Upload input video to Storage, reporting upload progress via onProgress.
    // Using putData (not putFile) to avoid iOS "cannot parse response" errors
    // that occur with image-picker temp file paths on iOS.
    final bucket = FirebaseStorage.instance.bucket;
    final ref = FirebaseStorage.instance
        .ref('swings/$uid/$jobId/input.mp4');
    final bytes = await videoFile.readAsBytes();
    final metadata = SettableMetadata(contentType: 'video/mp4');
    final task = ref.putData(bytes, metadata);
    task.snapshotEvents.listen((snapshot) {
      if (snapshot.totalBytes > 0) {
        onProgress?.call(snapshot.bytesTransferred / snapshot.totalBytes);
      }
    });
    await task;

    // 2. Create Firestore job document — triggers Cloud Function
    await _db.collection('swingJobs').doc(jobId).set({
      'jobId': jobId,
      'userId': uid,
      'status': 'queued',
      'progress': 0,
      'inputUrl': 'gs://$bucket/swings/$uid/$jobId/input.mp4',
      'createdAt': FieldValue.serverTimestamp(),
      if (ballHint != null)
        'ballHint': {'x': ballHint.dx, 'y': ballHint.dy},
    });

    // 3. Return a live stream of job status
    return _db
        .collection('swingJobs')
        .doc(jobId)
        .snapshots()
        .map(SwingJobStatus.fromFirestore);
  }

  /// Persist a completed analysis to Firestore history (without video bytes).
  static Future<SwingAnalysis> saveAnalysis(SwingAnalysis analysis) async {
    final ref = await _db
        .collection('users')
        .doc(analysis.userId)
        .collection('swingAnalyses')
        .add(analysis.toFirestore());
    return SwingAnalysis(
      id: ref.id,
      userId: analysis.userId,
      createdAt: analysis.createdAt,
      videoLocalPath: analysis.videoLocalPath,
      outputVideoUrl: analysis.outputVideoUrl,
      ballPath: analysis.ballPath,
      shotData: analysis.shotData,
    );
  }

  /// Stream of saved analyses for the current user.
  static Stream<List<SwingAnalysis>> getAnalysesStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('users')
        .doc(uid)
        .collection('swingAnalyses')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(SwingAnalysis.fromFirestore).toList());
  }
}

