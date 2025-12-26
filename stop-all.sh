#!/bin/bash
#===============================================================================
# Quantus - Stop All
#===============================================================================

echo "Zatrzymuję procesy Quantus..."

pkill -f quantus-miner && echo "Miner zatrzymany" || echo "Miner nie był uruchomiony"
pkill -f quantus-node && echo "Node zatrzymany" || echo "Node nie był uruchomiony"

echo "Gotowe"
