#!/bin/bash
#===============================================================================
# Quantus Node - Start
#===============================================================================

export XDG_RUNTIME_DIR=/tmp

NODENAME="${1:-VastAI-Miner}"
CHAIN="dirac"
BASE_PATH="/var/lib/quantus"
SEED_FILE="/root/seed.txt"

# Pobierz SS58 address
if [[ -f "$SEED_FILE" ]]; then
    REWARDS_ADDR=$(grep "SS58 Address" "$SEED_FILE" | awk '{print $NF}')
    if [[ -z "$REWARDS_ADDR" ]]; then
        REWARDS_ADDR=$(grep "SS58_ADDRESS" "$SEED_FILE" | cut -d'=' -f2)
    fi
else
    echo "Błąd: Brak pliku $SEED_FILE - uruchom najpierw install.sh"
    exit 1
fi

if [[ -z "$REWARDS_ADDR" ]]; then
    echo "Błąd: Nie znaleziono SS58 Address w $SEED_FILE"
    exit 1
fi

# Sprawdź node-key
if [[ ! -f "/root/chain/node-key" ]]; then
    echo "Błąd: Brak /root/chain/node-key - uruchom najpierw install.sh"
    exit 1
fi

echo "Uruchamiam Node: $NODENAME"
echo "Chain: $CHAIN"
echo "Rewards: $REWARDS_ADDR"
echo ""

quantus-node \
    --validator \
    --chain "$CHAIN" \
    --base-path "$BASE_PATH" \
    --name "$NODENAME" \
    --rewards-address "$REWARDS_ADDR" \
    --node-key-file /root/chain/node-key \
    --rpc-external \
    --rpc-methods unsafe \
    --rpc-cors all \
    --enable-peer-sharing \
    --out-peers 50 \
    --in-peers 100 \
    --allow-private-ip \
    --external-miner-url http://127.0.0.1:9833
