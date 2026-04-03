FROM python:3.11-slim

RUN apt-get update && apt-get install -y ffmpeg libgl1 wget libglib2.0-0 && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Pre-download YOLO golf ball weights at build time.
# Pass YOLO_MODEL_URL as a build-arg:
#   gcloud run deploy ... --set-build-env-vars YOLO_MODEL_URL=https://...
# If not provided, the model falls back to YOLOv8n COCO (sports ball) at runtime.
ARG YOLO_MODEL_URL=""
RUN mkdir -p /app/models && \
    if [ -n "$YOLO_MODEL_URL" ]; then \
      wget -q -O /app/models/golfball.pt "$YOLO_MODEL_URL" && \
      echo "YOLO golf ball weights downloaded OK"; \
    else \
      echo "No YOLO_MODEL_URL — YOLOv8n COCO fallback will be used at runtime"; \
    fi

COPY . .

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
