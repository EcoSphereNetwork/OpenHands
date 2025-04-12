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

# Modell über SGL-API laden (je nach Modell und Version kann der genaue Endpunkt variieren)
curl -X POST http://localhost:30000/v1/models/configure \
  -H "Content-Type: application/json" \
  -d "{\"model\": \"$MODEL\", \"device_map\": \"auto\"}"

echo "Modell $MODEL wurde konfiguriert."

echo "Hinweis: Größere Modelle werden automatisch beim ersten Aufruf heruntergeladen."
echo "Dies kann je nach Modellgröße einige Zeit dauern."
echo "SGLang-Server läuft auf: http://localhost:30001"
