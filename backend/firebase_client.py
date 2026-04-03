import uuid
import firebase_admin
from firebase_admin import firestore, storage as fb_storage
from google.cloud import storage as gcs

# Initialise Firebase Admin once (Cloud Run uses ADC / service account automatically)
if not firebase_admin._apps:
    firebase_admin.initialize_app()

_db = firestore.client()


def update_job(job_id: str, **fields) -> None:
    _db.collection("swingJobs").document(job_id).update(fields)


def get_job(job_id: str) -> dict:
    doc = _db.collection("swingJobs").document(job_id).get()
    return doc.to_dict() or {}


def download_video(gs_uri: str, dest_path: str) -> None:
    """Download a gs:// URI to a local path."""
    assert gs_uri.startswith("gs://"), f"Expected gs:// URI, got: {gs_uri}"
    without_prefix = gs_uri[5:]
    bucket_name, blob_path = without_prefix.split("/", 1)
    client = gcs.Client()
    blob = client.bucket(bucket_name).blob(blob_path)
    blob.download_to_filename(dest_path)


def upload_video(local_path: str, gs_dest: str) -> str:
    """
    Upload a local file to GCS and return a permanent Firebase Storage download URL.
    Uses a download token stored in blob metadata — no private key required on Cloud Run.
    """
    assert gs_dest.startswith("gs://")
    without_prefix = gs_dest[5:]
    bucket_name, blob_path = without_prefix.split("/", 1)

    bucket = fb_storage.bucket(name=bucket_name)
    blob = bucket.blob(blob_path)
    blob.upload_from_filename(local_path, content_type="video/mp4")

    # Attach a Firebase Storage download token so Flutter can use getDownloadURL()
    token = str(uuid.uuid4())
    blob.metadata = {"firebaseStorageDownloadTokens": token}
    blob.patch()

    encoded_path = blob_path.replace("/", "%2F")
    url = (
        f"https://firebasestorage.googleapis.com/v0/b/{bucket_name}"
        f"/o/{encoded_path}?alt=media&token={token}"
    )
    return url
