#!/bin/bash

# Erstellen Sie ein Verzeichnis für die SGLang-Integration
mkdir -p ~/openhands-sglang
cd ~/openhands-sglang

# Dateien erstellen
mkdir -p workspace

# Dockerfile erstellen
cat > Dockerfile << 'EOF'
FROM docker.all-hands.dev/all-hands-ai/openhands:0.31

ARG CONFIG_PATH=./config.toml

LABEL maintainer="EcoSphereNetwork"
LABEL description="OpenHands mit SGLang für lokale LLMs"

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
    environment:
      - SGLANG_DEVICE_MAP=auto      # Automatische Geräteerkennung
      - SGLANG_WORKER_PORT=30000    # Port für API-Endpunkt
      - SGLANG_MODEL=${SGLANG_MODEL:-Phi3-mini-4k-instruct-gguf}  # Standardmodell
    # Aktiviere diese Zeilen, wenn du eine NVIDIA GPU verwendest
    # deploy:
    #   resources:
    #     reservations:
    #       devices:
    #         - driver: nvidia
    #           count: all
    #           capabilities: [gpu]
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
      - SGLANG_MODEL=${SGLANG_MODEL:-Phi3-mini-4k-instruct-gguf}
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

# Konfigurationsdatei erstellen
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

[llm.condenser]
model = "Phi3-mini-4k-instruct-gguf"  # Kleineres Modell für die Zusammenfassung
temperature = 0.1
max_output_tokens = 1024
url = "http://sglang-server:30000/v1/chat"
custom_llm_provider = "sglang"

[llm]
model = "${SGLANG_MODEL}"  # Wird aus der Umgebungsvariable gelesen
api_key = ""  # Kein API-Key für lokale Modelle erforderlich
temperature = 0.7
max_output_tokens = 4096
url = "http://sglang-server:30000/v1/chat"
custom_llm_provider = "sglang"
EOF

# Setup-Script erstellen
cat > setup-models.sh << 'EOF'
#!/bin/bash

# Dieses Skript richtet die benötigten Modelle für SGLang ein

# Warten, bis der SGLang-Server bereit ist
echo "Warte auf SGLang-Server..."
until curl -s http://localhost:30000/v1/health > /dev/null 2>&1; do
  sleep 2
done

echo "SGLang-Server ist bereit. Konfiguriere Modelle..."

# Prüfen, welches Modell konfiguriert ist
MODEL=${SGLANG_MODEL:-"Phi3-mini-4k-instruct-gguf"}
echo "Verwende Modell: $MODEL"

# Modell über SGL-API laden
curl -X POST http://localhost:30000/v1/models/configure \
  -H "Content-Type: application/json" \
  -d "{\"model\": \"$MODEL\", \"device_map\": \"auto\"}"

echo "Modell $MODEL wurde konfiguriert."

echo "Hinweis: Größere Modelle werden automatisch beim ersten Aufruf heruntergeladen."
echo "Dies kann je nach Modellgröße einige Zeit dauern."
echo "SGLang-Server läuft auf: http://localhost:30001"
EOF

chmod +x setup-models.sh

# Umgebungsvariablen-Datei erstellen
cat > .env << 'EOF'
# Modell für SGLang
SGLANG_MODEL=Phi3-mini-4k-instruct-gguf
# Weitere Optionen: llama3-8b-gguf, mistral-7b-instruct-gguf, gemma-7b-instruct-gguf
EOF

# OpenHands mit SGLang starten
echo "Starte OpenHands mit SGLang..."
docker-compose up -d

# Warten, bis der SGLang-Server bereit ist, und Modelle laden
echo "Warte auf SGLang-Server und konfiguriere Modelle..."
sleep 10
./setup-models.sh

echo "OpenHands mit SGLang läuft jetzt auf http://localhost:3004"
echo "SGLang Web-UI ist verfügbar unter http://localhost:30001"
