#!/bin/sh

# Start MinIO in background
minio server /data --console-address ":9001" &

# Wait until MinIO is ready (retry until connection works)
until mc alias set myminio http://localhost:9000 $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD 2>/dev/null; do
  echo "Waiting for MinIO to start..."
  sleep 3
done

wait

# Start MinIO server
exec "$@"
