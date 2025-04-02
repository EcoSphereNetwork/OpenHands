FROM ../base/Dockerfile.base

ARG CONFIG_PATH=./deployments/ollama/config.toml

LABEL maintainer="EcoSphereNetwork"
LABEL description="OpenHands mit Ollama"

# Kopieren der spezifischen Konfigurationsdatei
COPY ${CONFIG_PATH} /app/config.toml