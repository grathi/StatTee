"""
Pipeline orchestrator. Runs all stages and updates Firestore progress.
"""
from __future__ import annotations

import subprocess
import tempfile
import shutil
from pathlib import Path

import cv2

import firebase_client as fc
from pipeline import detector, tracker, trajectory, renderer


def process(job_id: str, input_url: str, user_id: str) -> None:
    """
    Full pipeline:
      download → extract frames → detect → track → smooth
      → render → encode → upload → update Firestore
    """
    workdir = Path(tempfile.mkdtemp(prefix=f"swing_{job_id}_"))
    try:
        _run(job_id, input_url, user_id, workdir)
    except Exception as exc:
        fc.update_job(job_id, status="failed", errorMessage=str(exc))
        raise
    finally:
        shutil.rmtree(workdir, ignore_errors=True)


def _run(job_id: str, input_url: str, user_id: str, workdir: Path) -> None:
    input_mp4   = workdir / "input.mp4"
    frames_dir  = workdir / "frames"
    out_frames  = workdir / "out_frames"
    output_mp4  = workdir / "output.mp4"
    frames_dir.mkdir()

    # ── Stage 1: Download ──────────────────────────────────────────────────
    fc.update_job(job_id, status="processing", progress=5)
    raw_mp4 = workdir / "raw.mp4"
    fc.download_video(input_url, str(raw_mp4))

    # ── Stage 1b: Transcode to H.264 (handles Dolby Vision / HEVC / HDR) ───
    fc.update_job(job_id, progress=10)
    _transcode_to_h264(raw_mp4, input_mp4)

    # ── Stage 2: Extract frames (capped at 30 fps) ─────────────────────────
    fc.update_job(job_id, progress=15)
    fps, frame_w, frame_h = _extract_frames(input_mp4, frames_dir)

    # ── Stage 3: Detect ────────────────────────────────────────────────────
    fc.update_job(job_id, progress=20)
    job_doc   = fc.get_job(job_id)
    ball_hint = job_doc.get("ballHint")   # {'x': 0–1, 'y': 0–1} or None
    detections, impact_frame = detector.detect_all(
        frames_dir,
        ball_hint=ball_hint,
        frame_w=frame_w,
        frame_h=frame_h,
    )

    # ── Stage 4: Track ─────────────────────────────────────────────────────
    fc.update_job(job_id, progress=50)
    hint_px = (
        (ball_hint["x"] * frame_w, ball_hint["y"] * frame_h)
        if ball_hint else None
    )
    tracked = tracker.track(
        detections,
        impact_frame=impact_frame,
        fps=fps,
        hint_px=hint_px,
    )

    # ── Stage 5: Smooth & metrics ──────────────────────────────────────────
    fc.update_job(job_id, progress=60)
    ball_path, shot_data = trajectory.smooth(tracked, fps, frame_w, frame_h)

    # ── Stage 6: Render overlay ────────────────────────────────────────────
    fc.update_job(job_id, progress=70)
    renderer.draw_overlay(frames_dir, tracked, out_frames)

    # ── Stage 7: Encode output video ───────────────────────────────────────
    fc.update_job(job_id, progress=85)
    renderer.encode_video(out_frames, output_mp4, fps)

    # ── Stage 8: Upload output video ───────────────────────────────────────
    fc.update_job(job_id, progress=90)
    gs_dest = input_url.replace("/input.mp4", "/output.mp4")
    output_url = fc.upload_video(str(output_mp4), gs_dest)

    # ── Stage 9: Update Firestore ──────────────────────────────────────────
    fc.update_job(
        job_id,
        status="completed",
        progress=100,
        outputVideoUrl=output_url,
        ballPath=ball_path,
        shotData=shot_data,
    )


def _extract_frames(input_mp4: Path, frames_dir: Path) -> tuple[float, int, int]:
    """Extract frames (capped at 30 fps) and return (fps, width, height)."""
    cap = cv2.VideoCapture(str(input_mp4))
    src_fps = cap.get(cv2.CAP_PROP_FPS) or 30.0
    frame_w = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    frame_h = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    cap.release()

    capped_fps = min(src_fps, 30.0)

    subprocess.run(
        [
            "ffmpeg", "-y", "-i", str(input_mp4),
            "-vf", f"fps={capped_fps}",
            "-q:v", "4",          # slightly lower quality → smaller files, faster I/O
            str(frames_dir / "%06d.jpg"),
        ],
        check=True,
        capture_output=True,
    )
    return capped_fps, frame_w, frame_h


def _transcode_to_h264(src: Path, dst: Path) -> None:
    """Transcode any input video (Dolby Vision, HEVC, HDR) to H.264 / AAC.

    This ensures:
    - cv2.VideoCapture can read the file reliably on Linux (no Dolby Vision decoder)
    - The output video is playable on all Android devices via ExoPlayer
    - Frame dimensions are accurate before inference
    """
    subprocess.run(
        [
            "ffmpeg", "-y", "-i", str(src),
            # Video: libx264, fast preset, visually lossless for analysis
            "-c:v", "libx264", "-preset", "fast", "-crf", "18",
            # Strip HDR metadata / colour space → standard BT.709
            "-vf", "scale=in_color_matrix=bt2020:out_color_matrix=bt709",
            "-color_primaries", "bt709",
            "-color_trc", "bt709",
            "-colorspace", "bt709",
            # Audio: pass through as AAC (no-op if already AAC)
            "-c:a", "aac", "-b:a", "128k",
            # Move moov atom to front for fast streaming
            "-movflags", "+faststart",
            str(dst),
        ],
        check=True,
        capture_output=True,
    )
