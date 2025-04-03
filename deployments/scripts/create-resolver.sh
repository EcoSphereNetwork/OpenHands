#!/bin/bash

# Dieses Skript erstellt einen neuen Issue-Resolver für ein Repository

# Überprüfen, ob alle erforderlichen Parameter angegeben wurden
if [ $# -lt 2 ]; then
  echo "Verwendung: $0 <repository-name> <port>"
  exit 1
fi

REPO=$1
PORT=$2

# Umgebungsvariablen laden
if [ -f .env ]; then
  export $(cat .env | grep -v '#' | xargs)
fi

# Konfiguration
GITHUB_TOKEN=${GITHUB_TOKEN:-"your-github-token"}
GIT_USERNAME=${GIT_USERNAME:-"your-github-username"}
ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY:-"your-anthropic-api-key"}

# Pfade bestimmen
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$SCRIPT_DIR/../issue-resolver/repositories/$REPO"
WORKSPACE_DIR="$SCRIPT_DIR/../workspace/$REPO"

# Verzeichnisse erstellen
mkdir -p "$REPO_DIR"
mkdir -p "$WORKSPACE_DIR"

# Repository klonen
if [ ! -d "$WORKSPACE_DIR" ]; then
  git clone https://github.com/EcoSphereNetwork/$REPO.git "$WORKSPACE_DIR"
fi

# Konfigurationsdatei erstellen
cat > "$REPO_DIR/config.toml" << EOF
# Issue-Resolver-Konfiguration für $REPO

# Basis-Konfiguration einbinden
# Hinweis: In einer tatsächlichen Implementierung würden wir die Basis-Konfiguration hier einbinden
# Da TOML keine direkte Einbindung unterstützt, müssten wir ein Skript verwenden, um die Dateien zu kombinieren

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
model = "anthropic/claude-3-haiku-20240307"
temperature = 0.1
max_output_tokens = 1024

# Issue-Resolver-spezifische Konfiguration
[llm]
model = "anthropic/claude-3-5-sonnet-20241022"
api_key = "\${ANTHROPIC_API_KEY}"  # Wird aus der Umgebungsvariable gelesen
temperature = 0.0
max_output_tokens = 4096
input_cost_per_token = 0.000003
output_cost_per_token = 0.000015
custom_llm_provider = "anthropic"
EOF

# .openhands_instructions erstellen
cat > "$REPO_DIR/.openhands_instructions" << EOF
Du bist ein Issue-Resolver für das Repository EcoSphereNetwork/$REPO.
Deine Aufgabe ist es, GitHub-Issues zu analysieren und zu lösen.
Befolge diese Richtlinien:

1. Verstehe das Problem gründlich, bevor du eine Lösung vorschlägst.
2. Prüfe den Code sorgfältig und identifiziere die Ursache des Problems.
3. Implementiere eine Lösung, die das Problem behebt und keine neuen Probleme verursacht.
4. Teste deine Lösung gründlich.
5. Dokumentiere deine Änderungen klar und verständlich.
6. Erstelle einen Pull Request mit deiner Lösung.

Viel Erfolg!
EOF

# Docker-Compose-Datei erstellen
cat > "$REPO_DIR/docker-compose.yml" << EOF
version: '3.8'

services:
  openhands-resolver-$REPO:
    build:
      context: ../../
      dockerfile: ./deployments/issue-resolver/Dockerfile
      args:
        CONFIG_PATH: ./deployments/issue-resolver/repositories/$REPO/config.toml
        REPO_NAME: $REPO
    image: openhands-resolver-$REPO:latest
    container_name: openhands-resolver-$REPO
    restart: unless-stopped
    environment:
      - ANTHROPIC_API_KEY=\${ANTHROPIC_API_KEY}
      - GITHUB_TOKEN=\${GITHUB_TOKEN}
      - GIT_USERNAME=\${GIT_USERNAME}
      - SANDBOX_RUNTIME_CONTAINER_IMAGE=docker.all-hands.dev/all-hands-ai/runtime:0.30-nikolaik
      - WORKSPACE_MOUNT_PATH=/opt/workspace_base
      - SELECTED_REPO=EcoSphereNetwork/$REPO
    ports:
      - "$PORT:3000"
    extra_hosts:
      - "host.docker.internal:host-gateway"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - resolver-$REPO-state:/.openhands-state
      - ../../workspace/$REPO:/opt/workspace_base
    stdin_open: true
    tty: true

volumes:
  resolver-$REPO-state:
    name: openhands-resolver-$REPO-state
EOF

echo "Issue-Resolver für $REPO wurde erstellt."
echo "Um den Issue-Resolver zu starten, führe folgende Befehle aus:"
echo "cd $REPO_DIR"
echo "docker-compose up -d"