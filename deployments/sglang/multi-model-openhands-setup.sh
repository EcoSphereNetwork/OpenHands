#!/bin/bash

# Multi-Modell-Setup für OpenHands mit SGLang
# Unterstützt: openhands-lm-1.5b, openhands-lm-7b und openhands-lm-32b

# Erstellen Sie ein Verzeichnis für die Multi-Modell-Integration
mkdir -p ~/openhands-multi-model
cd ~/openhands-multi-model

# Verzeichnisse erstellen
mkdir -p workspace
mkdir -p models

# Dockerfile erstellen
cat > Dockerfile << 'EOF'
FROM docker.all-hands.dev/all-hands-ai/openhands:0.31

ARG CONFIG_PATH=./config.toml

LABEL maintainer="EcoSphereNetwork"
LABEL description="OpenHands mit multiplen lokalen OpenHands-Modellen via SGLang"

# Kopieren der spezifischen Konfigurationsdatei
COPY ${CONFIG_PATH} /app/config.toml
EOF

# Docker Compose Datei erstellen
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  sglang-server:
    image: sglang/sglang:latest
    container_name: sglang-server
    restart: unless-stopped
    ports:
      - "30000:30000"  # API-Endpunkt
      - "30001:30001"  # Web-UI
    volumes:
      - sglang-data:/root/.cache  # Cache für Modelle
      - ./models:/models          # Gemountetes Verzeichnis für lokale Modelle
    environment:
      - SGLANG_DEVICE_MAP=auto      # Automatische Geräteerkennung
      - SGLANG_WORKER_PORT=30000    # Port für API-Endpunkt
      - SGLANG_ALLOW_DOWNLOADS=true # Erlaube Downloads von Hugging Face
      - SGLANG_MAX_MODEL_LEN=8192   # Maximale Kontextlänge
      - SGLANG_MULTI_MODEL=true     # Wichtig: Aktiviert Multi-Modell-Unterstützung
      - SGLANG_HF_TOKEN=${HF_TOKEN:-""} # Hugging Face Token (falls das Modell privat ist)
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:30000/v1/health"]
      interval: 10s
      timeout: 5s
      retries: 5

  openhands-sglang:
    build:
      context: .
      dockerfile: Dockerfile
    image: openhands-sglang:latest
    container_name: openhands-sglang
    restart: unless-stopped
    depends_on:
      sglang-server:
        condition: service_healthy
    environment:
      - SGLANG_MODEL=${SGLANG_MODEL:-all-hands/openhands-lm-1.5b-v0.1}  # Default ist das 1.5B-Modell
      - SANDBOX_RUNTIME_CONTAINER_IMAGE=docker.all-hands.dev/all-hands-ai/runtime:0.31-nikolaik
      - WORKSPACE_MOUNT_PATH=/opt/workspace_base
    ports:
      - "3004:3000"
    extra_hosts:
      - "host.docker.internal:host-gateway"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - sglang-openhands-state:/.openhands-state
      - ./workspace:/opt/workspace_base
    stdin_open: true
    tty: true

volumes:
  sglang-data:
    name: sglang-data
  sglang-openhands-state:
    name: openhands-sglang-state
EOF

# Konfigurationsdatei erstellen - mit Multi-Modell-Unterstützung
cat > config.toml << 'EOF'
[core]
workspace_base = "/opt/workspace_base"
debug = false
max_iterations = 250
max_concurrent_conversations = 3
conversation_max_age_seconds = 864000  # 10 Tage

[sandbox]
timeout = 120
base_container_image = "nikolaik/python-nodejs:python3.12-nodejs22"
use_host_network = false
runtime_extra_build_args = ["--network=host", "--add-host=host.docker.internal:host-gateway"]
enable_auto_lint = true
initialize_plugins = true
keep_runtime_alive = true
pause_closed_runtimes = true
close_delay = 300

[agent]
codeact_enable_browsing = true
codeact_enable_llm_editor = true
codeact_enable_jupyter = true
enable_history_truncation = true

[condenser]
type = "llm"
keep_first = 1
max_size = 100

# Für die Zusammenfassung
[llm.condenser]
model = "all-hands/openhands-lm-1.5b-v0.1"  # Kleineres Modell für Zusammenfassungen
temperature = 0.1
max_output_tokens = 1024
url = "http://sglang-server:30000/v1/chat"
custom_llm_provider = "sglang"

# Hauptmodellkonfiguration
[llm]
model = "${SGLANG_MODEL}"  # Wird aus der Umgebungsvariable gelesen
api_key = ""  # Kein API-Key für lokale Modelle erforderlich
temperature = 0.7
max_output_tokens = 4096
url = "http://sglang-server:30000/v1/chat"
custom_llm_provider = "sglang"

