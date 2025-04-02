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

# Optional: Weitere Modelle hinzufügen
# echo "Lade CodeLlama..."
# curl -X POST http://localhost:11434/api/pull -d '{"name": "codellama"}'

echo "Alle Modelle wurden geladen."