#!/bin/bash
#===============================================================================
# Quantus GPU Miner - Start
#===============================================================================

# Wymagane dla GPU Vulkan
export XDG_RUNTIME_DIR=/tmp

CPU_WORKERS="${1:-4}"
GPU_WORKERS="${2:-1}"

echo "Uruchamiam GPU Miner (CPU: $CPU_WORKERS, GPU: $GPU_WORKERS)..."
echo "Ctrl+C aby zatrzymać"
echo ""

quantus-miner serve --cpu-workers "$CPU_WORKERS" --gpu-workers "$GPU_WORKERS"
