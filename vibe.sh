#!/bin/bash

TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)

echo "Launching llama-server..."

~/Development/ai/tools/llama-cpp/llama-server \
  -m ~/Development/ai/models/llm/Qwen3.6-27B-IQ4_XS.gguf \
  --alias qwen3.6 \
  --ctx-size 131072 \
  --n-gpu-layers 99 \
  --flash-attn on \
  --cache-type-k q4_0 \
  --cache-type-v q4_0 \
  --batch-size 2048 \
  --ubatch-size 512 \
  --jinja \
  --temp 0.7 \
  --top-p 0.8 \
  --top-k 20 \
  --min-p 0.0 \
  --repeat-penalty 1.05 \
  --cache-reuse 256 \
  --host 127.0.0.1 \
  --port 11434 \
  >~/Development/ai/logs/vibe/llama-server_$TIMESTAMP.txt 2>&1 &

echo "Waiting for llama-server to be ready..."
until curl -sf http://127.0.0.1:11434/health >/dev/null; do
  sleep 1
done
echo "Server ready: launching opencode..."

OPENCODE_ENABLE_EXA=1 opencode --model llama.cpp/qwen3.6

killall llama-server

echo "Killed llama-server: goodbye!"
