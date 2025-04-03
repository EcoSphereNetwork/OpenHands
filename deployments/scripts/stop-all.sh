#!/bin/bash

# Dieses Skript stoppt alle OpenHands-Instanzen

# Pfad zum Skript-Verzeichnis ermitteln
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

# Issue-Resolver-Instanzen stoppen
echo "Stoppe Issue-Resolver-Instanzen..."
cd "$BASE_DIR/issue-resolver/repositories"
for REPO_DIR in */; do
  REPO=${REPO_DIR%/}
  echo "Stoppe Issue-Resolver für $REPO..."
  cd "$BASE_DIR/issue-resolver/repositories/$REPO"
  docker-compose down
done

# Ollama-Instanz stoppen
echo "Stoppe Ollama-Instanz..."
cd "$BASE_DIR/ollama"
docker-compose down

# OpenAI-Instanz stoppen
echo "Stoppe OpenAI-Instanz..."
cd "$BASE_DIR/openai"
docker-compose down

# Anthropic-Instanz stoppen
echo "Stoppe Anthropic-Instanz..."
cd "$BASE_DIR/anthropic"
docker-compose down

echo "Alle OpenHands-Instanzen wurden gestoppt."