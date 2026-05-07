#!/bin/bash

TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)

echo "Launching llama-server..."

~/Development/ai/tools/llama-cpp/llama-server \
  -m ~/Development/ai/models/llm/Qwen3.6-27B-IQ4_XS.gguf \
  --mmproj ~/Development/ai/models/llm/Qwen3.6-27b-mmproj-F16.gguf \
  --alias qwen3.6 \
  --ctx-size 65536 \
  --n-gpu-layers 99 \
  -fa on \
  --cache-type-k q8_0 \
  --cache-type-v q8_0 \
  --batch-size 2048 \
  --ubatch-size 512 \
  --jinja \
  --temp 1.0 \
  --top-p 0.95 \
  --top-k 20 \
  --min-p 0.0 \
  --presence-penalty 0.0 \
  --repeat-penalty 1.0 \
  --host 127.0.0.1 \
  --port 11434 \
  >~/Development/ai/logs/chat/llama-server_$TIMESTAMP.txt 2>&1 &

echo "Waiting for llama-server to be ready..."
until curl -sf http://127.0.0.1:11434/health >/dev/null; do
  sleep 1
done
echo "Loaded llama-server: launching searnxg..."

docker-compose --project-directory ~/Development/ai/tools/searxng up -d

if docker container inspect open-webui >/dev/null 2>&1; then
  docker start open-webui >/dev/null
else
  docker run -d \
    -p 3000:8080 \
    -v open-webui:/app/backend/data \
    -e OPENAI_API_BASE_URL=http://host.docker.internal:11434/v1 \
    -e OPENAI_API_KEY=sk-no-key \
    --add-host=host.docker.internal:host-gateway \
    --name open-webui \
    --restart no \
    ghcr.io/open-webui/open-webui:main >/dev/null
fi

echo "Waiting for open-webui to be ready..."
until curl -sf http://127.0.0.1:3000/health >/dev/null 2>&1; do
  sleep 1
done

echo "All loaded! Opening browser..."
xdg-open "http://127.0.0.1:3000/" >/dev/null 2>&1 &

echo "Goodbye."
