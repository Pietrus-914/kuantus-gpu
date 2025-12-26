# Quantus GPU Mining - Vast.ai

Skrypty do uruchomienia GPU miningu Quantus Network na Vast.ai.

**Przetestowane:** RTX 4090, Ubuntu 22.04, sieć Dirac

---

## ⚡ Szybki start

```bash
# 1. Sklonuj repo
git clone https://github.com/Pietrus-914/kuantus-gpu.git
cd kuantus-gpu

# 2. Nadaj uprawnienia
chmod +x *.sh

# 3. Zainstaluj (10-30 min)
./install.sh

# 4. ZRÓB BACKUP KLUCZY! (skopiuj zawartość)
cat /root/seed.txt

# 5. Uruchom wszystko
./start-all.sh "TwojaNazwaNode"
```

---

## 📋 Kolejność uruchamiania

**WAŻNE:** Node musi działać PIERWSZY - miner pobiera z niego zadania.

### Ręczne uruchamianie (w osobnych terminalach/oknach tmux):

```bash
# KROK 1: Uruchom NODE (w pierwszym oknie)
./start-node.sh "TwojaNazwaNode"

# Poczekaj aż node zacznie się synchronizować (zobaczysz bloki)

# KROK 2: Uruchom MINER (w drugim oknie)
./start-miner.sh 4 1
```

### Automatyczne uruchamianie (oba w tle):

```bash
./start-all.sh "TwojaNazwaNode" 4 1
```

---

## 🛠 Skrypty

| Skrypt | Opis |
|--------|------|
| `install.sh` | Pełna instalacja (node + miner GPU) |
| `start-node.sh [nazwa]` | Uruchom node |
| `start-miner.sh [cpu] [gpu]` | Uruchom miner (domyślnie: 4 CPU, 1 GPU) |
| `start-all.sh [nazwa] [cpu] [gpu]` | Uruchom node + miner w tle |
| `stop-all.sh` | Zatrzymaj wszystko |
| `status.sh` | Status procesów i GPU |

---

## 📊 Monitorowanie

```bash
# Status wszystkiego
./status.sh

# Logi node (synchronizacja, bloki)
tail -f /var/lib/quantus/node.log

# Logi miner (hashrate, joby)
tail -f /var/lib/quantus/miner.log

# GPU status
nvidia-smi

# GPU na żywo
watch -n 1 nvidia-smi
```

---

## ⚙️ Konfiguracja

### Parametry minera

```bash
# Tylko GPU (bez CPU)
./start-miner.sh 0 1

# Więcej CPU workers
./start-miner.sh 8 1

# Więcej GPU workers (jeśli masz wiele GPU)
./start-miner.sh 4 2
```

### Zmiana nazwy node

```bash
./start-node.sh "MojaNowaazwa"
# lub
./start-all.sh "MojaNowaazazwa" 4 1
```

---

## 🔐 Klucze i bezpieczeństwo

**KRYTYCZNE:** Po instalacji NATYCHMIAST zrób backup kluczy!

```bash
# Wyświetl klucze
cat /root/seed.txt

# Skopiuj przez SCP (z lokalnego komputera)
scp -P PORT root@IP:/root/seed.txt ./seed-backup.txt
```

### Lokalizacja plików:
- `/root/seed.txt` - seed phrase i SS58 address (BACKUP!)
- `/root/chain/node-key` - klucz node
- `/var/lib/quantus/` - dane blockchain + logi

---

## 🔧 Troubleshooting

### GPU nie wykryte przez miner

```bash
# Ustaw zmienne środowiskowe
export XDG_RUNTIME_DIR=/tmp

# Sprawdź Vulkan
vulkaninfo | head -30

# Jeśli brak vulkan:
apt-get install -y vulkan-tools mesa-vulkan-drivers
```

### Miner: "No suitable GPU adapters found"

Użyj wersji minera z GPU:
```bash
wget -O /usr/local/bin/quantus-miner \
  https://github.com/Quantus-Network/quantus-miner/releases/download/v2.0.2/quantus-miner-linux-x86_64-gpu
chmod +x /usr/local/bin/quantus-miner
```

### Node: "Invalid rewards address"

Użyj SS58 Address (zaczyna się od `q...`), nie hex:
```bash
grep "SS58 Address" /root/seed.txt
```

### Miner nie dostaje jobów

1. Sprawdź czy node działa: `ps aux | grep quantus-node`
2. Sprawdź czy node się synchronizuje: `tail /var/lib/quantus/node.log`
3. Sprawdź port 9833: `curl http://127.0.0.1:9833/`

---

## 📁 Struktura po instalacji

```
/root/
├── seed.txt              # Klucze - BACKUP!
├── chain/
│   └── node-key          # Klucz node
└── kuantus-gpu/          # Skrypty

/var/lib/quantus/
├── chains/dirac/         # Dane blockchain
├── miner.log             # Logi minera
└── node.log              # Logi node

/usr/local/bin/
├── quantus-node          # Binary node
└── quantus-miner         # Binary miner (GPU)
```

---

## 🌐 Sieć

- **Chain:** Dirac (testnet)
- **Port P2P:** 30333
- **Port RPC:** 9933
- **Port Miner:** 9833

---

## 📚 Linki

- [Quantus Network](https://github.com/Quantus-Network)
- [Miner Releases](https://github.com/Quantus-Network/quantus-miner/releases)
- [Chain Repo](https://github.com/Quantus-Network/chain)
