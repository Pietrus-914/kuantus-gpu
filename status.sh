#!/bin/bash
#===============================================================================
# Quantus - Status
#===============================================================================

echo "═══════════════════════════════════════════════════════════"
echo " QUANTUS STATUS"
echo "═══════════════════════════════════════════════════════════"

echo ""
echo "PROCESY:"
ps aux | grep -E "quantus-(miner|node)" | grep -v grep || echo "  Brak uruchomionych"

echo ""
echo "GPU:"
nvidia-smi --query-gpu=index,name,utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv 2>/dev/null || echo "  Brak GPU"

echo ""
echo "OSTATNIE LOGI MINERA:"
tail -5 /var/lib/quantus/miner.log 2>/dev/null || echo "  Brak logów"

echo ""
echo "OSTATNIE LOGI NODE:"
tail -5 /var/lib/quantus/node.log 2>/dev/null || echo "  Brak logów"
echo ""
