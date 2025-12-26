#!/bin/bash
#===============================================================================
# Quantus Network - GPU Mining Installer dla Vast.ai
# Działa z siecią Dirac, RTX 4090 przetestowane
#===============================================================================

set -e

# Sprawdź root
if [[ $EUID -ne 0 ]]; then
    echo "Ten skrypt wymaga uprawnień root. Uruchom: sudo $0"
    exit 1
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; exit 1; }

#===============================================================================
# KONFIGURACJA
#===============================================================================
NODENAME="${NODENAME:-VastAI-Miner}"
CHAIN="dirac"
MINER_VERSION="v2.0.2"
BASE_PATH="/var/lib/quantus"
SEED_FILE="/root/seed.txt"

# Wymagane dla GPU (Vulkan)
export XDG_RUNTIME_DIR=/tmp

#===============================================================================
# INSTALACJA ZALEŻNOŚCI
#===============================================================================
install_deps() {
    log "Instalacja zależności..."
    apt-get update
    apt-get install -y \
        build-essential cmake pkg-config libssl-dev git clang curl wget \
        tmux jq protobuf-compiler libprotobuf-dev \
        vulkan-tools mesa-vulkan-drivers
    log "Zależności zainstalowane"
}

#===============================================================================
# INSTALACJA RUST
#===============================================================================
install_rust() {
    if command -v rustc &> /dev/null; then
        log "Rust już zainstalowany: $(rustc --version)"
    else
        log "Instalacja Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    fi
    
    source "$HOME/.cargo/env"
    rustup default nightly
    rustup update nightly
    rustup target add wasm32-unknown-unknown --toolchain nightly
    log "Rust gotowy: $(rustc --version)"
}

#===============================================================================
# BUDOWANIE NODE
#===============================================================================
build_node() {
    log "Budowanie Quantus Node (10-30 min)..."
    cd /root
    
    # Usuń stary folder jeśli nie jest git repo
    if [[ -d "chain" ]] && [[ ! -d "chain/.git" ]]; then
        rm -rf chain
    fi
    
    if [[ -d "chain/.git" ]]; then
        cd chain && git pull
    else
        git clone https://github.com/Quantus-Network/chain.git
        cd chain
    fi
    
    source "$HOME/.cargo/env"
    cargo build --release
    
    cp target/release/quantus-node /usr/local/bin/
    chmod +x /usr/local/bin/quantus-node
    log "Node zainstalowany: $(quantus-node --version)"
}

#===============================================================================
# SPRAWDZENIE GPU
#===============================================================================
check_gpu() {
    log "Sprawdzanie GPU..."
    
    if ! command -v nvidia-smi &> /dev/null; then
        error "nvidia-smi nie znalezione! Zainstaluj sterowniki NVIDIA."
    fi
    
    nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
    log "GPU wykryte"
}

#===============================================================================
# POBIERANIE MINERA GPU
#===============================================================================
install_miner() {
    log "Pobieranie GPU Miner ${MINER_VERSION}..."
    
    wget -q -O /usr/local/bin/quantus-miner \
        "https://github.com/Quantus-Network/quantus-miner/releases/download/${MINER_VERSION}/quantus-miner-linux-x86_64-gpu"
    
    chmod +x /usr/local/bin/quantus-miner
    log "Miner zainstalowany: $(quantus-miner --version)"
}

#===============================================================================
# TEST GPU MINERA
#===============================================================================
test_gpu_miner() {
    log "Testowanie GPU minera..."
    
    # Krótki test czy miner wykrywa GPU
    timeout 5 quantus-miner serve --cpu-workers 0 --gpu-workers 1 2>&1 | head -20 || true
    
    # Sprawdź czy nie było błędu GPU
    if timeout 3 quantus-miner serve --cpu-workers 0 --gpu-workers 1 2>&1 | grep -q "No suitable GPU"; then
        warn "Miner nie wykrywa GPU! Sprawdź Vulkan."
    else
        log "GPU miner OK"
    fi
}

#===============================================================================
# GENEROWANIE KLUCZY
#===============================================================================
generate_keys() {
    mkdir -p "$BASE_PATH"
    mkdir -p /root/chain
    
    if [[ ! -f "$SEED_FILE" ]]; then
        log "Generowanie kluczy..."
        
        KEYGEN=$(/usr/local/bin/quantus-node key generate --scheme dilithium 2>&1)
        echo "$KEYGEN" > "$SEED_FILE"
        
        # Wyciągnij SS58 Address
        SS58_ADDR=$(echo "$KEYGEN" | grep "SS58 Address" | awk '{print $NF}')
        echo "SS58_ADDRESS=$SS58_ADDR" >> "$SEED_FILE"
        
        log "Klucze zapisane w: $SEED_FILE"
        warn "ZRÓB BACKUP TEGO PLIKU!"
    else
        log "Klucze już istnieją"
    fi
    
    # Node key
    if [[ ! -f "/root/chain/node-key" ]]; then
        /usr/local/bin/quantus-node key generate-node-key --file /root/chain/node-key 2>&1 | tee -a "$SEED_FILE"
        log "Node key wygenerowany"
    fi
}

#===============================================================================
# PEŁNA INSTALACJA
#===============================================================================
install_full() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║   QUANTUS GPU MINER - INSTALACJA (Vast.ai)                ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    check_gpu
    install_deps
    install_rust
    build_node
    install_miner
    generate_keys
    test_gpu_miner
    
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN} INSTALACJA ZAKOŃCZONA!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  Klucze: ${CYAN}/root/seed.txt${NC} - ZRÓB BACKUP!"
    echo ""
    echo -e "  Uruchomienie:"
    echo -e "    ${YELLOW}./start-all.sh [nazwa]${NC}  - uruchom node + miner"
    echo -e "    ${YELLOW}./start-node.sh${NC}        - tylko node"
    echo -e "    ${YELLOW}./start-miner.sh${NC}       - tylko miner"
    echo ""
}

#===============================================================================
# MAIN
#===============================================================================
case "${1:-install}" in
    install|install-full)
        install_full
        ;;
    deps)
        install_deps
        ;;
    miner)
        install_miner
        ;;
    node)
        install_rust
        build_node
        ;;
    keys)
        generate_keys
        ;;
    *)
        echo "Użycie: $0 [install|deps|miner|node|keys]"
        ;;
esac
