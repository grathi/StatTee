"""
FastAPI entry point for the TeeStats Swing Analyzer Cloud Run service.

POST /process-video  — processes the job synchronously (blocking until done)
GET  /health         — health check

Cloud Run keeps the instance alive for the full request duration (up to 600s).
The Cloud Function fires-and-forgets; it doesn't wait for the response.
"""
from __future__ import annotations

import logging
import traceback

from fastapi import FastAPI
from pydantic import BaseModel

from pipeline.processor import process

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="TeeStats Swing Analyzer")


class ProcessVideoRequest(BaseModel):
    job_id: str
    input_url: str
    user_id: str


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}


@app.post("/process-video")
def process_video(req: ProcessVideoRequest) -> dict:
    """
    Processes the job synchronously so Cloud Run keeps the instance alive
    for the full duration. Returns when done (or failed).
    The calling Cloud Function uses a short abort timeout and ignores the response.
    """
    logger.info("[main] Starting job %s for user %s", req.job_id, req.user_id)
    try:
        process(req.job_id, req.input_url, req.user_id)
        logger.info("[main] Job %s completed successfully", req.job_id)
    except Exception as exc:
        # process() already attempted fc.update_job(status="failed") internally.
        # Log the full traceback here so Cloud Run logs capture the root cause.
        logger.error(
            "[main] Job %s FAILED: %s\n%s",
            req.job_id, exc, traceback.format_exc(),
        )
    return {"done": True, "job_id": req.job_id}
