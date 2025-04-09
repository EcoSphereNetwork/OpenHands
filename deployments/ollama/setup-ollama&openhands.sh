#!/bin/bash

# Erstellen Sie ein neues Verzeichnis für das korrigierte Setup
mkdir -p ~/openhands-ollama
cd ~/openhands-ollama

# Dateien erstellen
cat > Dockerfile << 'EOF'
# Dockerfile für Ollama
FROM docker.all-hands.dev/all-hands-ai/openhands:0.31

ARG CONFIG_PATH=./config.toml

LABEL maintainer="EcoSphereNetwork"
LABEL description="OpenHands mit Ollama"

# Kopieren der spezifischen Konfigurationsdatei
COPY ${CONFIG_PATH} /app/config.toml
EOF

cat > docker-compose.yml << 'EOF'
services:
  ollama:
    image: ollama/ollama:latest
    container_name: ollama-server
    restart: unless-stopped
    ports:
      - "11434:11434"
    volumes:
      - ollama-data:/root/.ollama
    environment:
      - OLLAMA_HOST=0.0.0.0
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:11434"]
      interval: 10s
      timeout: 5s
      retries: 5

  openhands-ollama:
    build:
      context: .
      dockerfile: Dockerfile
    image: openhands-ollama:latest
    container_name: openhands-ollama
    restart: unless-stopped
    depends_on:
      ollama:
        condition: service_healthy
    environment:
      - SANDBOX_RUNTIME_CONTAINER_IMAGE=docker.all-hands.dev/all-hands-ai/runtime:0.31-nikolaik
      - WORKSPACE_MOUNT_PATH=/opt/workspace_base
    ports:
      - "3003:3000"
    extra_hosts:
      - "host.docker.internal:host-gateway"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ollama-state:/.openhands-state
      - ./workspace:/opt/workspace_base
    stdin_open: true
    tty: true

volumes:
  ollama-data:
    name: ollama-data
  ollama-state:
    name: openhands-ollama-state
EOF

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
model = "ollama/llama3"
temperature = 0.1
max_output_tokens = 1024

[llm]
model = "ollama/llama3"
api_key = ""  # Kein API-Key für Ollama erforderlich
temperature = 0.7
max_output_tokens = 4096
url = "http://ollama:11434/api/chat"
custom_llm_provider = "ollama"
EOF

cat > setup-models.sh << 'EOF'
#!/bin/bash

# Dieses Skript lädt die benötigten Modelle für Ollama herunter

# Warten, bis der Ollama-Server bereit ist
echo "Warte auf Ollama-Server..."
until curl -s http://localhost:11434/api/tags > /dev/null 2>&1; do
  sleep 2
done

echo "Ollama-Server ist bereit. Lade Modelle..."

# Llama3 herunterladen
echo "Lade Llama3..."
curl -X POST http://localhost:11434/api/pull -d '{"name": "llama3"}'

echo "Alle Modelle wurden geladen."
EOF

chmod +x setup-models.sh
mkdir -p workspace

# OpenHands mit Ollama starten
docker-compose up -d

# Warten, bis der Ollama-Server bereit ist, und Modelle laden
echo "Warte auf Ollama-Server und lade Modelle..."
./setup-models.sh

echo "OpenHands mit Ollama läuft jetzt auf http://localhost:3003"
