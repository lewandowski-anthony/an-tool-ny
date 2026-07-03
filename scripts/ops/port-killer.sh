#!/bin/bash

PORT=$1

if [ -z "$PORT" ]; then
    echo "Error: You must specify a port."
    echo "Usage: $0 <port> (e.g., $0 8080)"
    exit 1
fi

echo "Searching for process occupying port ${PORT}..."

PID=$(lsof -t -i:"$PORT" -sTCP:LISTEN)

if [ -z "$PID" ]; then
    echo "Port ${PORT} is already free. No action required."
    exit 0
fi

PROCESS_NAME=$(ps -p "$PID" -o comm= 2>/dev/null)

echo "Process found (PID: $PID, Name: $PROCESS_NAME)"

if [[ "$PROCESS_NAME" == *"com.docker"* || "$PROCESS_NAME" == *"vpnkit"* ]]; then
    echo "Docker process detected. Trying to identify the container..."

    CONTAINER_ID=$(docker ps --format '{{.ID}}\t{{.Ports}}' | grep "0.0.0.0:${PORT}" | awk '{print $1}')

    if [ -n "$CONTAINER_ID" ]; then
        CONTAINER_NAME=$(docker ps --filter "id=$CONTAINER_ID" --format '{{.Names}}')
        echo "Stopping Docker container cleanly: ${CONTAINER_NAME} (${CONTAINER_ID})..."
        docker stop "$CONTAINER_ID" > /dev/null
        echo "Docker container stopped successfully."
        exit 0
    else
        echo "Unable to target the exact container. Forcing Docker process termination..."
    fi
fi

if [[ "$PROCESS_NAME" == *"java"* ]]; then
    echo "Java process detected."
fi

echo "Killing process ${PID}..."
kill -9 "$PID" 2>/dev/null

sleep 0.2
if ! lsof -t -i:"$PORT" -sTCP:LISTEN > /dev/null; then
    echo "Port ${PORT} freed successfully."
else
    echo "Failed to free port ${PORT}. The process might require sudo privileges."
    echo "Try: sudo $0 $PORT"
fi