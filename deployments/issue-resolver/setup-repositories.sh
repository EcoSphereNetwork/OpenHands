#!/bin/bash

# Dieses Skript richtet Issue-Resolver für alle EcoSphereNetwork-Repositories ein

# Konfiguration
GITHUB_TOKEN=${GITHUB_TOKEN:-"your-github-token"}
GIT_USERNAME=${GIT_USERNAME:-"your-github-username"}
ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY:-"your-anthropic-api-key"}
BASE_PORT=3100

# Verzeichnis für die Repositories erstellen
mkdir -p $(dirname "$0")/repositories
mkdir -p $(dirname "$0")/../workspace

# Repositories von EcoSphereNetwork abrufen
echo "Rufe Repositories von EcoSphereNetwork ab..."
REPOS=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" "https://api.github.com/orgs/EcoSphereNetwork/repos" | jq -r '.[].name')

# Für jedes Repository einen Issue-Resolver einrichten
PORT=$BASE_PORT
for REPO in $REPOS; do
  echo "Richte Issue-Resolver für $REPO ein..."
  
  # Repository-Verzeichnis erstellen
  mkdir -p $(dirname "$0")/repositories/$REPO
  mkdir -p $(dirname "$0")/../workspace/$REPO
  
  # Repository klonen
  if [ ! -d "$(dirname "$0")/../workspace/$REPO" ]; then
    git clone https://github.com/EcoSphereNetwork/$REPO.git $(dirname "$0")/../workspace/$REPO
  fi
  
  # Konfigurationsdatei erstellen
  cat > $(dirname "$0")/repositories/$REPO/config.toml << EOF
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
  cat > $(dirname "$0")/repositories/$REPO/.openhands_instructions << EOF
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
  cat > $(dirname "$0")/repositories/$REPO/docker-compose.yml << EOF
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

  echo "Issue-Resolver für $REPO eingerichtet auf Port $PORT"
  
  # Port für das nächste Repository erhöhen
  PORT=$((PORT + 1))
done

echo "Alle Issue-Resolver wurden eingerichtet."