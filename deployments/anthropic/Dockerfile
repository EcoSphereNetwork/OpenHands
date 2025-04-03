FROM ../base/Dockerfile.base

ARG CONFIG_PATH=./deployments/anthropic/config.toml

LABEL maintainer="EcoSphereNetwork"
LABEL description="OpenHands mit Anthropic Claude"

# Kopieren der spezifischen Konfigurationsdatei
COPY ${CONFIG_PATH} /app/config.toml