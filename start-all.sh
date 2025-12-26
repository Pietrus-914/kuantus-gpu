#!/bin/bash
#===============================================================================
# Quantus - Start All (node + miner w tle)
# Kolejność: NODE najpierw, potem MINER
#===============================================================================

export XDG_RUNTIME_DIR=/tmp

NODENAME="${1:-VastAI-Miner}"
CPU_WORKERS="${2:-4}"
GPU_WORKERS="${3:-1}"

MINER_LOG="/var/lib/quantus/miner.log"
NODE_LOG="/var/lib/quantus/node.log"
SEED_FILE="/root/seed.txt"

mkdir -p /var/lib/quantus

echo "═══════════════════════════════════════════════════════════"
echo " Quantus GPU Mining - Start All"
echo "═══════════════════════════════════════════════════════════"

# Sprawdź klucze
if [[ ! -f "$SEED_FILE" ]]; then
    echo "Błąd: Brak pliku $SEED_FILE"
    echo "Uruchom najpierw: ./install.sh"
    exit 1
fi

REWARDS_ADDR=$(grep "SS58 Address" "$SEED_FILE" | awk '{print $NF}')
if [[ -z "$REWARDS_ADDR" ]]; then
    REWARDS_ADDR=$(grep "SS58_ADDRESS" "$SEED_FILE" | cut -d'=' -f2)
fi

if [[ -z "$REWARDS_ADDR" ]]; then
    echo "Błąd: Nie znaleziono SS58 Address w $SEED_FILE"
    exit 1
fi

# Sprawdź node-key
if [[ ! -f "/root/chain/node-key" ]]; then
    echo "Błąd: Brak /root/chain/node-key"
    echo "Uruchom najpierw: ./install.sh"
    exit 1
fi

# Zatrzymaj poprzednie procesy
pkill -f quantus-node 2>/dev/null || true
pkill -f quantus-miner 2>/dev/null || true
sleep 2

# KROK 1: Uruchom NODE najpierw
echo ""
echo "[1/2] Uruchamiam Node: $NODENAME..."
echo "      Rewards: $REWARDS_ADDR"

nohup bash -c "export XDG_RUNTIME_DIR=/tmp && quantus-node \
    --validator \
    --chain dirac \
    --base-path /var/lib/quantus \
    --name '$NODENAME' \
    --rewards-address $REWARDS_ADDR \
    --node-key-file /root/chain/node-key \
    --rpc-external \
    --rpc-methods unsafe \
    --rpc-cors all \
    --enable-peer-sharing \
    --out-peers 50 \
    --in-peers 100 \
    --allow-private-ip \
    --external-miner-url http://127.0.0.1:9833" > "$NODE_LOG" 2>&1 &
NODE_PID=$!
echo "      PID: $NODE_PID"
echo "      Log: $NODE_LOG"

# Poczekaj chwilę na start node
echo ""
echo "      Czekam na start node..."
sleep 5

# KROK 2: Uruchom MINER
echo ""
echo "[2/2] Uruchamiam GPU Miner (CPU: $CPU_WORKERS, GPU: $GPU_WORKERS)..."

nohup bash -c "export XDG_RUNTIME_DIR=/tmp && quantus-miner serve --cpu-workers $CPU_WORKERS --gpu-workers $GPU_WORKERS" > "$MINER_LOG" 2>&1 &
MINER_PID=$!
echo "      PID: $MINER_PID"
echo "      Log: $MINER_LOG"

sleep 2

echo ""
echo "═══════════════════════════════════════════════════════════"
echo " URUCHOMIONE!"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo " Node:   $NODENAME (PID: $NODE_PID)"
echo " Miner:  CPU=$CPU_WORKERS, GPU=$GPU_WORKERS (PID: $MINER_PID)"
echo ""
echo " Komendy:"
echo "   Logi node:     tail -f $NODE_LOG"
echo "   Logi miner:    tail -f $MINER_LOG"
echo "   Status GPU:    nvidia-smi"
echo "   Status:        ./status.sh"
echo "   Zatrzymanie:   ./stop-all.sh"
echo ""
