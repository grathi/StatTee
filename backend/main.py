"""
FastAPI entry point for the TeeStats Swing Analyzer Cloud Run service.

POST /process-video  — processes the job synchronously (blocking until done)
GET  /health         — health check

Cloud Run keeps the instance alive for the full request duration (up to 600s).
The Cloud Function fires-and-forgets; it doesn't wait for the response.
"""
from __future__ import annotations

from fastapi import FastAPI
from pydantic import BaseModel

from pipeline.processor import process

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
    try:
        process(req.job_id, req.input_url, req.user_id)
    except Exception:
        pass  # Firestore already updated with status=failed inside process()
    return {"done": True, "job_id": req.job_id}
