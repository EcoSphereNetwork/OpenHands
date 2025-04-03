#!/bin/bash

# Dieses Skript startet alle OpenHands-Instanzen

# Pfad zum Skript-Verzeichnis ermitteln
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

# Umgebungsvariablen laden
if [ -f "$BASE_DIR/.env" ]; then
  export $(cat "$BASE_DIR/.env" | grep -v '#' | xargs)
fi

# Anthropic-Instanz starten
echo "Starte Anthropic-Instanz..."
cd "$BASE_DIR/anthropic"
docker-compose up -d

# OpenAI-Instanz starten
echo "Starte OpenAI-Instanz..."
cd "$BASE_DIR/openai"
docker-compose up -d

# Ollama-Instanz starten
echo "Starte Ollama-Instanz..."
cd "$BASE_DIR/ollama"
docker-compose up -d

# Warten, bis Ollama bereit ist, dann Modelle laden
echo "Warte auf Ollama-Server und lade Modelle..."
sleep 10
bash "$BASE_DIR/ollama/setup-models.sh"

# Issue-Resolver-Instanzen starten
echo "Starte Issue-Resolver-Instanzen..."
cd "$BASE_DIR/issue-resolver/repositories"
for REPO_DIR in */; do
  REPO=${REPO_DIR%/}
  echo "Starte Issue-Resolver für $REPO..."
  cd "$BASE_DIR/issue-resolver/repositories/$REPO"
  docker-compose up -d
done

echo "Alle OpenHands-Instanzen wurden gestartet."
echo ""
echo "Verfügbare Instanzen:"
echo "- Anthropic: http://localhost:3001"
echo "- OpenAI: http://localhost:3002"
echo "- Ollama: http://localhost:3003"
echo "- Issue-Resolver: http://localhost:3100 und folgende Ports"