# Modellauswahl-Konfiguration
[model_selector]
# Diese Einstellung aktiviert die Modellauswahl in der UI
enabled = true
# Liste verfügbarer Modelle (erscheinen im Dropdown-Menü)
models = [
    { name = "OpenHands 1.5B", model_id = "all-hands/openhands-lm-1.5b-v0.1", description = "Kleines Modell (1.5B Parameter) - schnell & ressourcenschonend" },
    { name = "OpenHands 7B", model_id = "all-hands/openhands-lm-7b-v0.1", description = "Mittleres Modell (7B Parameter) - gute Balance" },
    { name = "OpenHands 32B", model_id = "all-hands/openhands-lm-32b-v0.1", description = "Großes Modell (32B Parameter) - hohe Qualität, ressourcenintensiv" }
]
# Standard-Modell (muss einem der Einträge in der models-Liste entsprechen)
default = "all-hands/openhands-lm-1.5b-v0.1"
EOF

# Setup-Script erstellen
cat > setup-models.sh << 'EOF'
#!/bin/bash

# Multi-Modell-Setup für SGLang mit OpenHands-Modellen

# Modellverzeichnis erstellen
mkdir -p models

# Warten, bis der SGLang-Server bereit ist
echo "Warte auf SGLang-Server..."
until curl -s http://localhost:30000/v1/health > /dev/null 2>&1; do
  sleep 2
done

echo "SGLang-Server ist bereit. Konfiguriere alle Modelle..."

# 1.5B-Modell konfigurieren (Standard-Modell)
echo "Konfiguriere openhands-lm-1.5b-v0.1..."
curl -X POST http://localhost:30000/v1/models/configure \
  -H "Content-Type: application/json" \
  -d "{\"model\": \"all-hands/openhands-lm-1.5b-v0.1\", \"device_map\": \"auto\"}"

# 7B-Modell konfigurieren
echo "Konfiguriere openhands-lm-7b-v0.1..."
curl -X POST http://localhost:30000/v1/models/configure \
  -H "Content-Type: application/json" \
  -d "{\"model\": \"all-hands/openhands-lm-7b-v0.1\", \"device_map\": \"auto\"}"

# 32B-Modell konfigurieren
echo "Konfiguriere openhands-lm-32b-v0.1..."
curl -X POST http://localhost:30000/v1/models/configure \
  -H "Content-Type: application/json" \
  -d "{\"model\": \"all-hands/openhands-lm-32b-v0.1\", \"device_map\": \"auto\"}"

echo "Alle Modelle wurden konfiguriert."
echo "Hinweis: Das erste Laden der Modelle kann einige Zeit dauern (mehrere Minuten)."
echo "Der Fortschritt kann im Docker-Log verfolgt werden: docker logs sglang-server"
echo "SGLang Web-UI ist verfügbar unter: http://localhost:30001"
EOF

chmod +x setup-models.sh

# Umgebungsvariablen-Datei erstellen
cat > .env << 'EOF'
# Standard-Modell (1.5B)
SGLANG_MODEL=all-hands/openhands-lm-1.5b-v0.1

# Hugging Face Token (falls die Modelle privat sind)
# HF_TOKEN=hf_...

# GPU-Optimierungen (aktivieren Sie bei Bedarf)
# SGLANG_QUANTIZATION=4bit    # Für 32B Modell empfohlen
# SGLANG_MAX_MODEL_LEN=4096  # Reduzieren Sie bei Speicherproblemen
EOF

# Informationen anzeigen
echo "Setup abgeschlossen!"
echo ""
echo "Um OpenHands mit allen drei Modellen zu starten:"
echo "1. Starten Sie den Service mit: docker-compose up -d"
echo "2. Führen Sie das Setup-Script aus: ./setup-models.sh"
echo ""
echo "OpenHands wird dann unter http://localhost:3004 verfügbar sein."
echo "Sie können zwischen den Modellen über die Weboberfläche wechseln."
echo ""
echo "HINWEIS:"
echo "- Das 1.5B-Modell läuft auf den meisten GPUs gut (benötigt ca. 3GB VRAM)"
echo "- Das 7B-Modell benötigt eine mittelstarke GPU (ca. 8GB VRAM)"
echo "- Das 32B-Modell benötigt eine leistungsstarke GPU (24GB+ VRAM empfohlen)"
echo ""
echo "Modellwechsel: Das System lädt die Modelle beim ersten Aufruf."
echo "Ein Wechsel zwischen Modellen kann daher beim ersten Mal länger dauern."
